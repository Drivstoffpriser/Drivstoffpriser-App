#!/bin/bash
set -e

echo "--- Installing Flutter (stable) ---"
if [ -d flutter-sdk/.git ]; then
  echo "flutter-sdk exists — fetching latest"
  git -C flutter-sdk fetch --depth=1 origin || true
  git -C flutter-sdk reset --hard origin/stable || true
else
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git flutter-sdk
fi

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