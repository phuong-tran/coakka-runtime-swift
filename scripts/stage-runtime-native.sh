#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
swift_root="$(cd "${script_dir}/.." && pwd)"
repo_root="$(cd "${swift_root}/.." && pwd)"
resource_root="${swift_root}/Sources/CoAkkaRuntime/Resources/macos-aarch64"
native_dest="${resource_root}/libcoakka_runtime_v2.dylib"
core_root="${COAKKA_CORE_NATIVE_DEV:-}"

if [[ -z "${core_root}" && -d "${repo_root}/../coakkaCoreNativeDev" ]]; then
  core_root="$(cd "${repo_root}/../coakkaCoreNativeDev" && pwd)"
fi

if [[ -n "${core_root}" ]]; then
  native_source="${core_root}/build/v2/release-public-native/1.3.3+282f3ad/package/coakka-runtime-native-v2-1.3.3/native/macos-aarch64/libcoakka_runtime_v2.dylib"
  if [[ -f "${native_source}" ]]; then
    mkdir -p "${resource_root}"
    cp "${native_source}" "${native_dest}"
    echo "[swift-stage-runtime-native] staged ${native_dest}"
    exit 0
  fi
fi

if [[ -f "${native_dest}" ]]; then
  echo "[swift-stage-runtime-native] using bundled ${native_dest}"
  exit 0
fi

if [[ -n "${core_root}" ]]; then
  echo "[swift-stage-runtime-native] missing native source under ${core_root}" >&2
else
  echo "[swift-stage-runtime-native] set COAKKA_CORE_NATIVE_DEV or include ${native_dest}" >&2
fi
  exit 1
