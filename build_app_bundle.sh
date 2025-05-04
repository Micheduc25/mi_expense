#!/bin/bash

# Script to build optimized App Bundle (AAB) for Play Store

echo "Building optimized App Bundle (AAB) for Play Store..."

# Clean any previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release AAB with optimizations
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/debug-info

echo "Build complete! Optimized App Bundle is available at:"
echo "build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "This App Bundle format allows Google Play to deliver optimized APKs"
echo "to each device, reducing the download size for your users."