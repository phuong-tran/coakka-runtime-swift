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
    macos-aarch64) printf '%s\n' "5935b613a7e9ff3662712d9af1c68d24d34460a58d5900d47d5a12341e754d79" ;;
    linux-aarch64) printf '%s\n' "686666fed7211e959cee2512374a5c1083bb90805a894f2e471655a14d1af1dd" ;;
    linux-x86_64) printf '%s\n' "cdf36ac53578b81ade018c26d45794ff9cccebda3a72fec7a3ead27880dbb4f9" ;;
    windows-aarch64) printf '%s\n' "ce3d54b3f4046e13a27d099758a4a1c4991cc6fd7e87e1836b129d7d633562e3" ;;
    windows-x86_64) printf '%s\n' "4cd5cdc8c43f84b1f5fb3fa49113e8de900d94aff35b8a6bed0ea6566c51b186" ;;
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
