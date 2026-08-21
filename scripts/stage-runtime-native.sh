#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
swift_root="$(cd "${script_dir}/.." && pwd)"
staging_root="${COAKKA_RUNTIME_STAGING_ROOT:-}"
resource_root="${swift_root}/Sources/CoAkkaRuntime/Resources"

if [[ -z "${staging_root}" ]]; then
  if bash "${script_dir}/verify-native-payload.sh" >/dev/null 2>&1; then
    echo "[swift-stage-runtime] using exact bundled unsigned natives"
    exit 0
  fi
  echo "[swift-stage-runtime] set COAKKA_RUNTIME_STAGING_ROOT to refresh native resources" >&2
  exit 1
fi
if [[ ! -d "${staging_root}" ]]; then
  echo "[swift-stage-runtime] staging directory not found: ${staging_root}" >&2
  exit 1
fi

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

expected_digest() {
  case "$1" in
    macos-aarch64) printf '%s\n' "277d9ff36b017f2eef2e630ac82bb9ba68f112879297e8067521fe665f82368a" ;;
    linux-aarch64) printf '%s\n' "dedacfa666c398b01e0aefa0bd9f649a6a63722645e5b822252d3e505e7fda43" ;;
    linux-x86_64) printf '%s\n' "0ce69740cff0a5f7d5b2f002340ecff645c3c82f4f50d6dfdb9fb8a19e90a38b" ;;
    windows-aarch64) printf '%s\n' "0ee49c59de50dad40fa403ce2f32b59e0da05ab7677bf3d1ca8a9ccfe2f9b545" ;;
    windows-x86_64) printf '%s\n' "a54e8a43089adf68f9275c83d0a4495bf8deb384c25f993cd13ef42233da573b" ;;
    *) echo "[swift-stage-runtime] unknown platform: $1" >&2; exit 1 ;;
  esac
}

stage_platform() {
  local platform="$1"
  local filename="$2"
  local source="${staging_root}/${platform}/${filename}"
  local destination="${resource_root}/${platform}/${filename}"
  if [[ ! -f "${source}" ]]; then
    echo "[swift-stage-runtime] missing staged runtime native: ${source}" >&2
    exit 1
  fi
  local actual
  actual="$(sha256_file "${source}")"
  if [[ "${actual}" != "$(expected_digest "${platform}")" ]]; then
    echo "[swift-stage-runtime] digest mismatch for ${platform}: ${actual}" >&2
    exit 1
  fi
  mkdir -p "$(dirname "${destination}")"
  cp "${source}" "${destination}"
  echo "[swift-stage-runtime] ${platform}/${filename}"
}

stage_platform "macos-aarch64" "libcoakka_runtime_v2.dylib"
stage_platform "linux-aarch64" "libcoakka_runtime_v2.so"
stage_platform "linux-x86_64" "libcoakka_runtime_v2.so"
stage_platform "windows-aarch64" "libcoakka_runtime_v2.dll"
stage_platform "windows-x86_64" "libcoakka_runtime_v2.dll"

echo "[swift-stage-runtime] staged unsigned natives from ${staging_root}"
