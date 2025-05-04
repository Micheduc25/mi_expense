import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSection(
            title: 'Frequently Asked Questions',
            icon: Icons.question_answer,
            children: [
              _buildExpansionTile(
                title: 'How do I add a transaction?',
                content:
                    'Tap the + button on the home screen, then choose either "Manual" to enter transaction details yourself, or "Voice" to use voice commands.',
              ),
              _buildExpansionTile(
                title: 'How do I create a budget?',
                content:
                    'Go to the Budget section from the home screen, then tap "Create Budget" to set up a new budget with category and spending limits.',
              ),
              _buildExpansionTile(
                title: 'Can I add receipt images to my transactions?',
                content:
                    'Yes! When adding or editing a transaction, scroll down to "Receipt Image" and tap to add an image. You can either take a new photo with your camera or select an existing image from your gallery.',
              ),
              _buildExpansionTile(
                title: 'Can I export my transaction data?',
                content:
                    'This feature is coming soon. In a future update, you\'ll be able to export your data to CSV or PDF.',
              ),
              _buildExpansionTile(
                title: 'How do I categorize transactions?',
                content:
                    'When adding a transaction, select a category from the dropdown menu. You can manage your categories in the Categories section.',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Contact Us',
            icon: Icons.email,
            children: [
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email Support'),
                subtitle: const Text('support@miexpense.com'),
                onTap: () {
                  Get.snackbar(
                      'Email Support', 'Email feature will be available soon');
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_outlined),
                title: const Text('Live Chat'),
                subtitle: const Text('Available 9am-5pm, Monday-Friday'),
                onTap: () {
                  Get.snackbar(
                      'Live Chat', 'Chat feature will be available soon');
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Tutorials',
            icon: Icons.video_library,
            children: [
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: const Text('Getting Started'),
                subtitle: const Text('Learn the basics of Mi Expense'),
                onTap: () {
                  Get.snackbar('Video Tutorial',
                      'Tutorial videos will be available soon');
                },
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: const Text('Advanced Features'),
                subtitle: const Text('Master analytics and budgeting'),
                onTap: () {
                  Get.snackbar('Video Tutorial',
                      'Tutorial videos will be available soon');
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Troubleshooting',
            icon: Icons.build,
            children: [
              _buildExpansionTile(
                title: 'App is running slow',
                content:
                    'Try clearing the app cache or reinstalling the app. If the problem persists, please contact our support team.',
              ),
              _buildExpansionTile(
                title: 'Transactions not showing up',
                content:
                    'Pull down to refresh the transaction list. If transactions are still missing, restart the app or check if you have any active filters.',
              ),
            ],
          ),
          const SizedBox(height: 36),
          Center(
            child: Text(
              'Mi Expense v1.0.0',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Get.theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionTile({
    required String title,
    required String content,
  }) {
    return ExpansionTile(
      title: Text(title),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(content),
        ),
      ],
    );
  }
}
