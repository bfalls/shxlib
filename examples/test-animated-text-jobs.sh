#!/usr/bin/env bash
set -euo pipefail

# Resolve repo root from this file's location: examples/ -> repo root
this_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$this_dir/.." && pwd)"

# Source library module(s)
# shellcheck source=../lib/shx_run.sh
source "$repo_root/lib/shx_run.sh"

# Failing jobs (default capture is on; keep `|| true` so the demo continues)
shx_run --style dots --no-tty-ok "Long job (fails after 10s)" -- sh -c 'echo "simulated error output" >&2; sleep 10; exit 1' || true
shx_run --style line --no-tty-ok "Line glyph (fails after 5s)" -- sh -c 'echo "simulated error output" >&2; sleep 5; exit 1' || true
shx_run --style moredots --no-tty-ok "More Dots glyph (fails after 5s)" -- sh -c 'echo "simulated error output" >&2; sleep 5; exit 1' || true

# Success job
shx_run --style star --no-tty-ok "Star glyph (succeeds after 5s)" -- sh -c 'echo "success output"; sleep 5; exit 0'
shx_run --style pulse --no-tty-ok "Pulse glyph (succeeds after 5s)" -- sh -c 'echo "success output"; sleep 5; exit 0'
shx_run --style block --no-tty-ok "Block glyph (succeeds after 5s)" -- sh -c 'echo "success output"; sleep 5; exit 0'
shx_run --style circle --no-tty-ok "Circle glyph (succeeds after 5s)" -- sh -c 'echo "success output"; sleep 5; exit 0'
shx_run --style quad --no-tty-ok "Quad glyph (succeeds after 5s)" -- sh -c 'echo "success output"; sleep 5; exit 0'
shx_run --style arrow --no-tty-ok "Arrow glyph (succeeds after 5s)" -- sh -c 'echo "success output"; sleep 5; exit 0'
shx_run --style caret --no-tty-ok "Caret glyph (succeeds after 5s)" -- sh -c 'echo "success output"; sleep 5; exit 0'
shx_run --style minimal --no-tty-ok "Minimal glyph (succeeds after 5s)" -- sh -c 'echo "success output"; sleep 5; exit 0'

shx_run --no-tty-ok --hl 10 "Use a longer highlight if you prefer (succeeds after 10s)" -- sh -c 'echo "success output"; sleep 10; exit 0'
shx_run --no-tty-ok --hl 2 "Use a short highlight if you prefer (succeeds after 5s)" -- sh -c 'echo "success output"; sleep 5; exit 0'

# Speed
shx_run --no-tty-ok --s 0 "Fast highlight if you prefer (succeeds after 5s)" -- sh -c 'echo "success output"; sleep 5; exit 0'
shx_run --no-tty-ok --s 0.1 "Slow highlight if you prefer (succeeds after 10s)" -- sh -c 'echo "success output"; sleep 10; exit 0'

# `--no-capture` demo: command controls output continuously
# Note: ping behavior varies across OSes; Ctrl-C will end it.
shx_run --no-capture --no-tty-ok "Pinging localhost (streaming output; Ctrl-C to stop)" -- ping 127.0.0.1

# Default capture demo: output appears after the final status line
shx_run --no-tty-ok "Pinging localhost (captured output; Ctrl-C to stop)" -- ping 127.0.0.1

echo "done"
