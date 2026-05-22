#!/bin/bash
# Build Rust library for Windows (x86_64)
# Requires: rustup target add x86_64-pc-windows-msvc (or -gnu)
# Run on Windows, or cross-compile with appropriate toolchain.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUST_DIR="$SCRIPT_DIR"

echo "Building Rust crate (release) for Windows..."
cargo build --release --manifest-path "$RUST_DIR/Cargo.toml"

echo "DLL: $RUST_DIR/target/release/plans_core.dll"
echo "Done."
