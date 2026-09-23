//! Kernel socket ownership connects a foreground Zellij client to its server.
//! Session environment variables are deliberately not used: they survive detach.
use anyhow::{Result, ensure};
use std::{
    collections::{HashMap, HashSet},
    fs,
    os::fd::{AsRawFd, FromRawFd, OwnedFd},
    path::PathBuf,
};

#[derive(Default, Debug)]
pub struct UnixSocket {
    pub peer: Option<u32>,
    pub name: Option<PathBuf>,
}
fn u32_at(b: &[u8], i: usize) -> u32 {
    u32::from_ne_bytes(b[i..i + 4].try_into().unwrap())
}
fn u16_at(b: &[u8], i: usize) -> u16 {
    u16::from_ne_bytes(b[i..i + 2].try_into().unwrap())
}
fn aligned(n: usize) -> usize {
    (n + 3) & !3
}

pub fn sockets() -> Result<HashMap<u32, UnixSocket>> {
    let fd = unsafe {
        libc::socket(
            libc::AF_NETLINK,
            libc::SOCK_RAW | libc::SOCK_CLOEXEC,
            libc::NETLINK_SOCK_DIAG,
        )
    };
    ensure!(fd >= 0, "socket diagnostics unavailable");
    let fd = unsafe { OwnedFd::from_raw_fd(fd) };
    let timeout = libc::timeval {
        tv_sec: 0,
        tv_usec: 100_000,
    };
    unsafe {
        libc::setsockopt(
            fd.as_raw_fd(),
            libc::SOL_SOCKET,
            libc::SO_RCVTIMEO,
            &timeout as *const _ as *const _,
            std::mem::size_of_val(&timeout) as _,
        );
    }
    let mut address: libc::sockaddr_nl = unsafe { std::mem::zeroed() };
    address.nl_family = libc::AF_NETLINK as u16;
    let mut request = vec![];
    request.extend(40u32.to_ne_bytes()); // nlmsghdr + unix_diag_req
    request.extend(20u16.to_ne_bytes()); // SOCK_DIAG_BY_FAMILY
    request.extend(0x301u16.to_ne_bytes()); // REQUEST | DUMP
    request.extend(1u32.to_ne_bytes());
    request.extend(0u32.to_ne_bytes());
    request.extend([libc::AF_UNIX as u8, 0, 0, 0]);
    request.extend(u32::MAX.to_ne_bytes());
    request.extend(0u32.to_ne_bytes());
    request.extend(5u32.to_ne_bytes()); // UDIAG_SHOW_NAME | UDIAG_SHOW_PEER
    request.extend(u32::MAX.to_ne_bytes());
    request.extend(u32::MAX.to_ne_bytes());
    let sent = unsafe {
        libc::sendto(
            fd.as_raw_fd(),
            request.as_ptr() as _,
            request.len(),
            0,
            &address as *const _ as _,
            std::mem::size_of_val(&address) as _,
        )
    };
    ensure!(
        sent == request.len() as isize,
        "socket diagnostic request failed"
    );
    let mut result = HashMap::new();
    let mut buffer = [0u8; 65536];
    loop {
        let count =
            unsafe { libc::recv(fd.as_raw_fd(), buffer.as_mut_ptr() as _, buffer.len(), 0) };
        ensure!(count > 0, "socket diagnostic response failed");
        let mut offset = 0;
        while offset + 16 <= count as usize {
            let size = u32_at(&buffer, offset) as usize;
            ensure!(
                size >= 16 && offset + size <= count as usize,
                "invalid netlink message"
            );
            let msg = &buffer[offset..offset + size];
            match u16_at(msg, 4) {
                3 => return Ok(result), // NLMSG_DONE
                2 => anyhow::bail!("socket diagnostics rejected"),
                20 if size >= 32 => {
                    let inode = u32_at(msg, 20);
                    let mut socket = UnixSocket::default();
                    let mut attr = 32;
                    while attr + 4 <= size {
                        let len = u16_at(msg, attr) as usize;
                        ensure!(len >= 4 && attr + len <= size, "invalid socket attribute");
                        let value = &msg[attr + 4..attr + len];
                        match u16_at(msg, attr + 2) {
                            0 if value.first().is_some_and(|b| *b != 0) => {
                                let end = value.iter().position(|b| *b == 0).unwrap_or(value.len());
                                if let Ok(name) = std::str::from_utf8(&value[..end]) {
                                    socket.name = Some(PathBuf::from(name));
                                }
                            }
                            2 if value.len() == 4 => socket.peer = Some(u32_at(value, 0)),
                            _ => {}
                        }
                        attr += aligned(len);
                    }
                    result.insert(inode, socket);
                }
                _ => {}
            }
            offset += aligned(size);
        }
    }
}
pub fn process_sockets(pid: u32) -> HashSet<u32> {
    fs::read_dir(format!("/proc/{pid}/fd"))
        .into_iter()
        .flatten()
        .filter_map(|f| f.ok())
        .filter_map(|f| fs::read_link(f.path()).ok())
        .filter_map(|p| {
            p.to_str()?
                .strip_prefix("socket:[")?
                .strip_suffix(']')?
                .parse()
                .ok()
        })
        .collect()
}
pub fn is_zellij(pid: u32) -> bool {
    fs::read_to_string(format!("/proc/{pid}/comm"))
        .is_ok_and(|name| ["zellij", ".zellij-wrapped"].contains(&name.trim()))
}
pub fn processes() -> impl Iterator<Item = u32> {
    fs::read_dir("/proc")
        .into_iter()
        .flatten()
        .filter_map(|e| e.ok())
        .filter_map(|e| e.file_name().to_string_lossy().parse().ok())
}
#[derive(Clone)]
pub struct Session {
    pub name: String,
    pub server_pid: u32,
    pub server_start: String,
    pub path: PathBuf,
    client_socket: u32,
    server_socket: u32,
}
impl Session {
    pub fn still_connected(&self, client_pid: u32) -> bool {
        super::process(self.server_pid).is_some_and(|p| p.start == self.server_start)
            && process_sockets(client_pid).contains(&self.client_socket)
            && process_sockets(self.server_pid).contains(&self.server_socket)
    }
}
pub fn session(client_pid: u32) -> Result<Option<Session>> {
    let table = sockets()?;
    let client_sockets = process_sockets(client_pid);
    let peers: HashSet<_> = client_sockets
        .iter()
        .filter_map(|inode| table.get(inode)?.peer)
        .collect();
    let mut found = HashSet::new();
    for pid in processes().filter(|pid| is_zellij(*pid)) {
        let fds = process_sockets(pid);
        if fds.is_disjoint(&peers) {
            continue;
        }
        let args = fs::read(format!("/proc/{pid}/cmdline")).unwrap_or_default();
        let parts: Vec<_> = args.split(|b| *b == 0).collect();
        if let Some(pair) = parts.windows(2).find(|p| p[0] == b"--server")
            && let Ok(path) = std::str::from_utf8(pair[1])
        {
            let path = PathBuf::from(path);
            if fds
                .iter()
                .any(|inode| table.get(inode).and_then(|s| s.name.as_ref()) == Some(&path))
                && let Some(name) = path.file_name().and_then(|n| n.to_str())
                && let Some(server) = super::process(pid)
                && let Some((client_socket, server_socket)) =
                    client_sockets.iter().find_map(|inode| {
                        let peer = table.get(inode)?.peer?;
                        fds.contains(&peer).then_some((*inode, peer))
                    })
            {
                found.insert((
                    name.to_owned(),
                    pid,
                    server.start,
                    path,
                    client_socket,
                    server_socket,
                ));
            }
        }
    }
    ensure!(found.len() <= 1, "ambiguous Zellij server");
    Ok(found.into_iter().next().map(
        |(name, server_pid, server_start, path, client_socket, server_socket)| Session {
            name,
            server_pid,
            server_start,
            path,
            client_socket,
            server_socket,
        },
    ))
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn identifies_connected_socket_peer() {
        let (a, b) = std::os::unix::net::UnixStream::pair().unwrap();
        let inode = |fd| {
            fs::read_link(format!("/proc/self/fd/{fd}"))
                .unwrap()
                .to_string_lossy()
                .trim_start_matches("socket:[")
                .trim_end_matches(']')
                .parse::<u32>()
                .unwrap()
        };
        let table = sockets().unwrap();
        assert_eq!(
            table[&inode(a.as_raw_fd())].peer,
            Some(inode(b.as_raw_fd()))
        );
        let owner = Session {
            name: "test".into(),
            server_pid: std::process::id(),
            server_start: super::super::process(std::process::id()).unwrap().start,
            path: PathBuf::new(),
            client_socket: inode(a.as_raw_fd()),
            server_socket: inode(b.as_raw_fd()),
        };
        assert!(owner.still_connected(std::process::id()));
        drop(a);
        assert!(
            !owner.still_connected(std::process::id()),
            "cached ownership must expire with either socket endpoint"
        );
    }
}
