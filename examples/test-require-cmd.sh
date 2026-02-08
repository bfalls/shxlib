#!/usr/bin/env bash
set -euo pipefail

# Resolve repo root from this file's location: examples/ -> repo root
this_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$this_dir/.." && pwd)"

# Source library module(s)
source "$repo_root/lib/shx_require_cmd.sh"

shx_require_cmd aws jq git
shx_require_cmd asdf123 aws qwer456
