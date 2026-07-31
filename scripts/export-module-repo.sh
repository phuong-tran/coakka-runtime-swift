#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  scripts/export-module-repo.sh DEST_DIR

Stages and verifies the Swift runtime source package, then copies it into
DEST_DIR so DEST_DIR can be committed as the root of the public SwiftPM repo:

  github.com/phuong-tran/coakka-runtime-swift

DEST_DIR must not exist or must be empty.
EOF
}

if [[ $# -ne 1 ]]; then
  usage
  exit 2
fi

dest_dir="$1"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
swift_root="$(cd "${script_dir}/.." && pwd)"

if [[ -e "${dest_dir}" ]] && [[ -n "$(find "${dest_dir}" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
  echo "[swift-export-runtime-module] destination is not empty: ${dest_dir}" >&2
  exit 1
fi

bash "${script_dir}/smoke-package.sh"

mkdir -p "${dest_dir}"
tar \
  --exclude './.build' \
  --exclude './.swiftpm' \
  -C "${swift_root}" \
  -cf - . | tar -C "${dest_dir}" -xf -

echo "[swift-export-runtime-module] module=${dest_dir}"
echo "[swift-export-runtime-module] path=github.com/phuong-tran/coakka-runtime-swift"
echo "[swift-export-runtime-module] native=1.3.3+282f3ad"
