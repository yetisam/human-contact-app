#!/bin/bash
# Vercel build script for Flutter web app
set -e

echo "=== Installing Flutter SDK ==="
FLUTTER_VERSION="3.29.3"
curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" | tar xJ -C "$HOME"
export PATH="$PATH:$HOME/flutter/bin"

echo "=== Flutter version ==="
flutter --version

echo "=== Building Flutter web (release) ==="
flutter build web --release --no-tree-shake-icons

echo "=== Build complete ==="
ls -la build/web/
