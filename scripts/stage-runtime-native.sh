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
    macos-aarch64) printf '%s\n' "391d2256bd5276f7b9001ae9afa8900dd82c5d29e2d81bc0edc1949c509dc4c1" ;;
    linux-aarch64) printf '%s\n' "bf32ebb908cde7ab7eade427356365ad561c1a4222a950d73097ff92329b79c1" ;;
    linux-x86_64) printf '%s\n' "07b246b97bad301b81cc90bb9d6f02d9ed425227bc302bc4b9039489b60d1727" ;;
    windows-aarch64) printf '%s\n' "5662cd77be9e5446bf530c7aedbeccd4b22e5a08b3c96acd92825014abba020f" ;;
    windows-x86_64) printf '%s\n' "45e4832d0a4c05cce36ec2dea9cc3e32695159b6bc8c741fce9d0bee583a938f" ;;
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
