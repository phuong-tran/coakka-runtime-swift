#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
swift_root="$(cd "${script_dir}/.." && pwd)"

bash "${script_dir}/stage-runtime-native.sh"
bash "${script_dir}/verify-native-payload.sh"

swift --version
(
  cd "${swift_root}"
  swift test
  swift run CoAkkaRuntimeSmoke
)

echo "[swift-runtime-smoke] ok"
