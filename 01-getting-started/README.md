# 01 — Getting Started with Red Hat Enterprise Linux

**RH024 Chapter 1**

## Objective

Learn how to identify the fundamental facts about a Linux system: which
distribution and version it runs, its kernel and architecture, how long it
has been up, whether it is virtualized, and a quick look at resources.

## What the script demonstrates

`system-info.sh` prints a clean, read-only overview of the machine in
labelled sections:

- **Distribution** — name, version, and ID from `/etc/os-release`.
- **Kernel & Architecture** — `uname` details and the kernel build string
  from `/proc/version`.
- **Uptime & Load** — `uptime`, including boot time when supported.
- **Virtualization** — `systemd-detect-virt` with a `/proc/1/cgroup`
  container fallback.
- **Session** — current user, privilege level, home, shell, date.
- **Resources** — CPU threads, total memory, root filesystem usage.

It is **distro-agnostic**: any missing tool produces an informational message
instead of an error, so it runs anywhere and highlights RHEL-specific tools
when they are present.

## How to run

```sh
chmod +x system-info.sh
./system-info.sh
./system-info.sh --help
```

## Sample output (abridged)

```
== Distribution ==
  Name                   Red Hat Enterprise Linux
  Version                9.4 (Plow)
  ID                     rhel
  Pretty name            Red Hat Enterprise Linux 9.4 (Plow)

== Kernel & Architecture ==
  Kernel                 Linux
  Kernel release         5.14.0-427.el9.x86_64
  Architecture           x86_64
  Hostname               rhel9.example.com

== Virtualization ==
  Platform               kvm
...
```

## Key commands & takeaways

| Command | Purpose |
|---------|---------|
| `cat /etc/os-release` | Distribution identity (all modern distros) |
| `cat /etc/redhat-release` | RHEL-specific release string |
| `uname -r` | Running kernel release |
| `uname -m` | Hardware architecture |
| `uptime` / `uptime -p` | Load averages and how long the system has run |
| `systemd-detect-virt` | Bare metal vs. VM vs. container |
| `subscription-manager status` | RHEL entitlement/support status |

**Takeaway:** before doing anything else on a system, establish *what* it is —
distro, version, kernel, and platform — because that determines available
packages, tools, and support.
