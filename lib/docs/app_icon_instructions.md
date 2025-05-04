# Using Custom App Icons in Mi Expense

This guide explains how to use the custom-designed Mi Expense app icon for your Android and iOS applications.

## Option 1: Using flutter_launcher_icons (Recommended)

The easiest way to set up your app icons is to use the `flutter_launcher_icons` package.

### Step 1: Add the dependency

Add this to your `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

### Step 2: Configure the icons

Create a configuration section in your `pubspec.yaml`:

```yaml
flutter_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon.png"
  adaptive_icon_background: "#FFFFFF" # For Android adaptive icons
  adaptive_icon_foreground: "assets/icons/app_icon_foreground.png"
  min_sdk_android: 21 # Android min sdk min:16, default 21
  web:
    generate: false
  windows:
    generate: false
  macos:
    generate: false
```

### Step 3: Generate the icon files

1. After using the Icon Generator from the Settings menu, save the generated 1024x1024 icon to your project's `assets/icons/` directory
2. Run this command:

```bash
flutter pub run flutter_launcher_icons
```

## Option 2: Manual Setup

If you prefer to set up the icons manually:

### For Android:

1. Navigate to `android/app/src/main/res/`
2. Replace the existing icon files in the `mipmap-*` folders with your generated icons:
   - mipmap-mdpi: 48x48
   - mipmap-hdpi: 72x72
   - mipmap-xhdpi: 96x96
   - mipmap-xxhdpi: 144x144
   - mipmap-xxxhdpi: 192x192

3. If using adaptive icons (Android 8.0+), you'll need to:
   - Update the `ic_launcher_background.xml` and `ic_launcher_foreground.xml` files
   - Or create an `ic_launcher.xml` in the `mipmap-anydpi-v26` folder

### For iOS:

1. Open your iOS project in Xcode (`ios/Runner.xcworkspace`)
2. In the Navigator, select `Runner` > `Assets.xcassets` > `AppIcon`
3. Drag and drop the appropriate size icons to each slot
4. Required sizes:
   - 20pt: 20x20, 40x40, 60x60 (1x, 2x, 3x)
   - 29pt: 29x29, 58x58, 87x87 (1x, 2x, 3x)
   - 40pt: 40x40, 80x80, 120x120 (1x, 2x, 3x)
   - 60pt: 120x120, 180x180 (2x, 3x)
   - 76pt: 76x76, 152x152 (1x, 2x) - iPad
   - 83.5pt: 167x167 (2x) - iPad Pro
   - 1024x1024 for App Store

## For App Stores:

### Google Play Store:
- Use the 512x512 icon for the app listing
- Use a 1024x500 feature graphic (can be created from your icon)

### Apple App Store:
- Use the 1024x1024 icon for the App Store listing

## Testing Your Icons

After setting up your icons:
1. Clean your project: `flutter clean`
2. Rebuild: `flutter build apk` or `flutter build ios` 
3. Test on real devices to ensure the icons appear correctly

## Troubleshooting

If icons don't appear correctly:
- For Android, check the `AndroidManifest.xml` for proper icon references
- For iOS, ensure your Xcode asset catalog is properly set up
- Try uninstalling the app before reinstalling with new icons 