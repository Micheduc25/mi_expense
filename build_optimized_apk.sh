#!/bin/bash

# Script to build optimized APK

echo "Building optimized APK for release..."

# Clean any previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK with optimizations
flutter build apk --release \
  --target-platform android-arm,android-arm64,android-x64 \
  --split-per-abi \
  --obfuscate \
  --split-debug-info=build/debug-info

echo "Build complete! Optimized APKs are available in build/app/outputs/flutter-apk/"
echo "- app-armeabi-v7a-release.apk (for older devices)"
echo "- app-arm64-v8a-release.apk (for newer devices)"
echo "- app-x86_64-release.apk (for emulators)"