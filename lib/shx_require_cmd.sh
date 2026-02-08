# shx_require_cmd
# Ensure one or more commands are available on PATH.
#
# Usage:
#   shx_require_cmd git
#   shx_require_cmd aws jq terraform
#
# Exits with code 127 if any command is missing.
shx_require_cmd() {
  local missing=()

  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    printf 'Missing required command(s): %s\n' "${missing[*]}" >&2
    return 127
  fi
}
