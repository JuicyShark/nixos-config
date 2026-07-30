import filecmp
import pathlib
import shutil
import sys


pack, target, marker = map(pathlib.Path, sys.argv[1:])
excluded = {"world", "eula.txt", "server.properties", "lazymc.toml", "logs"}

previous = None
if marker.exists():
    marker_value = marker.read_text().strip()
    if marker_value == str(pack):
        raise SystemExit(0)
    previous_candidate = pathlib.Path(marker_value)
    if previous_candidate.is_dir():
        previous = previous_candidate
    elif marker_value:
        print(
            "Previous pack source is unavailable; preserving existing mutable "
            f"files: {marker_value}",
            file=sys.stderr,
        )

target.mkdir(parents=True, exist_ok=True)


def included(relative):
    return relative.parts and relative.parts[0] not in excluded


def files_under(root):
    if root is None:
        return {}
    return {
        path.relative_to(root): path
        for path in root.rglob("*")
        if path.is_file() and included(path.relative_to(root))
    }


new_files = files_under(pack)
old_files = files_under(previous)

# Remove files retired by the pack only when the server copy is still
# byte-for-byte identical to the previous immutable source.
for relative, old_source in old_files.items():
    if relative in new_files:
        continue
    destination = target / relative
    if destination.is_file() and filecmp.cmp(destination, old_source, shallow=False):
        destination.unlink()

# Install new files and update files that the server has not modified.
# Locally changed configs/mods are preserved and reported instead of being
# destroyed during a launchd restart.
for relative, source in new_files.items():
    destination = target / relative
    old_source = old_files.get(relative)
    destination.parent.mkdir(parents=True, exist_ok=True)

    if not destination.exists():
        shutil.copy2(source, destination)
    elif not destination.is_file():
        print(f"Preserving non-file pack path: {relative}", file=sys.stderr)
    elif old_source is not None and filecmp.cmp(
        destination, old_source, shallow=False
    ):
        shutil.copy2(source, destination)
    elif not filecmp.cmp(destination, source, shallow=False):
        print(f"Preserving locally modified pack file: {relative}", file=sys.stderr)

marker.write_text(f"{pack}\n")
