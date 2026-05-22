#!/bin/bash
# Build Rust shared library for Windows
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Building Rust for Windows..."
cargo build --release --manifest-path "$SCRIPT_DIR/Cargo.toml"

echo "Done: $SCRIPT_DIR/target/release/plans_core.dll"
