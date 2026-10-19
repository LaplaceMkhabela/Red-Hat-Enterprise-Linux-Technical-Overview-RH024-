#!/usr/bin/env bash
#
# cli-tour.sh
#
# RH024 - Chapter 2: Accessing the Command Line
#
# Objective:
#   Tour the core bash concepts every RHEL user needs on day one:
#   shell variables, exit codes ($?), input/output redirection,
#   pipes, filename globbing, aliases, and command history.
#
# Usage:
#   ./cli-tour.sh          Run the guided tour
#   ./cli-tour.sh --help   Show this help
#
# Notes:
#   - Distro-agnostic: missing tools produce a note, never a hard failure.
#   - Non-destructive: every file write happens inside a throwaway sandbox
#     under ${TMPDIR:-/tmp}/rh024-demo/cli-tour, removed on exit.
#
set -u

# ---------------------------------------------------------------------------
# Small inline helpers (kept local so this project is self-contained)
# ---------------------------------------------------------------------------
have() { command -v "$1" >/dev/null 2>&1; }

section() { printf '\n== %s ==\n' "$1"; }
cmd()     { printf '  $ %s\n' "$1"; }
note()    { printf '    %s\n' "$1"; }
ok()      { printf '  %-22s %s\n' "$1" "$2"; }
warn()    { printf '  %-22s %s\n' "($1)" "$2"; }

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
# Sandbox for every file write (cleaned up on exit)
# ---------------------------------------------------------------------------
SANDBOX="${TMPDIR:-/tmp}/rh024-demo/cli-tour"
cleanup() { rm -rf "$SANDBOX"; }
mkdir -p "$SANDBOX" || { printf 'Cannot create sandbox: %s\n' "$SANDBOX" >&2; exit 1; }
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Shell variables
# ---------------------------------------------------------------------------
section "Shell Variables"

cmd 'MY_VAR="Red Hat Enterprise Linux"'
MY_VAR="Red Hat Enterprise Linux"
note "\"\$MY_VAR\" expands to: $MY_VAR"

cmd 'set -- $MY_VAR; echo $#'
# shellcheck disable=SC2086  # unquoted on purpose: word splitting is the lesson
note "unquoted expansion yields $(set -- $MY_VAR; echo $#) words (word splitting)"

cmd 'echo "$MY_VAR"'
note "quoted expansion stays one literal string"

cmd 'export MY_VAR'
export MY_VAR
if have printenv && printenv MY_VAR >/dev/null 2>&1; then
  ok "printenv MY_VAR" "$(printenv MY_VAR)"
  note "exported variables are visible to child processes and scripts"
else
  warn "printenv" "not available, or variable was not exported"
fi

cmd 'echo "${EDITOR:-"(not set)"}"'
note "EDITOR is ${EDITOR:-(not set)} — \${VAR:-default} supplies a fallback"

# ---------------------------------------------------------------------------
# Exit codes
# ---------------------------------------------------------------------------
section "Exit Codes (\$?)"

cmd 'true; echo $?'
true
note "true always succeeds -> $?"

cmd 'false; echo $?'
false
note "false always fails -> $?"

cmd 'ls /definitely/not/here 2>/dev/null; echo $?'
ls /definitely/not/here >/dev/null 2>&1
note "a missing path makes ls fail -> $?"

if [ -r /etc/passwd ]; then
  grep -q '^root:' /etc/passwd 2>/dev/null
  rc=$?
  cmd "grep -q '^root:' /etc/passwd; echo \$?"
  note "grep found a match -> $rc"
fi

note "Convention: 0 = success, 1-255 = failure."
note "'if cmd; then ...' tests \$? implicitly — no need to echo it."

# ---------------------------------------------------------------------------
# Redirection
# ---------------------------------------------------------------------------
section "Redirection"

cmd 'echo "hello" > notes.txt        # overwrite stdout'
printf 'hello\n' > "$SANDBOX/notes.txt"
note "notes.txt -> $(cat "$SANDBOX/notes.txt")"

cmd 'echo "world" >> notes.txt       # append to stdout'
printf 'world\n' >> "$SANDBOX/notes.txt"
note "notes.txt now:"
sed 's/^/      | /' "$SANDBOX/notes.txt"

cmd 'ls /definitely/not/here 2> errors.txt   # stderr to a file'
ls /definitely/not/here > "$SANDBOX/errors.txt" 2>&1
note "captured message: $(head -n 1 "$SANDBOX/errors.txt")"

cmd 'command > all.output 2>&1       # merge stderr into stdout'
ls /definitely/not/here > "$SANDBOX/all.output" 2>&1
note "all.output holds $(wc -l < "$SANDBOX/all.output") line(s)"

cmd 'sort <<EOF ... EOF              # here-document feeds stdin'
sorted="$(sort <<'EOF'
pear
apple
mango
EOF
)"
printf '%s\n' "$sorted" | sed 's/^/      /'

# ---------------------------------------------------------------------------
# Pipes
# ---------------------------------------------------------------------------
section "Pipes"

cmd 'cat /etc/passwd | cut -d: -f1 | head -n 5'
if [ -r /etc/passwd ]; then
  cut -d: -f1 /etc/passwd | head -n 5 | sed 's/^/      /'
else
  warn "/etc/passwd" "not readable on this system"
fi
note "each stage transforms the stream for the next one"

cmd 'uname -s -r -m | tr " " "|"'
note "$(uname -s -r -m | tr ' ' '|')"

if have ps; then
  cmd 'ps -eo comm= | sort | uniq -c | sort -rn | head -n 5'
  note "top 5 process names by instance count:"
  ps -eo comm= 2>/dev/null | sort | uniq -c | sort -rn | head -n 5 | sed 's/^/      /'
fi

cmd 'true | false; echo $?'
true | false
note "a pipeline's status is its LAST stage's: $?"

# ---------------------------------------------------------------------------
# Filename globbing
# ---------------------------------------------------------------------------
section "Filename Globbing"

mkdir -p "$SANDBOX/glob"
touch "$SANDBOX/glob"/report-2024-Q1.txt \
      "$SANDBOX/glob"/report-2024-Q2.txt \
      "$SANDBOX/glob"/report-2025-Q1.txt \
      "$SANDBOX/glob"/notes.md \
      "$SANDBOX/glob"/a.log \
      "$SANDBOX/glob"/b.log

cmd 'ls report-2025-*.txt'
(cd "$SANDBOX/glob" && ls report-2025-*.txt) | sed 's/^/      /'

cmd 'ls report-*-Q1.txt'
(cd "$SANDBOX/glob" && ls report-*-Q1.txt) | sed 's/^/      /'

cmd 'ls ?.log              # ? matches exactly one character'
(cd "$SANDBOX/glob" && ls ?.log) | sed 's/^/      /'

cmd 'ls [ab].log           # [..] matches one listed character'
(cd "$SANDBOX/glob" && ls [ab].log) | sed 's/^/      /'

cmd "ls '*.txt'            # quotes disable globbing -> literal name"
note "the shell expands unquoted patterns BEFORE the command runs;"
note "a quoted '*' is passed through as a literal asterisk."

# ---------------------------------------------------------------------------
# Aliases
# ---------------------------------------------------------------------------
section "Aliases"

shopt -s expand_aliases   # aliases are off by default in non-interactive shells

cmd "alias greet='echo Hello from'"
alias greet='echo Hello from'
cmd 'greet "the command line tour"'
greet "the command line tour" | sed 's/^/      /'

cmd "alias please='sudo'  # classic RH024 example: retry as root"
alias please='sudo'
cmd 'type please'
note "$(type please)"

cmd 'unalias please'
unalias please
note "after unalias, 'type please' says: $(type please 2>&1)"

note "In an interactive shell, 'alias' lists them all. Scripts should prefer"
note "full commands or functions; aliases are interactive conveniences."

# ---------------------------------------------------------------------------
# Command history
# ---------------------------------------------------------------------------
section "Command History"

ok "HISTSIZE" "${HISTSIZE:-unset in this shell}"
ok "HISTFILE" "${HISTFILE:-unset (non-interactive shells do not save)}"

cmd 'set -o history; history -c'
set -o history
history -c
cmd "history -s 'ls -l /etc'"
history -s 'ls -l /etc'
history -s 'grep root /etc/passwd'
cmd 'history'
history | sed 's/^/      /'

note "Interactive extras: Ctrl+R reverse-searches history; '!!' re-runs the"
note "last command; '!$' reuses its last argument; 'history -c' clears it."
note "HISTFILE (usually ~/.bash_history) is what persists history to disk."

# ---------------------------------------------------------------------------
# Everyday keystrokes (from the course)
# ---------------------------------------------------------------------------
section "Course Keystrokes"

note "Tab           complete commands, paths, and variables"
note "Ctrl+A / E    jump to start / end of the line"
note "Ctrl+R        reverse-search history"
note "Ctrl+U / K    cut to start / end of the line"
note "Ctrl+C        abort the current command"
note "Ctrl+L        clear the screen (same as 'clear')"
note "Esc .         insert the last argument of the previous command"

printf '\nSandbox %s was removed on exit.\n' "$SANDBOX"
exit 0
