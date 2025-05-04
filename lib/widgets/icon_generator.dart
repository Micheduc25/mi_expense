import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'app_icon.dart';

/// This utility class helps export the custom MI Expense app icon
/// to static PNG files that can be used for actual app icons.
class IconGenerator extends StatefulWidget {
  const IconGenerator({super.key});

  @override
  State<IconGenerator> createState() => _IconGeneratorState();
}

class _IconGeneratorState extends State<IconGenerator> {
  final GlobalKey _iconKey = GlobalKey();
  bool _generatingIcons = false;
  String _statusMessage = '';
  final List<int> _androidSizes = [48, 72, 96, 144, 192];
  final List<int> _iosSizes = [
    20,
    29,
    40,
    58,
    60,
    76,
    80,
    87,
    120,
    152,
    167,
    180,
    1024
  ];
  String _iconDirectoryPath = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Icon Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showInstructions,
            tooltip: 'How to use',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'App Icon Preview',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 40),
              // This is the icon we'll capture for export
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: RepaintBoundary(
                  key: _iconKey,
                  child: const MiExpenseAppIcon(size: 256),
                ),
              ),
              const SizedBox(height: 40),
              if (_generatingIcons)
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Generating icon files...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    // Use LayoutBuilder to adjust layout based on available width
                    LayoutBuilder(builder: (context, constraints) {
                      // If we have enough space, show buttons side by side
                      // Otherwise stack them vertically
                      final bool useHorizontalLayout =
                          constraints.maxWidth > 400;

                      return useHorizontalLayout
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: _buildButtonList(),
                            )
                          : Column(
                              children: [
                                ..._buildButtonList(),
                              ],
                            );
                    }),
                    const SizedBox(height: 16),
                    Text(
                      'This will generate app icon files for Android and iOS',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              if (_statusMessage.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _statusMessage.contains('Error')
                                ? Icons.error
                                : Icons.check_circle,
                            color: _statusMessage.contains('Error')
                                ? Colors.red
                                : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _statusMessage.contains('Error')
                                  ? 'Error'
                                  : 'Success!',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (_statusMessage.contains('generated at'))
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () => _copyPathsToClipboard(),
                              tooltip: 'Copy paths',
                            ),
                          if (_iconDirectoryPath.isNotEmpty &&
                              !_statusMessage.contains('Error'))
                            IconButton(
                              icon: const Icon(Icons.folder_open),
                              onPressed: () =>
                                  _openIconDirectory(_iconDirectoryPath),
                              tooltip: 'Copy folder path',
                            ),
                          if (_iconDirectoryPath.isNotEmpty &&
                              !_statusMessage.contains('Error'))
                            IconButton(
                              icon: const Icon(Icons.help),
                              onPressed: _showStorageAccessHelp,
                              tooltip: 'Help finding files',
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_statusMessage),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              // Make the help buttons responsive too
              LayoutBuilder(builder: (context, constraints) {
                final bool useHorizontalLayout = constraints.maxWidth > 400;

                return useHorizontalLayout
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: _buildHelpButtonList(),
                      )
                    : Column(
                        children: [
                          ..._buildHelpButtonList(),
                        ],
                      );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _captureAndSaveIcon() async {
    try {
      setState(() {
        _generatingIcons = true;
        _statusMessage = 'Generating icon files...';
      });

      // Capture the rendered widget as an image
      final RenderRepaintBoundary boundary =
          _iconKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        setState(() {
          _generatingIcons = false;
          _statusMessage = 'Failed to capture image';
        });
        return;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Try different locations until we find one that works
      String iconDirPath = '';
      Directory? iconDir;

      // First try external storage on Android (most visible)
      if (Platform.isAndroid) {
        try {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            iconDirPath = '${externalDir.path}/mi_expense_icons';
            iconDir = await Directory(iconDirPath).create(recursive: true);
          }
        } catch (e) {
          print('Failed to use external storage: $e');
        }
      }

      // If that fails, try the downloads directory
      if (iconDir == null) {
        try {
          final downloadsDir = await getDownloadsDirectory();
          if (downloadsDir != null) {
            iconDirPath = '${downloadsDir.path}/mi_expense_icons';
            iconDir = await Directory(iconDirPath).create(recursive: true);
          }
        } catch (e) {
          print('Failed to use downloads directory: $e');
        }
      }

      // If all else fails, use the documents directory (our previous method)
      if (iconDir == null) {
        final documentsDir = await getApplicationDocumentsDirectory();
        iconDirPath = '${documentsDir.path}/mi_expense_icons';
        iconDir = await Directory(iconDirPath).create(recursive: true);
      }

      // Store the path for later use
      _iconDirectoryPath = iconDirPath;

      // Create a directory for Android icons
      final androidDir =
          await Directory('$iconDirPath/android_icons').create(recursive: true);

      // Create a directory for iOS icons
      final iosDir =
          await Directory('$iconDirPath/ios_icons').create(recursive: true);

      // Create a test file to confirm we can write to this directory
      final testFile = File('$iconDirPath/test.txt');
      await testFile.writeAsString('Test file to confirm write permissions');

      bool anyFilesWritten = false;
      List<String> writtenFiles = [];

      // Save Android icons
      for (final size in _androidSizes) {
        final File file = File('${androidDir.path}/icon_${size}x$size.png');
        await file.writeAsBytes(pngBytes);

        // Verify file exists and track it
        if (await file.exists()) {
          anyFilesWritten = true;
          writtenFiles.add(file.path);
        }
      }

      // Save iOS icons
      for (final size in _iosSizes) {
        final File file = File('${iosDir.path}/icon_${size}x$size.png');
        await file.writeAsBytes(pngBytes);

        // Verify file exists and track it
        if (await file.exists()) {
          anyFilesWritten = true;
          writtenFiles.add(file.path);
        }
      }

      // Save a 1024x1024 icon for app stores
      final appStoreIcon = File('$iconDirPath/app_store_icon.png');
      await appStoreIcon.writeAsBytes(pngBytes);

      // Verify app store icon exists
      bool appStoreIconExists = await appStoreIcon.exists();
      if (appStoreIconExists) {
        anyFilesWritten = true;
        writtenFiles.add(appStoreIcon.path);
      }

      // Check if any files were actually written
      if (!anyFilesWritten) {
        setState(() {
          _generatingIcons = false;
          _statusMessage =
              'Error: Failed to write any icon files. This may be a permissions issue.';
        });
        return;
      }

      setState(() {
        _generatingIcons = false;
        _statusMessage = 'Icon files generated at:\n'
            'Storage location: $iconDirPath\n'
            'First file created: ${writtenFiles.isNotEmpty ? writtenFiles.first : "None"}\n'
            'Files written: ${writtenFiles.length}\n'
            'Android: ${androidDir.path}\n'
            'iOS: ${iosDir.path}\n'
            'App Store: ${appStoreIcon.path}\n'
            'Files verified: $anyFilesWritten';
      });

      // Show a snackbar with information
      Get.snackbar(
        'Icons Generated',
        'Icons saved to: $iconDirPath\nVerified: $anyFilesWritten\nFiles written: ${writtenFiles.length}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 7),
      );
    } catch (e) {
      setState(() {
        _generatingIcons = false;
        _statusMessage = 'Error: $e';
        _iconDirectoryPath = ''; // Clear the path on error
      });
    }
  }

  Future<void> _openIconDirectory(String path) async {
    // Simply copy the path to clipboard and inform the user
    try {
      await Clipboard.setData(ClipboardData(text: path));
      Get.snackbar(
        'Path Copied',
        'Directory path copied to clipboard. Use a file manager app to navigate to this location.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not copy directory path: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Use Icon Generator'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Click "Generate Icon Files" to create all necessary icon sizes',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 8),
              Text(
                '2. The files will be saved to your device\'s temporary directory',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 8),
              Text(
                '3. Copy the generated files to your project\'s assets/icons/ folder',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 8),
              Text(
                '4. Run flutter_launcher_icons to set up your app icons',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 8),
              Text(
                '5. See "Next Steps" for more detailed instructions',
                style: TextStyle(height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _copyPathsToClipboard() {
    Clipboard.setData(ClipboardData(text: _statusMessage));
    Get.snackbar(
      'Copied!',
      'Paths copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _showNextSteps() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Next Steps'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Finding your generated icons:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (Platform.isIOS)
                const Text(
                  'On iOS, icons are saved to the app\'s Documents folder, which can be accessed via the Files app or iTunes file sharing.',
                  style: TextStyle(height: 1.5),
                )
              else if (Platform.isAndroid)
                const Text(
                  'On Android, icons are saved to the app\'s Documents folder. You can find them using a file manager app at:\nAndroid/data/[package_name]/files/mi_expense_icons/',
                  style: TextStyle(height: 1.5),
                )
              else if (Platform.isMacOS)
                const Text(
                  'On macOS, icons are saved to the app\'s Documents folder at:\n~/Library/Containers/[app_bundle_id]/Data/Documents/mi_expense_icons/',
                  style: TextStyle(height: 1.5),
                )
              else
                const Text(
                  'Icons are saved to the app\'s Documents folder. Use the copy button in the success message to get the exact path.',
                  style: TextStyle(height: 1.5),
                ),
              const SizedBox(height: 16),
              const Text(
                'Using the generated icons:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                '1. Create an "assets/icons" folder in your project',
                style: TextStyle(height: 1.5),
              ),
              const Text(
                '2. Copy the 1024x1024 icon to "assets/icons/app_icon.png"',
                style: TextStyle(height: 1.5),
              ),
              const Text(
                '3. Create a version with transparent background and save as "app_icon_foreground.png"',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 12),
              const Text(
                '4. Run this command in your terminal:',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 4),
              const Text(
                'flutter pub run flutter_launcher_icons',
                style: TextStyle(
                  fontFamily: 'monospace',
                  backgroundColor: Color(0xFFEEEEEE),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '5. The icons will be installed in your Android and iOS projects',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'For manual installation and more detailed instructions, see lib/docs/app_icon_instructions.md',
                style: TextStyle(fontStyle: FontStyle.italic, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showStorageAccessHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finding Your Files'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The icon files have been saved to your device, but locating them depends on your platform:',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                'On Android:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '1. Use a file manager app like "Files by Google" or "Solid Explorer"\n'
                '2. Navigate to Internal Storage > Android > data > (app package ID) > files > mi_expense_icons\n'
                '3. Alternatively, look in the Downloads folder for mi_expense_icons',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                'On iOS:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '1. Open the Files app\n'
                '2. Go to On My iPhone/iPad > MI Expense > mi_expense_icons\n'
                '3. You may need to use iTunes File Sharing to access these files from a computer',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                'On macOS/Windows/Linux:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '1. The path is shown in the success message\n'
                '2. Copy the path and open it in Finder (macOS) or File Explorer (Windows)\n'
                '3. The files should be in your Downloads folder or the app\'s documents directory',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                'Troubleshooting:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '1. Check if any files were created (see success message)\n'
                '2. The app may not have proper permissions to write to storage\n'
                '3. Try searching your device for "app_store_icon.png"\n'
                '4. Check your Downloads folder',
                style: TextStyle(height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToDesktopLocation() async {
    try {
      // This would ideally use a file picker to let the user select a directory
      // For now we're going to save to a known location on desktop platforms

      setState(() {
        _generatingIcons = true;
        _statusMessage = 'Preparing to save icons to desktop location...';
      });

      // Capture the icon
      final RenderRepaintBoundary boundary =
          _iconKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        setState(() {
          _generatingIcons = false;
          _statusMessage = 'Failed to capture image';
        });
        return;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Choose a desktop-friendly location that's easy to find
      String desktopPath = '';

      if (Platform.isMacOS) {
        // On macOS, save to the Desktop
        final home = Platform.environment['HOME'];
        if (home != null) {
          desktopPath = '$home/Desktop/mi_expense_icons';
        }
      } else if (Platform.isWindows) {
        // On Windows, save to Documents
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          desktopPath = '$userProfile\\Documents\\mi_expense_icons';
        }
      } else if (Platform.isLinux) {
        // On Linux, save to the Home directory
        final home = Platform.environment['HOME'];
        if (home != null) {
          desktopPath = '$home/mi_expense_icons';
        }
      }

      if (desktopPath.isEmpty) {
        // Fall back to temporary directory if we couldn't determine platform paths
        final tempDir = await getTemporaryDirectory();
        desktopPath = '${tempDir.path}/mi_expense_icons';
      }

      // Create the directory
      final iconDir = await Directory(desktopPath).create(recursive: true);
      _iconDirectoryPath = desktopPath;

      // Create subdirectories
      final androidDir =
          await Directory('$desktopPath/android_icons').create(recursive: true);
      final iosDir =
          await Directory('$desktopPath/ios_icons').create(recursive: true);

      // Save a test file
      final testFile = File('$desktopPath/README.txt');
      await testFile.writeAsString('MI Expense App Icons\n'
          'Generated: ${DateTime.now()}\n\n'
          'Android icons are in the android_icons folder\n'
          'iOS icons are in the ios_icons folder\n'
          'app_store_icon.png is for app store submissions\n');

      bool anyFilesWritten = false;
      List<String> writtenFiles = [];

      // Save Android icons
      for (final size in _androidSizes) {
        final File file = File('${androidDir.path}/icon_${size}x$size.png');
        await file.writeAsBytes(pngBytes);

        if (await file.exists()) {
          anyFilesWritten = true;
          writtenFiles.add(file.path);
        }
      }

      // Save iOS icons
      for (final size in _iosSizes) {
        final File file = File('${iosDir.path}/icon_${size}x$size.png');
        await file.writeAsBytes(pngBytes);

        if (await file.exists()) {
          anyFilesWritten = true;
          writtenFiles.add(file.path);
        }
      }

      // Save app store icon
      final appStoreIcon = File('$desktopPath/app_store_icon.png');
      await appStoreIcon.writeAsBytes(pngBytes);

      if (await appStoreIcon.exists()) {
        anyFilesWritten = true;
        writtenFiles.add(appStoreIcon.path);
      }

      // Update the UI
      setState(() {
        _generatingIcons = false;
        _statusMessage = 'Icon files generated at:\n'
            'Desktop location: $desktopPath\n'
            'Files written: ${writtenFiles.length}\n'
            'First file: ${writtenFiles.isNotEmpty ? writtenFiles.first : "None"}\n'
            'Files verified: $anyFilesWritten';
      });

      // Show a snackbar message
      Get.snackbar(
        'Desktop Icons Generated',
        'Icons saved to: $desktopPath\nVerified: $anyFilesWritten',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 7),
      );
    } catch (e) {
      setState(() {
        _generatingIcons = false;
        _statusMessage = 'Error saving to desktop: $e';
      });
    }
  }

  // Helper method to build the button list
  List<Widget> _buildButtonList() {
    return [
      ElevatedButton.icon(
        onPressed: _captureAndSaveIcon,
        icon: const Icon(Icons.save),
        label: const Text('Generate Icons'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      const SizedBox(width: 16, height: 16), // Spacing works for both layouts
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux)
        ElevatedButton.icon(
          onPressed: _saveToDesktopLocation,
          icon: const Icon(Icons.folder_special),
          label: const Text('Save to Desktop'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
    ];
  }

  // Helper method to build the help button list
  List<Widget> _buildHelpButtonList() {
    return [
      OutlinedButton.icon(
        onPressed: _showNextSteps,
        icon: const Icon(Icons.help_outline),
        label: const Text('Next Steps'),
      ),
      const SizedBox(width: 16, height: 16),
      OutlinedButton.icon(
        onPressed: _showStorageAccessHelp,
        icon: const Icon(Icons.folder),
        label: const Text('Finding Your Files'),
      ),
    ];
  }
}
