#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
swift_root="$(cd "${script_dir}/.." && pwd)"
resource_root="${swift_root}/Sources/CoAkkaRuntime/Resources"

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

verify_native() {
  local relative="$1"
  local digest="$2"
  local format="$3"
  local path="${resource_root}/${relative}"
  [[ -f "${path}" ]] || { echo "[swift-verify-runtime] missing ${relative}" >&2; exit 1; }
  [[ "$(sha256_file "${path}")" == "${digest}" ]] || {
    echo "[swift-verify-runtime] digest mismatch: ${relative}" >&2
    exit 1
  }
  file "${path}" | grep -Eq "${format}" || {
    echo "[swift-verify-runtime] format mismatch: ${relative}" >&2
    file "${path}" >&2
    exit 1
  }
}

verify_native \
  "macos-aarch64/libcoakka_runtime_v2.dylib" \
  "ce141677ebd913537dce13805ce184d71a543a1b4cfd56a24df36c51378acb8b" \
  "Mach-O 64-bit dynamically linked shared library arm64"
verify_native \
  "linux-aarch64/libcoakka_runtime_v2.so" \
  "7e450b4a76ca612cf181083443d35f8c50b851d294973eb1ed34fd7868876b5e" \
  "ELF 64-bit LSB shared object, ARM aarch64"
verify_native \
  "linux-x86_64/libcoakka_runtime_v2.so" \
  "2a0750f96410a035d27b9b83cfdcca574afc3c8d071af837bbf7db73e8b446a3" \
  "ELF 64-bit LSB shared object, x86-64"
verify_native \
  "windows-aarch64/libcoakka_runtime_v2.dll" \
  "fd2cd782acaabb70467df6c34d7f812d87415c7dee9a9898a1c335a6a16ebe97" \
  "PE32\\+ executable \\(DLL\\).*Aarch64"
verify_native \
  "windows-x86_64/libcoakka_runtime_v2.dll" \
  "1f4019b285ddbd2745b52fac223dc1b7526c86a1e6e0a2a4b9a50fbf5b256403" \
  "PE32\\+ executable \\(DLL\\).*x86-64"

entries="$(find "${resource_root}" -type f \( -name '*.so' -o -name '*.dylib' -o -name '*.dll' \) | sort)"
count="$(printf '%s\n' "${entries}" | sed '/^$/d' | wc -l | tr -d ' ')"
if [[ "${count}" != "5" ]]; then
  echo "[swift-verify-runtime] expected exactly 5 native entries, got ${count}" >&2
  printf '%s\n' "${entries}" >&2
  exit 1
fi

echo "[swift-verify-runtime] exact unsigned native payload ok (macOS/Linux/Windows)"
