#!/usr/bin/env bash

set -euo pipefail

# --------------------------------------
# CONFIGURATION
# --------------------------------------

TAG_NAME="${1:-local}"
ARCH="x86_64"
APPDIR="AppDir"
OUTPUT_NAME="PactusGUI-${TAG_NAME}-linux-${ARCH}.AppImage"
PACTUS_CLI_URL="https://github.com/pactus-project/pactus/releases/download/v1.7.1/pactus-cli_1.7.1_linux_amd64.tar.gz"
FINAL_CLI_DEST="$APPDIR/usr/bin/lib/src/core/native_resources/linux"
LINUXDEPLOY_TOOL="linuxdeploy-x86_64.AppImage"
GTK_PLUGIN="linuxdeploy-plugin-gtk.sh"

# --------------------------------------
# FUNCTIONS
# --------------------------------------

install_dependencies() {
  echo "🔧 Installing system dependencies..."
  sudo apt-get update
  sudo apt-get install -y \
    libgtk-3-dev libfuse2 cmake ninja-build wget \
    appstream tree patchelf desktop-file-utils zsync
}

build_flutter_linux() {
  echo "🔨 Building Flutter app for Linux ${ARCH}..."
  flutter pub get
  flutter build linux --release
}

prepare_appdir() {
  echo "📁 Preparing AppDir structure..."
  rm -rf "$APPDIR"
  mkdir -p "$APPDIR/usr/bin"

  cp -r build/linux/x64/release/bundle/* "$APPDIR/usr/bin/"
  cp linux/pactus_gui.desktop "$APPDIR/"
  cp linux/pactus_gui.png "$APPDIR/"

  echo "✏️ Creating AppRun launcher..."
  cat << 'EOF' > "$APPDIR/AppRun"
#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")"
export PACTUS_NATIVE_RESOURCES="$HERE/usr/bin/lib/src/core/native_resources/linux"
exec "$HERE/usr/bin/pactus_gui" "$@"
EOF

  chmod +x "$APPDIR/AppRun"
}

download_and_extract_pactus_cli() {
  echo "⬇️ Downloading pactus-cli..."
  wget -q "$PACTUS_CLI_URL" -O pactus-cli.tar.gz

  TEMP_EXTRACT_DIR="pactus-cli-temp"
  rm -rf "$TEMP_EXTRACT_DIR"
  mkdir -p "$TEMP_EXTRACT_DIR"
  tar -xzvf pactus-cli.tar.gz --strip-components=1 -C "$TEMP_EXTRACT_DIR"

  echo "🚚 Moving CLI to: $FINAL_CLI_DEST"
  mkdir -p "$FINAL_CLI_DEST"
  mv "$TEMP_EXTRACT_DIR"/* "$FINAL_CLI_DEST"/
  rm -rf "$TEMP_EXTRACT_DIR"
}

download_linuxdeploy() {
  echo "⬇️ Downloading linuxdeploy and GTK plugin..."
  wget -q "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/${LINUXDEPLOY_TOOL}"
  chmod +x "${LINUXDEPLOY_TOOL}"

  wget -q "https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/master/${GTK_PLUGIN}"
  chmod +x "${GTK_PLUGIN}"
}

build_appimage() {
  echo "📦 Building AppImage with linuxdeploy..."

  export ARCH=${ARCH}
  export OUTPUT=appimage
  export VERBOSE=1

  ./"${LINUXDEPLOY_TOOL}" \
    --appdir "$APPDIR" \
    --desktop-file "$APPDIR/pactus_gui.desktop" \
    --icon-file "$APPDIR/pactus_gui.png" \
    --plugin gtk \
    --output appimage

  GENERATED_APPIMAGE=$(find . -maxdepth 1 -type f -name "*.AppImage" | head -n 1)
  if [[ ! -f "$GENERATED_APPIMAGE" ]]; then
    echo "❌ AppImage build failed!"
    exit 1
  fi

  mkdir -p artifacts
  TARGET_PATH="artifacts/${OUTPUT_NAME}"

  echo "📦 Moving AppImage to $TARGET_PATH"
  mv "$GENERATED_APPIMAGE" "$TARGET_PATH"
  chmod +x "$TARGET_PATH"

  echo "✅ AppImage created: $TARGET_PATH"

  echo "🔍 Verifying contents..."
  cp "$TARGET_PATH" unpack-test.AppImage
  chmod +x unpack-test.AppImage
  ./unpack-test.AppImage --appimage-extract

  echo "📂 Extracted contents:"
  tree squashfs-root/
}

# --------------------------------------
# MAIN EXECUTION
# --------------------------------------

install_dependencies
build_flutter_linux
prepare_appdir
download_and_extract_pactus_cli
download_linuxdeploy
build_appimage
