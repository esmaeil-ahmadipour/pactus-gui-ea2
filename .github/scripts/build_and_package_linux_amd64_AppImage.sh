#!/usr/bin/env bash

set -euo pipefail

# --------------------------------------
# CONFIGURATION
# --------------------------------------

TAG_NAME="${1:-local}"  # Use first argument as tag or fallback to 'local'
OUTPUT_NAME="PactusGUI-${TAG_NAME}-linux-amd64.AppImage"
APPDIR="AppDir"
PACTUS_CLI_URL="https://github.com/pactus-project/pactus/releases/download/v1.7.1/pactus-cli_1.7.1_linux_amd64.tar.gz"
FINAL_CLI_DEST="$APPDIR/usr/bin/lib/src/core/native_resources/linux"
APPIMAGE_TOOL="linuxdeploy-x86_64.AppImage"

# --------------------------------------
# FUNCTIONS
# --------------------------------------

install_dependencies() {
  echo "🔧 Installing dependencies..."
  sudo apt-get update
  sudo apt-get install -y \
    libgtk-3-dev libfuse2 cmake ninja-build wget appstream tree desktop-file-utils patchelf || true
}

build_flutter_linux() {
  echo "🔨 Building Flutter app for Linux AMD64..."
  flutter pub get
  flutter build linux --release
}

prepare_appdir() {
  echo "📁 Preparing AppDir..."
  rm -rf "$APPDIR"
  mkdir -p "$APPDIR/usr/bin"

  cp -r build/linux/x64/release/bundle/* "$APPDIR/usr/bin/"
  cp linux/pactus_gui.desktop "$APPDIR/"
  cp linux/pactus_gui.png "$APPDIR/"

  # Ensure the main binary is executable
  chmod +x "$APPDIR/usr/bin/pactus_gui"

  echo "✏️ Creating custom AppRun..."
  cat << 'EOF' > "$APPDIR/AppRun"
#!/bin/bash
set -e
HERE="$(dirname "$(readlink -f "$0")")"
export PACTUS_NATIVE_RESOURCES="$HERE/usr/bin/lib/src/core/native_resources/linux"
echo "PACTUS_NATIVE_RESOURCES=$PACTUS_NATIVE_RESOURCES"
echo "Running: $HERE/usr/bin/pactus_gui $*"
exec "$HERE/usr/bin/pactus_gui" "$@"
EOF
  chmod +x "$APPDIR/AppRun"
}

download_and_extract_pactus_cli() {
  echo "⬇️ Downloading pactus-cli..."
  wget -q "$PACTUS_CLI_URL" -O pactus-cli.tar.gz

  echo "📦 Extracting pactus-cli..."
  mkdir -p "$FINAL_CLI_DEST"
  tar -xzvf pactus-cli.tar.gz --strip-components=1 -C "$FINAL_CLI_DEST"

  # Make sure extracted binaries are executable
  find "$FINAL_CLI_DEST" -type f -exec chmod +x {} +
}

download_linuxdeploy_and_plugins() {
  echo "⬇️ Downloading AppImageTool for AMD64..."
  wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/${APPIMAGE_TOOL}
  chmod +x "${APPIMAGE_TOOL}"
}

build_appimage() {
  echo "🚀 Building AppImage with ${APPIMAGE_TOOL}..."
  ARCH=x86_64 ./${APPIMAGE_TOOL} "$APPDIR"

  ./linuxdeploy-x86_64.AppImage \
    --appdir "$APPDIR" \
    --desktop-file "$APPDIR/pactus_gui.desktop" \
    --icon-file "$APPDIR/pactus_gui.png" \
    --plugin gtk \
    --output appimage

  GENERATED_APPIMAGE=$(find . -maxdepth 1 -type f -name "*.AppImage" | head -n 1)

  if [[ ! -f "$GENERATED_APPIMAGE" ]]; then
    echo "❌ AppImage build failed: No AppImage file found."
    exit 1
  fi

  mkdir -p artifacts
  TARGET_PATH="artifacts/${OUTPUT_NAME}"

  echo "📦 Moving $GENERATED_APPIMAGE to $TARGET_PATH"
  mv "$GENERATED_APPIMAGE" "$TARGET_PATH"
  chmod +x "$TARGET_PATH"

  echo "✅ AppImage saved to $TARGET_PATH"

  echo "🔍 Verifying contents..."
  cp "artifacts/$OUTPUT_NAME" unpack-test.AppImage
  chmod +x unpack-test.AppImage
  ./unpack-test.AppImage --appimage-extract
  tree squashfs-root/
}

# --------------------------------------
# MAIN EXECUTION
# --------------------------------------

install_dependencies
build_flutter_linux
prepare_appdir
download_and_extract_pactus_cli
download_linuxdeploy_and_plugins
build_appimage
