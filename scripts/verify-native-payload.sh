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
  "528dbaba129a19d0777230872f8c7d285fde9364f42e2e43b638de043cabe25a" \
  "Mach-O 64-bit dynamically linked shared library arm64"
verify_native \
  "linux-aarch64/libcoakka_runtime_v2.so" \
  "63af2a34f6f09993aab51a6775c869becf3eb9351d3ec519cda3543d86733c68" \
  "ELF 64-bit LSB shared object, ARM aarch64"
verify_native \
  "windows-x86_64/libcoakka_runtime_v2.dll" \
  "5820bfdec8441eba76c098a04bfb330f2788111386ea62af2e0f13b09f79579c" \
  "PE32\\+ executable \\(DLL\\).*x86-64"

entries="$(find "${resource_root}" -type f \( -name '*.so' -o -name '*.dylib' -o -name '*.dll' \) | sort)"
count="$(printf '%s\n' "${entries}" | sed '/^$/d' | wc -l | tr -d ' ')"
if [[ "${count}" != "3" ]]; then
  echo "[swift-verify-runtime] expected exactly 3 native entries, got ${count}" >&2
  printf '%s\n' "${entries}" >&2
  exit 1
fi

echo "[swift-verify-runtime] exact unsigned native payload ok (macOS/Linux/Windows)"
