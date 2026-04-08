#!/bin/bash
set -e

echo "--- Installing Flutter (stable) ---"
git clone https://github.com/flutter/flutter.git \
  --depth 1 \
  --branch stable \
  flutter-sdk

export PATH="$PWD/flutter-sdk/bin:$PATH"

flutter config --no-analytics
flutter pub get

echo "--- Building Flutter web ---"
flutter build web --release --dart-define=BACKEND_URL="$BACKEND_URL"
