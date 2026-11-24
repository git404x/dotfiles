{ ... }:

{
  boot.kernel.sysctl = {
    # Restrict unprivileged eBPF (blocks local privilege escalation exploits)
    "kernel.unprivileged_bpf_disabled" = 1;

    # Hide kernel pointers/addresses from unprivileged users (blocks ROP gadget finding)
    "kernel.kptr_restrict" = 2;

    # Restrict dmesg hardware/kernel logs to privileged users (stops address leaks)
    "kernel.dmesg_restrict" = 1;

    # Restrict ptrace: apps can only inspect child processes (blocks memory spying)
    "kernel.yama.ptrace_scope" = 1;

    # Disable core dumps for setuid binaries (prevents credential leakage on crash)
    "fs.suid_dumpable" = 0;

    # Protect against link & FIFO race condition traps in /tmp
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;

    # Mitigate TCP TIME-WAIT connection assassination (RFC 1337)
    "net.ipv4.tcp_rfc1337" = 1;

    # Enable strict reverse-path filtering (blocks spoofed IP packets)
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;

    # Ignore ICMP route redirects (prevents rogue Wi-Fi MITM route poisoning)
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
  };
}
