import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/currency_config.dart';
import '../models/transaction.dart';
import '../controllers/category_controller.dart';
import '../utils/currency_utils.dart';
import 'voice_command_controller.dart';
import 'voice_service.dart';

class VoiceCommandScreen extends StatelessWidget {
  final VoiceCommandController _controller = Get.find<VoiceCommandController>();
  final CategoryController _categoryController = Get.find<CategoryController>();

  VoiceCommandScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Command'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _controller.stopListening();
            Get.back();
          },
        ),
      ),
      body: Obx(() {
        // Determine if we should show the mic button
        final bool showMicButton = _controller.isListening.value ||
            (_controller.recognizedText.isEmpty &&
                !_controller.showConfirmation.value);

        // Check if we have an unrecognized command
        final bool hasUnrecognizedCommand =
            _controller.recognizedText.isNotEmpty &&
                !_controller.showConfirmation.value &&
                !_controller.isListening.value;

        return SafeArea(
          child: Column(
            children: [
              // Main content with potential scrolling
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Voice instruction card
                      _buildInstructionCard(context),

                      // Recognized text display
                      _buildRecognizedTextDisplay(context),

                      // Status message
                      if (_controller.statusMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _controller.statusMessage.value,
                            style: TextStyle(
                              color: _controller.parsedCommand.value?.isValid ==
                                      true
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      // Retry button when command is not recognized
                      if (hasUnrecognizedCommand)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton.icon(
                            onPressed: () => _controller.retryVoiceCommand(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again With Voice'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              foregroundColor: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                          ),
                        ),

                      // Confirmation card when a valid command is detected
                      if (_controller.showConfirmation.value &&
                          _controller.parsedCommand.value != null &&
                          _controller.parsedCommand.value!.isValid)
                        _buildConfirmationCard(context),

                      // Add padding at the bottom when confirmation is shown
                      if (_controller.showConfirmation.value)
                        const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom microphone control area - only shown when needed
              if (showMicButton && !hasUnrecognizedCommand)
                Container(
                  padding: const EdgeInsets.only(bottom: 20, top: 8),
                  child: _buildMicrophoneButton(context),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInstructionCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voice Command Examples:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• "Add expense of 7,500 XAF for lunch today"',
              style: TextStyle(fontSize: 14),
            ),
            const Text(
              '• "Record 1,000,000 XAF income from salary"',
              style: TextStyle(fontSize: 14),
            ),
            const Text(
              '• "Expense of 5,000 XAF description: internet bill"',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Use "description:" or "for" to add details',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecognizedTextDisplay(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: _controller.isListening.value
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
            : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _controller.isListening.value
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _controller.isListening.value ? 'Listening...' : 'Your command:',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _controller.recognizedText.value.isEmpty
                ? _controller.isListening.value
                    ? 'Say your command now...'
                    : 'Tap the microphone to speak'
                : _controller.recognizedText.value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationCard(BuildContext context) {
    final result = _controller.parsedCommand.value!;
    final category = _categoryController.categories
        .firstWhere((c) => c.id == result.categoryId);

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.type == TransactionType.expense
                  ? 'Expense Details'
                  : 'Income Details',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildConfirmationRow(
              'Amount:',
              CurrencyConfig.formatAmount(result.amount!),
              color: result.type == TransactionType.expense
                  ? Colors.red
                  : Colors.green,
              bold: true,
            ),
            _buildConfirmationRow(
              'Category:',
              category.name,
              icon: Icon(category.icon, color: category.color, size: 20),
            ),
            if (result.description != null && result.description!.isNotEmpty)
              _buildConfirmationRow('Description:', result.description!),
            _buildConfirmationRow(
              'Date:',
              _formatDate(result.date!),
              icon: const Icon(Icons.calendar_today, size: 20),
            ),
            _buildConfirmationRow(
              'Payment Method:',
              result.paymentMethod!.name.capitalize!,
              icon: const Icon(Icons.payment, size: 20),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _controller.cancelTransaction();
                      _controller.startListening(); // Restart listening
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _controller.confirmTransaction(),
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationRow(String label, String value,
      {Color? color, bool bold = false, Icon? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          if (icon != null) ...[
            icon,
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: color,
                fontSize: bold ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicrophoneButton(BuildContext context) {
    final voiceService = Get.find<VoiceService>();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sound level indicator (only shown when listening)
          if (_controller.isListening.value)
            Obx(() {
              final level = voiceService.soundLevel.value;
              // Calculate radius based on sound level (min 40, max 100)
              final radius = 40.0 + (level * 60.0).clamp(0.0, 60.0);

              return Container(
                width: 120,
                height: 20,
                margin: const EdgeInsets.only(bottom: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: level,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _controller.isListening.value
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary),
                  ),
                ),
              );
            }),

          GestureDetector(
            onTap: () {
              if (_controller.isListening.value) {
                _controller.stopListening();
              } else {
                _controller.startListening();
              }
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _controller.isListening.value
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: _controller.isListening.value
                        ? Colors.red.withOpacity(0.3)
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _controller.isListening.value ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 32,
                  ),
                  if (_controller.isListening.value)
                    const Text(
                      "STOP",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _controller.isListening.value
                ? "Tap STOP when finished speaking"
                : "Tap to start speaking",
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_controller.recognizedText.value.isEmpty &&
              !_controller.isListening.value)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextButton.icon(
                onPressed: () => _controller.startListening(),
                icon: const Icon(Icons.refresh),
                label: const Text("Try Again"),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
