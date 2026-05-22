#!/bin/bash
# Build Rust library for Linux (x86_64)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUST_DIR="$SCRIPT_DIR"

echo "Building Rust crate (release) for Linux..."
cargo build --release --manifest-path "$RUST_DIR/Cargo.toml"

echo "Shared library: $RUST_DIR/target/release/libplans_core.so"
echo "Done."
