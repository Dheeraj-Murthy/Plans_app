#!/bin/bash
# Run on Windows via Git Bash / WSL
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Building Rust library ==="
bash rust/build_windows.sh

export PATH="$(pwd)/rust/target/release:${PATH:-}"

echo "=== Building and running Flutter Windows app ==="
flutter run -d windows "$@"
