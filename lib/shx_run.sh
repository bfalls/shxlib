# animate-text.sh
#!/usr/bin/env bash
# shellcheck shell=bash

ANIM_SPINNER_COLORS=( $'\e[90m' $'\e[37m' $'\e[97m' $'\e[37m' )

__set_spinner_glyphs() {
  local style="${1:-dots}"
  case "$style" in
    moredots)  SPINNER_GLYPHS=( "·" "•" "●" ) ;;
    dots)      SPINNER_GLYPHS=( "·" "•" ) ;;
    ascii)     SPINNER_GLYPHS=( "o" "O" ) ;;
    line)      SPINNER_GLYPHS=( "|" "/" "-" "\\" ) ;;
    star)      SPINNER_GLYPHS=( "+" "x" ) ;;
    pulse)     SPINNER_GLYPHS=( "▁" "▃" "▅" "▇" ) ;;
    block)     SPINNER_GLYPHS=( "░" "▒" "▓" "█" ) ;;
    circle)    SPINNER_GLYPHS=( "○" "◔" "◑" "◕" ) ;;
    quad)      SPINNER_GLYPHS=( "◐" "◓" "◑" "◒" ) ;;
    arrow)     SPINNER_GLYPHS=( "▹" "▸" ) ;;
    caret)     SPINNER_GLYPHS=( "^" ">" "v" "<" ) ;;
    minimal)   SPINNER_GLYPHS=( "-" "+" ) ;;
    *)         SPINNER_GLYPHS=( "·" "•" ) ;;
  esac
}

__print_final() {
  local tty_fd="$1"
  local rc="$2"
  local text="$3"

  local GRAY=$'\e[90m'
  local GREEN=$'\e[92m'
  local RED=$'\e[91m'
  local RESET=$'\e[0m'
  local CLEARLINE=$'\e[2K'

  local status color
  if [[ "$rc" -eq 0 ]]; then
    status="✓"
    color="$GREEN"
  else
    status="X"
    color="$RED"
  fi

  printf '\r%b%b %b%b\n' "$CLEARLINE" "${color}${status}${RESET}" "${GRAY}${text}" "$RESET" >&"$tty_fd"
}

__is_tty_available() {
  [[ -t 1 && -e /dev/tty ]]
}

# Usage:
#   shx_run [options] "Message..." -- cmd args...
#
# Options:
#   --style <dots|ascii|line|star>   Spinner style (default: dots)
#   --capture                        Capture cmd stdout/stderr, print after status line
#   --no-capture                     Stream output live (recommended only for interactive commands; otherwise captured output keeps status lines clean)
#   --no-tty-ok                      If no TTY, run command normally (no animation)
#   --hl <N>                         Number of highlighted characters (default: 3)
#   --s <N>                          Speed of highlight (default: 0.02)
shx_run() {
  local style="dots"
  local capture=1
  local no_tty_ok=0
  local highlight_width=3
  local highlight_speed="0.02"

  while [[ "${1:-}" == --* ]]; do
    case "$1" in
      --style)      style="${2:-dots}"; shift 2 ;;
      --capture)    capture=1; shift ;;
      --no-capture) capture=0; shift ;;
      --no-tty-ok)  no_tty_ok=1; shift ;;
      --hl)         highlight_width="${2:-3}"; shift 2 ;;
      --s)          highlight_speed="${2:-0.02}"; shift 2 ;;
      --)           shift; break ;;
      *)            break ;;
    esac
  done

  local text="$1"; shift
  if [[ "${1:-}" == "--" ]]; then shift; fi

  # If no TTY, either fail or run plainly
  if ! __is_tty_available; then
    if (( no_tty_ok )); then
      if (( capture )); then
        local tmp
        tmp="$(mktemp 2>/dev/null || printf '/tmp/anim.%s' "$$")"
        "$@" >"$tmp" 2>&1
        local rc=$?
        cat "$tmp"
        rm -f "$tmp"
        return "$rc"
      else
        "$@"
        return $?
      fi
    fi
    echo "No TTY available for animation (use --no-tty-ok to run without animation)" >&2
    return 2
  fi

  __set_spinner_glyphs "$style"

  exec 3>/dev/tty || { echo "No /dev/tty available"; return 2; }

  local speed="$highlight_speed" width="$highlight_width" step="1"
  local glyph_interval="0.5"  # status glyph changes
  local len=${#text}
  local GRAY=$'\e[90m' WHITE=$'\e[97m' RESET=$'\e[0m' CLEARLINE=$'\e[2K'

  local tmp=""
  if (( capture )); then
    tmp="$(mktemp 2>/dev/null || printf '/tmp/anim.%s' "$$")"
  fi

  # Run the command in background (optionally capturing output)
  if (( capture )); then
    "$@" >"$tmp" 2>&1 &
  else
    "$@" &
  fi
  local cmd_pid=$!

  trap 'kill '"$cmd_pid"' 2>/dev/null || true; wait '"$cmd_pid"' 2>/dev/null || true; printf "\n" >&3; exec 3>&-; (( capture )) && rm -f "'"$tmp"'"; exit 130' INT TERM

  # Temporarily disable errexit inside this function
  local had_errexit=0
  case "$-" in *e*) had_errexit=1; set +e ;; esac

  local i=0 tick=0
  local last_glyph_change
  last_glyph_change="$(date +%s)"   # seconds resolution is enough for 0.5s? better below

    # Use milliseconds if available; fall back to seconds.
  _now_ms() {
    local ms
    ms="$(date +%s%3N 2>/dev/null)" || ms=""
    if [[ -n "$ms" ]]; then
      echo "$ms"
    else
      # fallback: seconds * 1000
      echo "$(( $(date +%s) * 1000 ))"
    fi
  }

  local last_ms="$(_now_ms)"
  local interval_ms=500

  while kill -0 "$cmd_pid" 2>/dev/null; do
    local now_ms="$(_now_ms)"
    if (( now_ms - last_ms >= interval_ms )); then
      (( tick++ ))
      last_ms="$now_ms"
    fi

    local g_idx=$(( tick % ${#SPINNER_GLYPHS[@]} ))
    local c_idx=$(( tick % ${#ANIM_SPINNER_COLORS[@]} ))
    local glyph="${SPINNER_GLYPHS[$g_idx]}"
    local color="${ANIM_SPINNER_COLORS[$c_idx]}"

    # ... build out=... same as before ...
        local out="" j ch
    for ((j=0; j<len; j++)); do
      ch="${text:j:1}"
      if (( j >= i-(width-1) && j <= i )); then
        out+="${WHITE}${ch}"
      else
        out+="${GRAY}${ch}"
      fi
    done

    printf '\r%b%b%b%b %b%b' "$CLEARLINE" "$color" "$glyph" "$RESET" "$out" "$RESET" >&3
    sleep "$speed"
    (( i += step )); (( i >= len + width )) && i=0
  done

  # wait can be flaky under Git Bash; never let it abort the caller
  wait "$cmd_pid" 2>/dev/null
  local rc=$?
  if (( rc == 127 )); then rc=1; fi

  trap - INT TERM
  __print_final 3 "$rc" "$text"
  exec 3>&-

  if (( capture )); then
    # Print captured output after the final status line
    cat "$tmp"
    rm -f "$tmp"
  fi

  if (( had_errexit )); then set -e; fi
  return "$rc"
}
