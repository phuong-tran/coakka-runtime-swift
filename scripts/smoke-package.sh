#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
swift_root="$(cd "${script_dir}/.." && pwd)"
fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/coakka-swift-tls.XXXXXX")"

trap 'rm -rf "${fixture_root}"' EXIT

command -v openssl >/dev/null 2>&1 || {
  echo "[swift-runtime-smoke] openssl is required for the TLS reload gate" >&2
  exit 1
}

case "$(uname -s):$(uname -m)" in
  Darwin:arm64)
    feature_runtime="${swift_root}/Sources/CoAkkaRuntime/Resources/macos-aarch64/libcoakka_runtime_v2.dylib"
    ;;
  Linux:aarch64 | Linux:arm64)
    feature_runtime="${swift_root}/Sources/CoAkkaRuntime/Resources/linux-aarch64/libcoakka_runtime_v2.so"
    ;;
  Linux:x86_64 | Linux:amd64)
    feature_runtime="${swift_root}/Sources/CoAkkaRuntime/Resources/linux-x86_64/libcoakka_runtime_v2.so"
    ;;
  *)
    echo "[swift-runtime-smoke] unsupported feature-smoke host: $(uname -s):$(uname -m)" >&2
    exit 1
    ;;
esac

if [[ -n "${COAKKA_RUNTIME_LIB:-}" ]]; then
  feature_runtime="${COAKKA_RUNTIME_LIB}"
fi

openssl req -x509 -newkey rsa:2048 -nodes -sha256 \
  -subj /CN=CoAkka-Test-CA -days 2 \
  -keyout "${fixture_root}/ca.key" -out "${fixture_root}/ca.pem" >/dev/null 2>&1
printf '%s\n' \
  'subjectAltName=DNS:localhost,IP:127.0.0.1' \
  'extendedKeyUsage=serverAuth,clientAuth' \
  'keyUsage=digitalSignature,keyEncipherment' >"${fixture_root}/identity.ext"
for name in server client; do
  openssl req -newkey rsa:2048 -nodes -sha256 \
    -subj "/CN=${name}" -keyout "${fixture_root}/${name}.key" \
    -out "${fixture_root}/${name}.csr" >/dev/null 2>&1
  openssl x509 -req -sha256 -in "${fixture_root}/${name}.csr" \
    -CA "${fixture_root}/ca.pem" -CAkey "${fixture_root}/ca.key" -CAcreateserial \
    -days 2 -extfile "${fixture_root}/identity.ext" \
    -out "${fixture_root}/${name}.pem" >/dev/null 2>&1
done

bash "${script_dir}/stage-runtime-native.sh"
bash "${script_dir}/verify-native-payload.sh"

swift --version
(
  cd "${swift_root}"
  swift test
  COAKKA_FILE_LANE_RUNTIME_LIB="${feature_runtime}" \
    swift test --filter CoAkkaRuntimeTests/testFileLaneRoundtripCrossesNativeQuantum
  COAKKA_STREAM_LANE_RUNTIME_LIB="${feature_runtime}" \
    swift test --filter StreamLaneTests/testNativeRoundTripAcrossCallbacks
  swift run CoAkkaRuntimeSmoke
  COAKKA_TLS_FIXTURE_ROOT="${fixture_root}" swift run CoAkkaRuntimeTransportSmoke
)

echo "[swift-runtime-smoke] ok"
