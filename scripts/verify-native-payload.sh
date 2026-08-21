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
  "277d9ff36b017f2eef2e630ac82bb9ba68f112879297e8067521fe665f82368a" \
  "Mach-O 64-bit dynamically linked shared library arm64"
verify_native \
  "linux-aarch64/libcoakka_runtime_v2.so" \
  "dedacfa666c398b01e0aefa0bd9f649a6a63722645e5b822252d3e505e7fda43" \
  "ELF 64-bit LSB shared object, ARM aarch64"
verify_native \
  "linux-x86_64/libcoakka_runtime_v2.so" \
  "0ce69740cff0a5f7d5b2f002340ecff645c3c82f4f50d6dfdb9fb8a19e90a38b" \
  "ELF 64-bit LSB shared object, x86-64"
verify_native \
  "windows-aarch64/libcoakka_runtime_v2.dll" \
  "0ee49c59de50dad40fa403ce2f32b59e0da05ab7677bf3d1ca8a9ccfe2f9b545" \
  "PE32\\+ executable \\(DLL\\).*Aarch64"
verify_native \
  "windows-x86_64/libcoakka_runtime_v2.dll" \
  "a54e8a43089adf68f9275c83d0a4495bf8deb384c25f993cd13ef42233da573b" \
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
