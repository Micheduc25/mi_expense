#!/bin/bash

# Script to analyze app size

echo "Analyzing app size..."

# Build release APK with size analysis
flutter build apk --target-platform android-arm --analyze-size

echo "Size analysis complete!"
echo "Check the console output above for size details."
echo ""
echo "For a more detailed analysis, you can also run:"
echo "flutter build appbundle --analyze-size"