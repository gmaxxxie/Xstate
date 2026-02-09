#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

PRODUCT_NAME="Xstate"
APP_NAME="Xstate"
BUNDLE_ID="com.xstate.menubar"
OUTPUT_DIR="$PROJECT_DIR/dist"
INSTALL_TO_APPLICATIONS=false
FORCE_OVERWRITE=false
ICON_NAME="AppIcon"
ICON_SCRIPT="$PROJECT_DIR/scripts/generate_app_icon.swift"

usage() {
  cat <<USAGE
Usage: ./install.sh [options]

Build and package the app as a macOS .app bundle.

Options:
  --name <app_name>        App bundle display name (default: Xstate)
  --bundle-id <bundle_id>  Bundle identifier (default: com.xstate.menubar)
  --output-dir <path>      Output directory for the .app (default: ./dist)
  --install                Also copy app bundle to /Applications
  --force                  Overwrite existing app bundle if present
  -h, --help               Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      APP_NAME="${2:-}"
      shift 2
      ;;
    --bundle-id)
      BUNDLE_ID="${2:-}"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="${2:-}"
      shift 2
      ;;
    --install)
      INSTALL_TO_APPLICATIONS=true
      shift
      ;;
    --force)
      FORCE_OVERWRITE=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$APP_NAME" ]]; then
  echo "Error: --name cannot be empty" >&2
  exit 2
fi

if [[ -z "$BUNDLE_ID" ]]; then
  echo "Error: --bundle-id cannot be empty" >&2
  exit 2
fi

if ! command -v swift >/dev/null 2>&1; then
  echo "Error: swift is not installed or not in PATH" >&2
  exit 1
fi

if ! command -v iconutil >/dev/null 2>&1; then
  echo "Error: iconutil is required but not found" >&2
  exit 1
fi

if ! command -v sips >/dev/null 2>&1; then
  echo "Error: sips is required but not found" >&2
  exit 1
fi

if [[ ! -f "$ICON_SCRIPT" ]]; then
  echo "Error: icon generator script not found at $ICON_SCRIPT" >&2
  exit 1
fi

cd "$PROJECT_DIR"

echo "[1/5] Building release binary..."
swift build -c release --product "$PRODUCT_NAME"

BIN_DIR="$(swift build -c release --show-bin-path)"
BIN_PATH="$BIN_DIR/$PRODUCT_NAME"

if [[ ! -x "$BIN_PATH" ]]; then
  echo "Error: built binary not found at $BIN_PATH" >&2
  exit 1
fi

APP_BUNDLE_PATH="$OUTPUT_DIR/$APP_NAME.app"
CONTENTS_PATH="$APP_BUNDLE_PATH/Contents"
MACOS_PATH="$CONTENTS_PATH/MacOS"
RESOURCES_PATH="$CONTENTS_PATH/Resources"

if [[ -d "$APP_BUNDLE_PATH" ]]; then
  if [[ "$FORCE_OVERWRITE" == true ]]; then
    rm -rf "$APP_BUNDLE_PATH"
  else
    echo "Error: $APP_BUNDLE_PATH already exists. Use --force to overwrite." >&2
    exit 2
  fi
fi

echo "[2/5] Creating app bundle..."
mkdir -p "$MACOS_PATH" "$RESOURCES_PATH"
cp "$BIN_PATH" "$MACOS_PATH/$PRODUCT_NAME"
chmod +x "$MACOS_PATH/$PRODUCT_NAME"

echo "[3/5] Building app icon..."
ICON_WORKDIR="$(mktemp -d /tmp/xstate-iconset.XXXXXX)"
trap 'rm -rf "$ICON_WORKDIR"' EXIT
ICONSET_PATH="$ICON_WORKDIR/$ICON_NAME.iconset"
BASE_ICON="$ICON_WORKDIR/icon_1024x1024.png"
mkdir -p "$ICONSET_PATH"

swift "$ICON_SCRIPT" "$BASE_ICON"

sips -s format png -z 16 16 "$BASE_ICON" --out "$ICONSET_PATH/icon_16x16.png" >/dev/null
sips -s format png -z 32 32 "$BASE_ICON" --out "$ICONSET_PATH/icon_16x16@2x.png" >/dev/null
sips -s format png -z 32 32 "$BASE_ICON" --out "$ICONSET_PATH/icon_32x32.png" >/dev/null
sips -s format png -z 64 64 "$BASE_ICON" --out "$ICONSET_PATH/icon_32x32@2x.png" >/dev/null
sips -s format png -z 128 128 "$BASE_ICON" --out "$ICONSET_PATH/icon_128x128.png" >/dev/null
sips -s format png -z 256 256 "$BASE_ICON" --out "$ICONSET_PATH/icon_128x128@2x.png" >/dev/null
sips -s format png -z 256 256 "$BASE_ICON" --out "$ICONSET_PATH/icon_256x256.png" >/dev/null
sips -s format png -z 512 512 "$BASE_ICON" --out "$ICONSET_PATH/icon_256x256@2x.png" >/dev/null
sips -s format png -z 512 512 "$BASE_ICON" --out "$ICONSET_PATH/icon_512x512.png" >/dev/null
cp "$BASE_ICON" "$ICONSET_PATH/icon_512x512@2x.png"

iconutil -c icns "$ICONSET_PATH" -o "$RESOURCES_PATH/$ICON_NAME.icns"

echo "[4/5] Writing Info.plist..."
cat > "$CONTENTS_PATH/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$PRODUCT_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>$ICON_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

echo "[5/5] Validating bundle..."
plutil -lint "$CONTENTS_PATH/Info.plist" >/dev/null

echo "App bundle created: $APP_BUNDLE_PATH"

if [[ "$INSTALL_TO_APPLICATIONS" == true ]]; then
  TARGET="/Applications/$APP_NAME.app"
  if [[ -d "$TARGET" ]]; then
    if [[ "$FORCE_OVERWRITE" == true ]]; then
      rm -rf "$TARGET"
    else
      echo "Error: $TARGET already exists. Use --force to overwrite." >&2
      exit 2
    fi
  fi

  cp -R "$APP_BUNDLE_PATH" "$TARGET"
  echo "Installed to: $TARGET"
fi

echo "Done."
