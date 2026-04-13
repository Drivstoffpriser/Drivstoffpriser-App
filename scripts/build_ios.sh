#!/bin/bash
# Build iOS IPA with build number derived from git commit count.
# This ensures the build number is always increasing and matches
# the same scheme used by CI for Android builds.

set -euo pipefail

BUILD_NUMBER=$(git rev-list --count HEAD)
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | cut -d'+' -f1)

echo "Building iOS: version=$VERSION build=$BUILD_NUMBER"
flutter build ipa --build-name="$VERSION" --build-number="$BUILD_NUMBER" --dart-define=BACKEND_URL="https://api.drivstoffpriser.net" "$@"
