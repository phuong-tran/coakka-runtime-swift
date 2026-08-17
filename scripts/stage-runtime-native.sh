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
    macos-aarch64) printf '%s\n' "956f6cf04c18a923cc6416366b1a1ee1e5cae67e6f61bf3988e6bbeb09db6a7c" ;;
    linux-aarch64) printf '%s\n' "9ccd618dbb18fb32a0d7201f13a3163de175c7037c3e5325e84824bb32e1843c" ;;
    linux-x86_64) printf '%s\n' "465e831fa564cde87fe3af29390071e4241390e1edcd0153c55ce00017f2c248" ;;
    windows-aarch64) printf '%s\n' "ae26021aac51ae19d06e317b9ce5a43befa9ef1bc8997e6bbd238e09036df3f9" ;;
    windows-x86_64) printf '%s\n' "795615adb861b74d9c017d480a377a08cd355e1fb83648f06b43ee85c5f049d6" ;;
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
