#!/bin/bash
# Build Rust library and create macOS framework bundle

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUST_DIR="$SCRIPT_DIR"
RELEASE_DIR="$RUST_DIR/target/release"
FRAMEWORK_DIR="$RELEASE_DIR/plans_core.framework"

echo "Building Rust crate (release)..."
cargo build --release --manifest-path "$RUST_DIR/Cargo.toml"

echo "Creating plans_core.framework..."
mkdir -p "$FRAMEWORK_DIR/Versions/A/Resources"
cp "$RELEASE_DIR/libplans_core.dylib" "$FRAMEWORK_DIR/Versions/A/plans_core"

cat > "$FRAMEWORK_DIR/Versions/A/Resources/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>CFBundleDevelopmentRegion</key>
<string>en</string>
<key>CFBundleExecutable</key>
<string>plans_core</string>
<key>CFBundleIdentifier</key>
<string>com.plans.plans-core</string>
<key>CFBundleInfoDictionaryVersion</key>
<string>6.0</string>
<key>CFBundleName</key>
<string>plans_core</string>
<key>CFBundlePackageType</key>
<string>FMWK</string>
<key>CFBundleShortVersionString</key>
<string>1.0</string>
<key>CFBundleVersion</key>
<string>1</string>
<key>MinimumOSVersion</key>
<string>10.15</string>
</dict>
</plist>
PLIST

ln -sfh "A" "$FRAMEWORK_DIR/Versions/Current"
ln -sf "Versions/Current/plans_core" "$FRAMEWORK_DIR/plans_core"
ln -sf "Versions/Current/Resources" "$FRAMEWORK_DIR/Resources"

echo "Framework created at $FRAMEWORK_DIR"
