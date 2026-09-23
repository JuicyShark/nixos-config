"""Isolated real PTYs: no windows or existing application sessions are touched."""
import fcntl
import json
import os
from pathlib import Path
import pty
import re
import shutil
import signal
import shlex
import socket
import struct
import subprocess
import sys
import tempfile
import threading
import time
import termios
import uuid

samples = {}
def benchmark(name, operation):
    count = int(os.environ.get("SMART_FOCUS_BENCH", "0"))
    if not count:
        return
    times = []
    for index in range(count):
        start = time.monotonic()
        answer = operation(index)
        times.append((time.monotonic() - start) * 1000)
        assert answer["status"] == "moved", (name, index, answer)
    times.sort()
    samples[name] = {"samples":count, **{f"p{q}_ms":round(times[min(count-1, int(count*q/100))], 3) for q in (50,95,99)}}
    print("BENCH", name, json.dumps(samples[name]), flush=True)

BROKER = str(Path(sys.argv[1]).resolve())
ADAPTER = str(Path(sys.argv[2]).resolve())
children = []
masters = []
outputs = []

# Public CLI works without a desktop environment and reports failures as data.
no_desktop = {k: v for k, v in os.environ.items()
              if k not in ("XDG_RUNTIME_DIR", "HYPRLAND_INSTANCE_SIGNATURE")}
assert subprocess.check_output([BROKER, "--version"], env=no_desktop, text=True).startswith("smart-focus ")
assert "doctor" in subprocess.check_output([BROKER, "--help"], env=no_desktop, text=True)
doctor = subprocess.run([BROKER, "doctor", "--json"], env=no_desktop, capture_output=True, text=True, timeout=3)
assert doctor.returncode == 1 and json.loads(doctor.stdout)["healthy"] is False


def spawn(argv, env):
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 120, 0, 0))
    def controlling_tty():
        os.setsid()
        fcntl.ioctl(0, termios.TIOCSCTTY, 0)
    child = subprocess.Popen(argv, stdin=slave, stdout=slave, stderr=slave,
                             env=env, preexec_fn=controlling_tty)
    os.close(slave)
    children.append(child)
    masters.append(master)
    output = bytearray()
    outputs.append(output)
    def drain():
        try:
            while data := os.read(master, 65536):
                output.extend(data)
                for query, reply in [
                    (b"\x1b[c", b"\x1b[?1;2c"),
                    (b"\x1b[5n", b"\x1b[0n"),
                    (b"\x1b]11;?", b"\x1b]11;rgb:0000/0000/0000\x1b\\"),
                    (b"\x1b]10;?", b"\x1b]10;rgb:ffff/ffff/ffff\x1b\\"),
                    (b"\x1b[14t", b"\x1b[4;600;1200t"),
                    (b"\x1b[16t", b"\x1b[6;20;10t"),
                    (b"\x1b[?u", b"\x1b[?0u"),
                ]:
                    if query in data:
                        os.write(master, reply)
        except OSError:
            pass
    threading.Thread(target=drain, daemon=True).start()
    return child


def wait_for(predicate, seconds=5):
    end = time.monotonic() + seconds
    while time.monotonic() < end:
        found = predicate()
        if found:
            return found
        time.sleep(0.02)
    raise AssertionError("condition did not become true: " + repr([bytes(o)[:2500] for o in outputs]))


def process(pid):
    fields = Path(f"/proc/{pid}/stat").read_text().rsplit(") ", 1)[1].split()
    return dict(pid=pid, start=fields[19], tty=int(fields[4]), pgrp=int(fields[2]),
                foreground=int(fields[5]), state=fields[0])


with tempfile.TemporaryDirectory(prefix="sf-") as directory:
    root = Path(directory)
    env = {k: v for k, v in os.environ.items() if not k.startswith("ZELLIJ")}
    env.update(HOME=directory, TMPDIR=directory, XDG_RUNTIME_DIR=directory, XDG_CONFIG_HOME=str(root / "config"),
               XDG_CACHE_HOME=str(root / "cache"), XDG_DATA_HOME=str(root / "data"),
               TERM="xterm-256color", ZELLIJ_SOCKET_DIR=str(root / "z"),
               HYPRLAND_INSTANCE_SIGNATURE="smart-focus-test", SHELL=shutil.which("bash"))
    config = root / "config/zellij"
    config.mkdir(parents=True)
    env["ZELLIJ_CONFIG_FILE"] = str(config / "config.kdl")
    (config / "config.kdl").write_text("show_startup_tips false\nshow_release_notes false\n")
    sf = root / "smart-focus"
    instance = sf / env["HYPRLAND_INSTANCE_SIGNATURE"]
    instance.mkdir(parents=True)
    broker = subprocess.Popen([BROKER, "serve"], env=env, stderr=subprocess.PIPE)
    children.append(broker)
    session = uuid.uuid4().hex[:6]
    sequence = 0

    def exchange(message):
        with socket.socket(socket.AF_UNIX) as client:
            client.settimeout(2)
            client.connect(str(sf / "broker.sock"))
            client.sendall(json.dumps(message).encode() + b"\n")
            return json.loads(client.makefile("rb").readline())

    def request(window="a", direction="left", operation="focus", context=None):
        global sequence
        sequence += 1
        current = "test\t0\t" + window
        (instance / "context").write_text(current + "\n")
        message = dict(instance=env["HYPRLAND_INSTANCE_SIGNATURE"], id=str(sequence),
                       context=context or current, window=window, direction=direction,
                       operation=operation, deadline=time.monotonic() + 0.2)
        return exchange(message)

    def register(child, window):
        path = instance / "terminals" / window
        path.mkdir(parents=True, exist_ok=True)
        (path / f"{child.pid}.json").write_text(json.dumps(process(child.pid)))

    try:
        wait_for(lambda: (sf / "broker.sock").exists())
        # A real interactive shell hands the foreground process group to the
        # registration helper. Stub only the compositor's title acknowledgement.
        hypr_socket = root / "hypr" / env["HYPRLAND_INSTANCE_SIGNATURE"] / ".socket.sock"
        hypr_socket.parent.mkdir(parents=True)
        with socket.socket(socket.AF_UNIX) as compositor:
            compositor.bind(str(hypr_socket))
            compositor.listen()
            compositor.settimeout(0.1)
            stopped = threading.Event()
            def acknowledge_title():
                while not stopped.is_set():
                    try:
                        stream, _ = compositor.accept()
                    except socket.timeout:
                        continue
                    except OSError:
                        return
                    with stream:
                        stream.recv(4096)
                        titles = re.findall(rb"\x1b\]2;(smart-focus-[a-f0-9-]+)\x07", b"".join(bytes(o) for o in outputs))
                        answer = ([dict(title=titles[-1].decode(),
                                        stableId="f0", **{"class": "com.mitchellh.ghostty"})]
                                  if titles else [])
                        stream.sendall(json.dumps(answer).encode())
            responder = threading.Thread(target=acknowledge_title, daemon=True)
            responder.start()
            try:
                shell = spawn(["bash", "--noprofile", "--norc", "-ic",
                               shlex.quote(BROKER) + ' register-terminal $$; read -r'], env)
                registered = instance / "terminals/f0" / f"{shell.pid}.json"
                wait_for(registered.exists)
                assert json.loads(registered.read_text())["pid"] == shell.pid
                print("real shell: foreground helper registers its waiting parent")
            finally:
                stopped.set()
                responder.join(timeout=1)
        nvim = spawn(["nvim", "--clean", "-i", "NONE", "--cmd",
                      "lua package.preload['juicy.smart_focus']=assert(loadfile(" + json.dumps(ADAPTER) + ")); require('juicy.smart_focus').start({})",
                      "-c", "rightbelow vsplit"], env)
        wait_for(lambda: list((sf / "editors").glob("*.json")))
        register(nvim, "a")
        time.sleep(0.1)
        assert request()["status"] == "moved", "Neovim left split"
        assert request()["status"] == "edge", "Neovim left edge"
        assert request(direction="right")["status"] == "moved", "Neovim right split"
        assert request(operation="cwd")["status"] == "cwd", "editor project directory"
        assert request(context="old\t0\ta")["status"] == "stale", "stale source rejected"
        assert request(window="b")["status"] == "edge", "unregistered window cannot borrow editor"
        os.killpg(nvim.pid, signal.SIGSTOP)
        time.sleep(0.03)
        assert request()["status"] == "edge", "suspended editor is not a focus target"
        os.killpg(nvim.pid, signal.SIGCONT)
        time.sleep(0.05)
        assert request()["status"] == "moved", "editor recovers after resume"
        print("real Neovim: split, edge, cwd, stale context, window isolation, suspend/resume passed")
        benchmark("neovim_roundtrip", lambda i: request(direction="right" if i % 2 == 0 else "left"))
        # No editor restart/re-registration is needed after a broker crash.
        broker.kill()
        broker.wait(timeout=3)
        broker = subprocess.Popen([BROKER, "serve"], env=env, stderr=subprocess.PIPE)
        children.append(broker)
        wait_for(lambda: subprocess.run([BROKER, "status"], env=env, capture_output=True).returncode == 0)
        assert request(direction="right")["status"] == "moved"
        assert request(direction="left")["status"] == "moved"
        # A disconnected caller must not cancel bookkeeping for accepted work.
        message = dict(instance=env["HYPRLAND_INSTANCE_SIGNATURE"], id="disconnected-client",
                       context="test\t0\ta", window="a", direction="right", operation="focus",
                       deadline=time.monotonic() + .2)
        with socket.socket(socket.AF_UNIX) as abandoned:
            abandoned.connect(str(sf / "broker.sock"))
            abandoned.sendall(json.dumps(message).encode() + b"\n")
        answer = exchange(message)
        assert answer["status"] == "moved", answer
        history = json.loads(subprocess.check_output([BROKER, "status"], env=env, text=True))["recent"]
        assert sum(item["id"] == message["id"] for item in history) == 1
        assert request(direction="right")["status"] == "edge"
        assert request(direction="left")["status"] == "moved"
        editor_record = json.loads(next((sf / "editors").glob("*.json")).read_text())
        def editor_lua(code):
            subprocess.run(["nvim", "--server", editor_record["socket"], "--remote-expr",
                            "luaeval(" + json.dumps(code) + ")"], env=env, check=True,
                           capture_output=True, timeout=2)
        editor_lua("(function() local m=require('juicy.smart_focus'); m.original_request=m.request; m.request=function(r) vim.wait(120); return m.original_request(r) end end)()")
        try:
            with socket.socket(socket.AF_UNIX) as slow_sender:
                slow_sender.settimeout(1)
                slow_sender.connect(str(sf / "broker.sock"))
                slow_sender.sendall(b"{")
                time.sleep(.22)
                delayed = dict(message, id="slow-sender", deadline=time.monotonic() + .2)
                slow_sender.sendall(json.dumps(delayed).encode()[1:] + b"\n")
                answer = json.loads(slow_sender.makefile("rb").readline())
                assert answer["status"] == "moved", answer
            assert exchange(delayed)["status"] == "moved", "accepted result remains deduplicated"
        finally:
            editor_lua("(function() local m=require('juicy.smart_focus'); m.request=m.original_request; m.original_request=nil end)()")
        assert request(direction="left")["status"] == "moved"
        print("broker lifecycle: crash recovery and disconnected-caller deduplication passed")

        layout = root / "test.kdl"
        layout.write_text('layout { pane; pane; }\n')
        zellij = spawn(["zellij", "--layout", str(layout), "attach", "--create", session], env)
        register(zellij, "c")
        def clients_ready():
            try:
                r = subprocess.run(["zellij", "--session", session, "action", "list-clients"], env=env, capture_output=True, timeout=1)
            except subprocess.TimeoutExpired:
                return False
            return r.returncode == 0 and "terminal_" in r.stdout.decode()
        wait_for(clients_ready, seconds=10)
        actual = subprocess.check_output([BROKER, "inspect", str(zellij.pid)], env=env, text=True).strip()
        assert actual == f'Some("{session}")', actual
        first = request(window="c", direction="down")
        second = request(window="c", direction="up")
        assert "moved" in [first["status"], second["status"]], (first, second)
        assert request(window="c", direction="up")["status"] == "edge"
        benchmark("zellij_roundtrip", lambda i: request(window="c", direction="down" if i % 2 == 0 else "up"))
        zellij.terminate()
        zellij.wait(timeout=3)
        reattached = spawn(["zellij", "attach", session], env)
        register(reattached, "d")
        wait_for(clients_ready)
        actual = subprocess.check_output([BROKER, "inspect", str(reattached.pid)], env=env, text=True).strip()
        assert actual == f'Some("{session}")', actual
        assert request(window="d", direction="down")["status"] == "moved"
        print("real Zellij: kernel socket identity, shell-only panes, edges, detach/reattach passed")
        before_editors = set((sf / "editors").glob("*.json"))
        command = shlex.join(["nvim", "--clean", "-i", "NONE", "--cmd",
                             "lua package.preload['juicy.smart_focus']=assert(loadfile(" + json.dumps(ADAPTER) + ")); require('juicy.smart_focus').start({})",
                             "-c", "rightbelow vsplit"])
        subprocess.run(["zellij", "--session", session, "action", "write-chars", command + "\n"], env=env, check=True, timeout=2)
        wait_for(lambda: set((sf / "editors").glob("*.json")) - before_editors)
        time.sleep(0.1)
        assert request(window="d", direction="left")["status"] == "moved", "nested editor split"
        assert request(window="d", direction="up")["status"] == "moved", "editor edge moves containing Zellij pane"
        assert request(window="d", direction="left")["status"] == "edge", "shell pane must not route to inactive editor"
        assert request(window="d", direction="down")["status"] == "moved", "return to editor pane"
        print("nested Neovim/Zellij: editor split, editor edge, shell pane isolation passed")
        second_client = spawn(["zellij", "attach", session], env)
        register(second_client, "e")
        def two_clients():
            r = subprocess.run(["zellij", "--session", session, "action", "list-clients"], env=env, capture_output=True, timeout=2)
            return len(r.stdout.decode().strip().splitlines()) == 3
        wait_for(two_clients)
        assert request(window="d", direction="left")["status"] == "blocked"
        assert request(window="e", direction="right")["status"] == "blocked"
        print("multi-client Zellij: ambiguous terminal/client association is blocked")
        # Reuse the session name after replacing the server. Cached native
        # connections and process/socket identities must not survive the restart.
        subprocess.run(["zellij", "kill-session", session], env=env, check=True, timeout=3)
        reattached.wait(timeout=3)
        second_client.wait(timeout=3)
        replacement = spawn(["zellij", "--layout", str(layout), "attach", "--create", session], env)
        register(replacement, "f")
        wait_for(clients_ready, seconds=10)
        results = [request(window="f", direction="up"), request(window="f", direction="down")]
        assert any(r["status"] == "moved" for r in results), results
        assert all(r["status"] in ("moved", "edge") for r in results), results
        print("Zellij lifecycle: replacement server with reused session name passed")
        if destination := os.environ.get("SMART_FOCUS_BENCH_OUT"):
            Path(destination).write_text(json.dumps({"binary":BROKER,"metrics":samples}, indent=2) + "\n")
    finally:
        if sys.exc_info()[0]:
            for log in root.rglob("zellij.log"):
                print(log.read_text()[-5000:], flush=True)
        subprocess.run(["zellij", "kill-session", session], env=env, capture_output=True, timeout=3)
        for child in children:
            if child.poll() is None:
                child.terminate()
                try:
                    child.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    child.kill()
                    child.wait()
        for master in masters:
            os.close(master)
