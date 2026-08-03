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
  "5935b613a7e9ff3662712d9af1c68d24d34460a58d5900d47d5a12341e754d79" \
  "Mach-O 64-bit dynamically linked shared library arm64"
verify_native \
  "linux-aarch64/libcoakka_runtime_v2.so" \
  "686666fed7211e959cee2512374a5c1083bb90805a894f2e471655a14d1af1dd" \
  "ELF 64-bit LSB shared object, ARM aarch64"
verify_native \
  "linux-x86_64/libcoakka_runtime_v2.so" \
  "cdf36ac53578b81ade018c26d45794ff9cccebda3a72fec7a3ead27880dbb4f9" \
  "ELF 64-bit LSB shared object, x86-64"
verify_native \
  "windows-aarch64/libcoakka_runtime_v2.dll" \
  "ce3d54b3f4046e13a27d099758a4a1c4991cc6fd7e87e1836b129d7d633562e3" \
  "PE32\\+ executable \\(DLL\\).*Aarch64"
verify_native \
  "windows-x86_64/libcoakka_runtime_v2.dll" \
  "4cd5cdc8c43f84b1f5fb3fa49113e8de900d94aff35b8a6bed0ea6566c51b186" \
  "PE32\\+ executable \\(DLL\\).*x86-64"

entries="$(find "${resource_root}" -type f \( -name '*.so' -o -name '*.dylib' -o -name '*.dll' \) | sort)"
count="$(printf '%s\n' "${entries}" | sed '/^$/d' | wc -l | tr -d ' ')"
if [[ "${count}" != "5" ]]; then
  echo "[swift-verify-runtime] expected exactly 5 native entries, got ${count}" >&2
  printf '%s\n' "${entries}" >&2
  exit 1
fi

echo "[swift-verify-runtime] exact unsigned native payload ok (macOS/Linux/Windows)"
