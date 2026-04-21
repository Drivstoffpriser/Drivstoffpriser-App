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

echo "--- Restoring firebase_options.dart from env ---"
if [ -z "$FIREBASE_OPTIONS_DART" ]; then
  echo "FIREBASE_OPTIONS_DART is not set!"
  exit 1
fi

echo "$FIREBASE_OPTIONS_DART" | base64 --decode > lib/firebase_options.dart

echo "--- Building Flutter web ---"
flutter build web \
  --release \
  --dart-define=BACKEND_URL="$BACKEND_URL"