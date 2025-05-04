import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../controllers/transaction_controller.dart';
import '../models/transaction.dart';
import 'voice_service.dart';
import 'command_parser.dart';

class VoiceCommandController extends GetxController {
  final VoiceService _voiceService = Get.find<VoiceService>();
  final CommandParser _commandParser = CommandParser();
  final TransactionController _transactionController =
      Get.find<TransactionController>();

  final RxBool isListening = false.obs;
  final RxString recognizedText = ''.obs;
  final RxString statusMessage = ''.obs;
  final RxBool showConfirmation = false.obs;
  final Rx<VoiceCommandResult?> parsedCommand = Rx<VoiceCommandResult?>(null);

  @override
  void onInit() {
    super.onInit();

    // Listen to speech recognition status (only for UI updates, not command processing)
    _voiceService.isListening.listen((listening) {
      // Only update our local state, don't process commands automatically
      isListening.value = listening;
    });

    // Listen for real-time transcription updates
    _voiceService.recognizedText.listen((text) {
      recognizedText.value = text;
    });

    // Subscribe to the command stream to process commands
    // This is the ONLY place where commands should be processed
    _voiceService.commandStream.listen(_processCommand);
  }

  void startListening() {
    statusMessage.value = 'Listening...';
    _voiceService.startListening();
  }

  void stopListening() {
    // Immediately update our local listening state before calling service
    isListening.value = false;
    statusMessage.value = '';
    _voiceService.stopListening();
  }

  void _processCommand(String command) {
    if (command.isEmpty) {
      statusMessage.value = 'Sorry, I didn\'t catch that. Please try again.';
      showConfirmation.value = false; // Ensure no confirmation is shown
      return;
    }

    // Parse the command to extract transaction details
    final result = _commandParser.parseCommand(command);

    // Ensure date is set (default to today if needed)
    if (result.isValid && result.date == null) {
      parsedCommand.value = VoiceCommandResult(
        isValid: result.isValid,
        type: result.type,
        amount: result.amount,
        categoryId: result.categoryId,
        description: result.description,
        date: DateTime.now(), // Set today's date if missing
        paymentMethod: result.paymentMethod,
        errorMessage: result.errorMessage,
      );
    } else {
      parsedCommand.value = result;
    }

    if (parsedCommand.value!.isValid) {
      // Explicitly stop listening when a valid command is detected
      if (isListening.value) {
        stopListening();
      }
      statusMessage.value = 'Command recognized. Please confirm:';
      showConfirmation.value = true;
    } else {
      statusMessage.value =
          parsedCommand.value!.errorMessage ?? 'Could not understand command.';
      showConfirmation.value = false;
      // We keep the recognized text to show what was heard
    }
  }

  // New method to retry voice command
  void retryVoiceCommand() {
    _resetState();
    startListening();
  }

  // Called when user confirms the parsed command
  Future<void> confirmTransaction() async {
    final result = parsedCommand.value;
    if (result != null && result.isValid) {
      // Create transaction from parsed data
      final transaction = Transaction(
        amount: result.amount!,
        type: result.type!,
        date: result.date!,
        category: result.categoryId!,
        description: result.description,
        paymentMethod: result.paymentMethod!,
      );

      // Add transaction
      await _transactionController.addTransaction(transaction);

      // Reset state
      _resetState();

      Get.back(); // Close the voice input screen

      // Show success message
      Get.snackbar(
        'Success',
        'Transaction added successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.7),
        colorText: Colors.white,
      );
    }
  }

  // Called when user cancels or wants to try again
  void cancelTransaction() {
    _resetState();
  }

  void _resetState() {
    recognizedText.value = '';
    statusMessage.value = '';
    showConfirmation.value = false;
    parsedCommand.value = null;
  }
}
