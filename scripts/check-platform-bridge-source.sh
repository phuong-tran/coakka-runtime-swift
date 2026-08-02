#!/usr/bin/env bash
set -euo pipefail

command -v zig >/dev/null 2>&1 || {
  echo "[swift-platform-bridge] zig is required" >&2
  exit 1
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
swift_root="$(cd "${script_dir}/.." && pwd)"
source_file="${swift_root}/Sources/CoAkkaRuntimeC/coakka_runtime_bridge.c"
include_dir="${swift_root}/Sources/CoAkkaRuntimeC/include"
work_root="$(mktemp -d "${TMPDIR:-/tmp}/coakka-swift-bridge.XXXXXX")"

trap 'rm -rf "${work_root}"' EXIT

zig cc -target aarch64-linux-gnu -std=c11 -Wall -Wextra -Werror \
  -I "${include_dir}" -c "${source_file}" -o "${work_root}/linux-aarch64.o"
zig cc -target x86_64-windows-gnu -std=c11 -Wall -Wextra -Werror \
  -I "${include_dir}" -c "${source_file}" -o "${work_root}/windows-x86_64.o"

file "${work_root}/linux-aarch64.o" | grep -q 'ELF 64-bit.*ARM aarch64'
file "${work_root}/windows-x86_64.o" | grep -q 'Intel amd64 COFF object file'

echo "[swift-platform-bridge] Linux ARM64 and Windows x86-64 source gates ok"
