#!/bin/bash
# Build Rust shared library for Android (arm64-v8a, armeabi-v7a, x86_64)
# Requires: cargo-ndk (`cargo install cargo-ndk`) and Android NDK

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

NDK_VERSION="27.2.12479018"
ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-$HOME/Library/Android/sdk/ndk/$NDK_VERSION}"

if [ ! -d "$ANDROID_NDK_HOME" ]; then
  echo "NDK not found at $ANDROID_NDK_HOME"
  echo "Install via: sdkmanager \"ndk;$NDK_VERSION\""
  exit 1
fi

export ANDROID_NDK_HOME

echo "Building Rust for Android (arm64-v8a, armeabi-v7a, x86_64)..."
cargo ndk \
  -t arm64-v8a \
  -t armeabi-v7a \
  -t x86_64 \
  -o "$SCRIPT_DIR/../android/app/src/main/jniLibs" \
  build --release --manifest-path "$SCRIPT_DIR/Cargo.toml"

echo "Done: android/app/src/main/jniLibs/"
