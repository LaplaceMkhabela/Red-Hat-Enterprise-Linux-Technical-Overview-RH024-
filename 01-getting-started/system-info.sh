#!/usr/bin/env bash
#
# system-info.sh
#
# RH024 - Chapter 1: Getting Started with Red Hat Enterprise Linux
#
# Objective:
#   Introduce the fundamental identity of a Linux system: which distribution
#   and version it runs, the kernel, the architecture, how long it has been
#   up, whether it is virtualized, and a few high-level resource facts.
#
# Usage:
#   ./system-info.sh          Print a system overview
#   ./system-info.sh --help   Show this help
#
# Notes:
#   - Distro-agnostic: reads /etc/os-release and degrades gracefully when a
#     tool is missing instead of failing.
#   - Read-only: makes no changes to the system.
#
set -u

# ---------------------------------------------------------------------------
# Small inline helpers (kept local so this project is self-contained)
# ---------------------------------------------------------------------------
have() { command -v "$1" >/dev/null 2>&1; }

section() {
  printf '\n== %s ==\n' "$1"
}

ok() {
  printf '  %-22s %s\n' "$1" "$2"
}

warn() {
  printf '  %-22s %s\n' "($1)" "$2"
}

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

# ---------------------------------------------------------------------------
# Argument handling
# ---------------------------------------------------------------------------
case "${1:-}" in
  -h|--help) usage ;;
  "") ;;
  *) printf 'Unknown argument: %s\n' "$1" >&2; usage ;;
esac

# ---------------------------------------------------------------------------
# Distribution
# ---------------------------------------------------------------------------
section "Distribution"

distro_name="unknown"
distro_version="unknown"
distro_id="unknown"

if [ -r /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  distro_name="${NAME:-unknown}"
  distro_version="${VERSION:-${VERSION_ID:-unknown}}"
  distro_id="${ID:-unknown}"
  ok "Name" "$distro_name"
  ok "Version" "$distro_version"
  ok "ID" "$distro_id"
  [ -n "${PRETTY_NAME:-}" ] && ok "Pretty name" "$PRETTY_NAME"
  [ -n "${HOME_URL:-}" ] && ok "Homepage" "$HOME_URL"
else
  warn "os-release" "/etc/os-release not readable; cannot detect distribution"
fi

# ---------------------------------------------------------------------------
# Kernel and architecture
# ---------------------------------------------------------------------------
section "Kernel & Architecture"

if have uname; then
  ok "Kernel" "$(uname -s)"
  ok "Kernel release" "$(uname -r)"
  ok "Architecture" "$(uname -m)"
  ok "Hostname" "$(uname -n)"
else
  warn "uname" "the 'uname' command is not available"
fi

if [ -r /proc/version ]; then
  ok "Compiled by" "$(cat /proc/version)"
fi

# ---------------------------------------------------------------------------
# Uptime and load
# ---------------------------------------------------------------------------
section "Uptime & Load"

if have uptime; then
  ok "Uptime" "$(uptime -p 2>/dev/null || uptime)"
  if uptime -s >/dev/null 2>&1; then
    ok "Booted at" "$(uptime -s)"
  fi
else
  warn "uptime" "the 'uptime' command is not available"
fi

# ---------------------------------------------------------------------------
# Virtualization
# ---------------------------------------------------------------------------
section "Virtualization"

virt="unknown"
if have systemd-detect-virt; then
  v="$(systemd-detect-virt 2>/dev/null)"
  [ -n "$v" ] && virt="$v"
elif [ -r /proc/1/cgroup ] && grep -qaE '(docker|lxc|kubepods|containerd)' /proc/1/cgroup 2>/dev/null; then
  virt="container"
fi

if [ "$virt" = "none" ]; then
  ok "Platform" "bare metal"
elif [ "$virt" = "unknown" ]; then
  warn "virtualization" "could not detect (systemd-detect-virt unavailable)"
else
  ok "Platform" "$virt"
fi

# ---------------------------------------------------------------------------
# Current user and host
# ---------------------------------------------------------------------------
section "Session"

ok "User" "${USER:-$(id -un 2>/dev/null)}"
[ "$(id -u 2>/dev/null)" = "0" ] && ok "Privilege" "root" || ok "Privilege" "regular user (not root)"
ok "Home" "${HOME:-unknown}"
ok "Shell" "${SHELL:-unknown}"
ok "Date" "$(date 2>/dev/null)"

# ---------------------------------------------------------------------------
# Quick resource facts
# ---------------------------------------------------------------------------
section "Resources (quick look)"

if [ -r /proc/cpuinfo ]; then
  cpus="$(grep -c '^processor' /proc/cpuinfo 2>/dev/null)"
  ok "CPU threads" "${cpus:-unknown}"
fi

if [ -r /proc/meminfo ]; then
  mem_total="$(awk '/^MemTotal:/ {printf "%.1f GiB", $2/1024/1024}' /proc/meminfo)"
  ok "Memory total" "${mem_total:-unknown}"
fi

if have df; then
  root_use="$(df -h / 2>/dev/null | awk 'NR==2 {print $3 " used / " $2 " (" $5 ")"}')"
  ok "Root filesystem" "${root_use:-unknown}"
fi

printf '\nTip: The RPMS/RHEL ecosystem uses /etc/redhat-release and /etc/os-release.\n'
printf '     On RHEL you can inspect support details with "subscription-manager status".\n'

exit 0
