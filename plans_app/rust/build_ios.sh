#!/bin/bash
# Build Rust static library for iOS (device + simulator) and create xcframework

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUST_DIR="$SCRIPT_DIR"
TARGET_DIR="$RUST_DIR/target"

echo "Building Rust for iOS device (aarch64-apple-ios)..."
cargo build --release --manifest-path "$RUST_DIR/Cargo.toml" --target aarch64-apple-ios

echo "Building Rust for iOS simulator arm64 (aarch64-apple-ios-sim)..."
cargo build --release --manifest-path "$RUST_DIR/Cargo.toml" --target aarch64-apple-ios-sim

echo "Building Rust for iOS simulator x86_64 (x86_64-apple-ios)..."
cargo build --release --manifest-path "$RUST_DIR/Cargo.toml" --target x86_64-apple-ios

echo "Creating fat binary for simulator..."
mkdir -p "$TARGET_DIR/ios-sim-fat"
lipo -create \
  "$TARGET_DIR/aarch64-apple-ios-sim/release/libplans_core.a" \
  "$TARGET_DIR/x86_64-apple-ios/release/libplans_core.a" \
  -output "$TARGET_DIR/ios-sim-fat/libplans_core.a"

echo "Creating xcframework..."
rm -rf "$TARGET_DIR/plans_core.xcframework"
xcodebuild -create-xcframework \
  -library "$TARGET_DIR/aarch64-apple-ios/release/libplans_core.a" \
  -library "$TARGET_DIR/ios-sim-fat/libplans_core.a" \
  -output "$TARGET_DIR/plans_core.xcframework"

echo "Done: $TARGET_DIR/plans_core.xcframework"
