#!/bin/bash

# This script converts SVG icons to PNG format for use with flutter_launcher_icons
# Requires ImageMagick to be installed (brew install imagemagick)

# Create directories if they don't exist
mkdir -p assets/icons

# Convert main app icon
echo "Converting app icon SVG to PNG..."
convert -background none -density 300 assets/icons/app_icon.svg assets/icons/app_icon.png

# Convert foreground icon (for adaptive icons)
echo "Converting foreground icon SVG to PNG..."
convert -background none -density 300 assets/icons/app_icon_foreground.svg assets/icons/app_icon_foreground.png

echo "Conversion complete! PNG files saved to assets/icons/"
echo "Now run: flutter pub run flutter_launcher_icons" 