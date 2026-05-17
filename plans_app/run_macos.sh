#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Building Rust library ==="
bash rust/build_macos.sh

echo "=== Building and running Flutter macOS app ==="
flutter run -d macos "$@"
