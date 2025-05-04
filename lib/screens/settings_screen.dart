import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/theme_config.dart';
import '../routes/app_routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: Get.isDarkMode,
              onChanged: (value) {
                ThemeConfig.toggleTheme();
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text('Budget alerts and reminders'),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                Get.snackbar('Coming Soon',
                    'Notification settings will be available soon');
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup & Sync'),
            subtitle: const Text('Backup your data to the cloud'),
            onTap: () {
              Get.snackbar(
                  'Coming Soon', 'Backup and sync will be available soon');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            onTap: () {
              Get.toNamed(AppRoutes.helpSupport);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Mi Expense v1.0.0'),
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          const Divider(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                _showResetConfirmation(context);
              },
              icon: const Icon(Icons.delete),
              label: const Text('Reset All Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Mi Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mi Expense is a simple, intuitive expense tracking app to help you manage your finances better.',
            ),
            const SizedBox(height: 16),
            const Text('Version: 1.0.0'),
            const SizedBox(height: 8),
            const Text('Created by: Mi Expense Team'),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.code,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Built with Flutter and GetX',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
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

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Data'),
        content: const Text(
          'This will permanently delete all your transactions, categories, and budgets. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement data reset functionality
              Navigator.of(context).pop();
              Get.snackbar(
                'Coming Soon',
                'Data reset functionality will be available soon',
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('RESET'),
          ),
        ],
      ),
    );
  }
}
