#!/bin/bash
# Vercel build script for Flutter web app
set -e

echo "=== Installing Flutter SDK ==="
FLUTTER_VERSION="3.41.1"
curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" | tar xJ -C "$HOME"
export PATH="$PATH:$HOME/flutter/bin"

# Fix git ownership check (Vercel runs as root)
git config --global --add safe.directory '*'
export FLUTTER_ROOT="$HOME/flutter"

echo "=== Flutter version ==="
flutter config --no-analytics 2>/dev/null || true
flutter --version

echo "=== Building Flutter web (release) ==="
flutter build web --release --no-tree-shake-icons

echo "=== Build complete ==="
ls -la build/web/
