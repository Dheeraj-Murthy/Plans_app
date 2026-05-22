#!/bin/bash
# Build Rust shared library for Linux
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Building Rust for Linux..."
cargo build --release --manifest-path "$SCRIPT_DIR/Cargo.toml"

echo "Done: $SCRIPT_DIR/target/release/libplans_core.so"
