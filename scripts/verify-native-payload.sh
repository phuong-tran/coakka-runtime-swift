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
  "391d2256bd5276f7b9001ae9afa8900dd82c5d29e2d81bc0edc1949c509dc4c1" \
  "Mach-O 64-bit dynamically linked shared library arm64"
verify_native \
  "linux-aarch64/libcoakka_runtime_v2.so" \
  "bf32ebb908cde7ab7eade427356365ad561c1a4222a950d73097ff92329b79c1" \
  "ELF 64-bit LSB shared object, ARM aarch64"
verify_native \
  "linux-x86_64/libcoakka_runtime_v2.so" \
  "07b246b97bad301b81cc90bb9d6f02d9ed425227bc302bc4b9039489b60d1727" \
  "ELF 64-bit LSB shared object, x86-64"
verify_native \
  "windows-aarch64/libcoakka_runtime_v2.dll" \
  "5662cd77be9e5446bf530c7aedbeccd4b22e5a08b3c96acd92825014abba020f" \
  "PE32\\+ executable \\(DLL\\).*Aarch64"
verify_native \
  "windows-x86_64/libcoakka_runtime_v2.dll" \
  "45e4832d0a4c05cce36ec2dea9cc3e32695159b6bc8c741fce9d0bee583a938f" \
  "PE32\\+ executable \\(DLL\\).*x86-64"

macos_native="${resource_root}/macos-aarch64/libcoakka_runtime_v2.dylib"
macos_build_version="$(xcrun vtool -show-build "${macos_native}")"
macos_minos="$(printf '%s\n' "${macos_build_version}" | awk '$1 == "minos" { print $2 }')"
if [[ "${macos_minos}" != "13.0" ]]; then
  echo "[swift-verify-runtime] expected macOS deployment target 13.0, got ${macos_minos:-missing}" >&2
  printf '%s\n' "${macos_build_version}" >&2
  exit 1
fi

entries="$(find "${resource_root}" -type f \( -name '*.so' -o -name '*.dylib' -o -name '*.dll' \) | sort)"
count="$(printf '%s\n' "${entries}" | sed '/^$/d' | wc -l | tr -d ' ')"
if [[ "${count}" != "5" ]]; then
  echo "[swift-verify-runtime] expected exactly 5 native entries, got ${count}" >&2
  printf '%s\n' "${entries}" >&2
  exit 1
fi

echo "[swift-verify-runtime] exact unsigned native payload ok (macOS 13/Linux/Windows)"
