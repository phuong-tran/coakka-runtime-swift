#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
swift_root="$(cd "${script_dir}/.." && pwd)"
package_version="2.5.2"
archive="${swift_root}/coakka-runtime-swift-${package_version}.tar.gz"
work_root="$(mktemp -d "${TMPDIR:-/tmp}/coakka-swift-package.XXXXXX")"
package_root="${work_root}/coakka-runtime-swift-${package_version}"

trap 'rm -rf "${work_root}"' EXIT

if [[ "${COAKKA_SWIFT_USE_EXISTING_PACKAGE:-0}" == "1" ]]; then
  [[ -f "${archive}" ]] || { echo "[swift-package-readiness] missing archive: ${archive}" >&2; exit 1; }
  tar -xzf "${archive}" -C "${work_root}"
else
  bash "${script_dir}/export-module-repo.sh" "${package_root}" >/dev/null
  rm -f "${archive}"
  COPYFILE_DISABLE=1 tar -C "${work_root}" -czf "${archive}" "$(basename "${package_root}")"
fi

required=(
  Package.swift
  README.md
  LICENSE
  NATIVE-LICENSE.md
  PACKAGE-LICENSE.md
  NOTICE
  RELEASE.md
  RELEASE_NOTES.md
  TRANSPORT_CONFIGURATION.md
  coakka-runtime-package.json
  Sources/CoAkkaRuntime/FileLane.swift
  Sources/CoAkkaRuntime/StreamLane.swift
  Sources/CoAkkaRuntime/RuntimeTransport.swift
  Sources/CoAkkaRuntimeC/coakka_runtime_bridge.c
  Sources/CoAkkaRuntimeTransportSmoke/main.swift
  scripts/check-platform-bridge-source.sh
  Sources/CoAkkaRuntime/Resources/macos-aarch64/libcoakka_runtime_v2.dylib
  Sources/CoAkkaRuntime/Resources/linux-aarch64/libcoakka_runtime_v2.so
  Sources/CoAkkaRuntime/Resources/linux-x86_64/libcoakka_runtime_v2.so
  Sources/CoAkkaRuntime/Resources/windows-aarch64/libcoakka_runtime_v2.dll
  Sources/CoAkkaRuntime/Resources/windows-x86_64/libcoakka_runtime_v2.dll
)
for file in "${required[@]}"; do
  [[ -f "${package_root}/${file}" ]] || {
    echo "[swift-package-readiness] missing ${file}" >&2
    exit 1
  }
done

grep -Fq "polyglot, multi-language, multi-platform" "${package_root}/README.md"
grep -Fq "CoAkka is not a Swift-only runtime" "${package_root}/README.md"
grep -Fq "https://github.com/phuong-tran/coakka-samples/blob/main/docs/README.md" \
  "${package_root}/README.md"
grep -Fq "https://raw.githubusercontent.com/phuong-tran/coakka-samples/main/docs/assets/brand/coakka-logo.png" \
  "${package_root}/README.md"
grep -Fq "https://github.com/phuong-tran/coakka-samples/blob/main/docs/runtime-file-transfer.md" "${package_root}/README.md"
grep -Fq "https://github.com/phuong-tran/coakka-samples/blob/main/docs/runtime-streaming.md" "${package_root}/README.md"
grep -Fq "https://github.com/phuong-tran/coakka-samples/blob/main/docs/ai-assisted-integration.md" "${package_root}/README.md"

(cd "${package_root}" && bash scripts/verify-native-payload.sh)
python3 - "${package_root}/coakka-runtime-package.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as stream:
    metadata = json.load(stream)

assert metadata["artifact_version"] == "2.5.2"
assert metadata["bundled_native_package_version"] == "2.5.0+4b65d0b2256037bf7fc180bfa6df8c41efc1dd6a"
assert metadata["publisher_signing"] == "absent"
assert metadata["supported_platforms"] == [
    "macos-aarch64",
    "linux-aarch64",
    "linux-x86_64",
    "windows-aarch64",
    "windows-x86_64",
]
PY

if rg -ni "preview|enterprise|1\.3\.4|dc6ec284|There should be no Linux|macOS-only|/Users/phuongtran|Staged, Not Published|source slice|source train|checkpoint|coakkaCoreNativeDev/blob|does not authorize|must not be uploaded" \
  "${package_root}/README.md" \
  "${package_root}/NATIVE-LICENSE.md" \
  "${package_root}/RELEASE.md" \
  "${package_root}/RELEASE_NOTES.md" \
  "${package_root}/TRANSPORT_CONFIGURATION.md" \
  "${package_root}/coakka-runtime-package.json"; then
  echo "[swift-package-readiness] stale or host-local metadata found" >&2
  exit 1
fi

echo "[swift-package-readiness] ok ${archive}"
