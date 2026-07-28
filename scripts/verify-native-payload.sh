#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
swift_root="$(cd "${script_dir}/.." && pwd)"
resource_root="${swift_root}/Sources/CoAkkaRuntime/Resources"
native_path="${resource_root}/macos-aarch64/libcoakka_runtime_v2.dylib"

if [[ ! -f "${native_path}" ]]; then
  echo "[swift-verify-runtime-payload] missing macOS ARM64 native: ${native_path}" >&2
  exit 1
fi

native_entries="$(find "${resource_root}" -type f \( -name '*.so' -o -name '*.dylib' -o -name '*.dll' \) | sort)"
entry_count="$(printf '%s\n' "${native_entries}" | sed '/^$/d' | wc -l | tr -d ' ')"
if [[ "${entry_count}" != "1" ]]; then
  echo "[swift-verify-runtime-payload] expected exactly 1 native entry, got ${entry_count}" >&2
  printf '%s\n' "${native_entries}" >&2
  exit 1
fi

if printf '%s\n' "${native_entries}" | grep -Ev '/macos-aarch64/libcoakka_runtime_v2\.dylib$' >/dev/null; then
  echo "[swift-verify-runtime-payload] unexpected native entry found" >&2
  printf '%s\n' "${native_entries}" >&2
  exit 1
fi

if ! file "${native_path}" | grep -q 'Mach-O 64-bit dynamically linked shared library arm64'; then
  echo "[swift-verify-runtime-payload] native library is not macOS ARM64 dylib" >&2
  file "${native_path}" >&2
  exit 1
fi

echo "[swift-verify-runtime-payload] ok"
