#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
swift_root="$(cd "${script_dir}/.." && pwd)"
connector_root="$(cd "${swift_root}/.." && pwd)"
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
    macos-aarch64) printf '%s\n' "e95cda46cd8e5d31633d005bb8af9093b2a93c9c2d0cefc90148e188f31da6d7" ;;
    linux-aarch64) printf '%s\n' "3c0cc47250e3c4ebb71633af85d205adb7bf2606d58abba0bf893a770dfde48c" ;;
    linux-x86_64) printf '%s\n' "7d8781b8eae6948eee968e422dd2097dfee43d788c4cb4a3fb3e8936bd214815" ;;
    windows-aarch64) printf '%s\n' "e932f870f6dd15fd36612f0ce404e4906faff47766f6ed40c328d4e12a69ebf0" ;;
    windows-x86_64) printf '%s\n' "dc9d352144fefb2d6789bc3ea49dd6fe1b3bb627be4f1277944bc51d49e2f3f9" ;;
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
