#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Building Rust library ==="
bash rust/build_linux.sh

export LD_LIBRARY_PATH="$(pwd)/rust/target/release:${LD_LIBRARY_PATH:-}"

echo "=== Building and running Flutter Linux app ==="
flutter run -d linux "$@"
