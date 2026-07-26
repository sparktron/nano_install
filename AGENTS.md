# AGENTS.md

Guidance for coding agents working in this repository. Single source of truth;
`CLAUDE.md` imports it.

## What this is

Installer scripts for **nanobot**, a local-LLM agent framework. Not an
application — three parallel installers plus setup documentation.

| File | Platform |
|---|---|
| `install_nanobot.sh` | Linux / macOS |
| `install_nanobot.ps1` | Windows PowerShell |
| `install_nanobot.bat` | Windows cmd |

Docs: `README.md`, `INSTALLATION_DEFAULTS.md`, `GPU_SETUP.md`,
`WINDOWS_SETUP.md`, `DISCORD_SETUP.md`.

Related: `nanobot-clean` in this workspace is the framework itself.

## The parity rule

The three installers are hand-maintained mirrors. A change to installation
behavior — new dependency, changed default, new prompt, different path — must
land in all three, or Windows and Unix users get different environments.

`INSTALLATION_DEFAULTS.md` documents the defaults the scripts apply. It is part
of the contract: update it in the same commit when a default changes.

## No CI

There is no test suite and no CI workflow. Nothing will catch a syntax error or
a broken code path for you.

- Shell: `bash -n install_nanobot.sh` at minimum; `shellcheck` if available.
- PowerShell: parse-check before committing.
- State clearly which of the three scripts you actually executed and which you
  only read. Do not report an installer as working if you did not run it on
  that platform.

## Installer safety

These scripts run on a user's machine, often with elevated privileges, and
install system packages and GPU drivers.

- No `curl … | bash` of unpinned remote content. Pin versions and verify
  checksums where the upstream provides them.
- Never `rm -rf` a path derived from an unvalidated variable — an empty
  variable turns it into a root delete. Quote every expansion and guard
  against empty.
- Prompt before destructive steps (removing an existing install, overwriting a
  config, changing driver versions).
- Uninstall paths must only remove what the installer created.
- Never write API keys or tokens into world-readable config, and never echo
  them during setup.
