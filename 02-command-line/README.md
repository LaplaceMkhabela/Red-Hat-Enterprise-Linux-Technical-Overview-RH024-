# 02 — Accessing the Command Line

**RH024 Chapter 2**

## Objective

Get comfortable with the bash shell itself: how variables work, how commands
report success or failure, how to steer input and output with redirection and
pipes, how the shell expands wildcard patterns, and how aliases and history
speed up daily work.

## What the script demonstrates

`cli-tour.sh` is a guided, read-only tour of core shell mechanics. Each
section shows a command and its real output on the current system:

- **Shell Variables** — assignment, quoting vs. word splitting,
  `${VAR:-default}` fallbacks, and promoting a variable with `export`.
- **Exit Codes** — `$?` after `true`, `false`, a failing `ls`, and `grep`;
  the *0 = success* convention.
- **Redirection** — `>` overwrite, `>>` append, `2>` stderr capture,
  `2>&1` stream merging, and a here-document feeding `sort`.
- **Pipes** — `cut`, `head`, `tr`, and the classic `sort | uniq -c` combo
  building small reports from `/etc/passwd` and `ps`; a pipeline's exit
  status is the last stage's.
- **Filename Globbing** — `*`, `?`, and `[...]` patterns against files in a
  sandbox, and how quoting disables expansion.
- **Aliases** — defining aliases (`shopt -s expand_aliases` is required
  inside scripts), the course's classic `alias please='sudo'`, inspecting
  with `type`, removing with `unalias`.
- **Command History** — `HISTSIZE`/`HISTFILE`, enabling history in a script
  via `set -o history`, and interactive shortcuts (Ctrl+R, `!!`, `!$`).

Every file write happens in a throwaway sandbox under
`${TMPDIR:-/tmp}/rh024-demo/` that is deleted when the script exits.

## How to run

```sh
chmod +x cli-tour.sh
./cli-tour.sh
./cli-tour.sh --help
```

## Sample output (abridged)

```
== Shell Variables ==
  $ MY_VAR="Red Hat Enterprise Linux"
    "$MY_VAR" expands to: Red Hat Enterprise Linux

== Exit Codes ($?) ==
  $ true; echo $?
    true always succeeds -> 0
  $ false; echo $?
    false always fails -> 1

== Redirection ==
  $ echo "hello" > notes.txt        # overwrite stdout
    notes.txt -> hello
  $ echo "world" >> notes.txt       # append to stdout
    notes.txt now:
      | hello
      | world

== Pipes ==
  $ cat /etc/passwd | cut -d: -f1 | head -n 5
      root
      bin
      daemon
      adm
      lp

== Filename Globbing ==
  $ ls report-2025-*.txt
      report-2025-Q1.txt

== Aliases ==
  $ alias please='sudo'  # classic RH024 example: retry as root
  $ type please
    please is aliased to `sudo'

== Command History ==
  HISTSIZE               unset in this shell
  $ set -o history; history -c
  $ history
          1  ls -l /etc
          2  grep root /etc/passwd
...
```

## Key commands & takeaways

| Command / Key | Purpose |
|---------------|---------|
| `VAR=value`, `export VAR` | shell variable vs. environment variable |
| `echo "${VAR:-default}"` | fallback value when a variable is unset |
| `echo $?` | exit status of the last command (0 = success) |
| `cmd > f`, `>> f`, `2> f`, `2>&1` | redirect stdout / append / stderr / both |
| `cmd1 \| cmd2` | pipe one command's output into the next |
| `sort \| uniq -c` | count duplicate lines (classic combo) |
| `ls *.txt`, `?.log`, `[ab].log` | filename globbing patterns |
| `alias`, `unalias`, `type name` | manage and inspect aliases |
| `history`, `Ctrl+R`, `!!`, `!$` | review and reuse past commands |
| `shopt -s expand_aliases` | needed for aliases inside scripts |

**Takeaway:** the command line's power comes from *composition* — small,
single-purpose tools chained with pipes and steered with redirection — with
`$?` driving every decision your scripts make.
