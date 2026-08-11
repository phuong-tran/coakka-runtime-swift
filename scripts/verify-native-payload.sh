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
  "5ca37b5f6d5182d4bd25284785c6b386114857074c91ab9dbefecf0dedda637c" \
  "Mach-O 64-bit dynamically linked shared library arm64"
verify_native \
  "linux-aarch64/libcoakka_runtime_v2.so" \
  "9ccd618dbb18fb32a0d7201f13a3163de175c7037c3e5325e84824bb32e1843c" \
  "ELF 64-bit LSB shared object, ARM aarch64"
verify_native \
  "linux-x86_64/libcoakka_runtime_v2.so" \
  "465e831fa564cde87fe3af29390071e4241390e1edcd0153c55ce00017f2c248" \
  "ELF 64-bit LSB shared object, x86-64"
verify_native \
  "windows-aarch64/libcoakka_runtime_v2.dll" \
  "ae26021aac51ae19d06e317b9ce5a43befa9ef1bc8997e6bbd238e09036df3f9" \
  "PE32\\+ executable \\(DLL\\).*Aarch64"
verify_native \
  "windows-x86_64/libcoakka_runtime_v2.dll" \
  "795615adb861b74d9c017d480a377a08cd355e1fb83648f06b43ee85c5f049d6" \
  "PE32\\+ executable \\(DLL\\).*x86-64"

entries="$(find "${resource_root}" -type f \( -name '*.so' -o -name '*.dylib' -o -name '*.dll' \) | sort)"
count="$(printf '%s\n' "${entries}" | sed '/^$/d' | wc -l | tr -d ' ')"
if [[ "${count}" != "5" ]]; then
  echo "[swift-verify-runtime] expected exactly 5 native entries, got ${count}" >&2
  printf '%s\n' "${entries}" >&2
  exit 1
fi

echo "[swift-verify-runtime] exact unsigned native payload ok (macOS/Linux/Windows)"
