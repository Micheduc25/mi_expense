import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService extends GetxService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final RxBool isListening = false.obs;
  final RxBool isAvailable = false.obs;
  final RxString recognizedText = ''.obs;
  final RxDouble confidence = 0.0.obs;
  final RxDouble soundLevel = 0.0.obs; // Track sound level for UI feedback
  final StreamController<String> _commandStreamController =
      StreamController<String>.broadcast();

  Stream<String> get commandStream => _commandStreamController.stream;

  @override
  void onInit() {
    super.onInit();
    _initSpeechRecognizer();
  }

  @override
  void onClose() {
    _commandStreamController.close();
    super.onClose();
  }

  Future<void> _initSpeechRecognizer() async {
    // First check and request microphone permission
    final status = await _requestMicrophonePermission();

    if (!status) {
      isAvailable.value = false;
      return;
    }

    // Initialize speech recognition if permission granted
    isAvailable.value = await _speech.initialize(
      onError: (error) {
        debugPrint('Speech recognition error: ${error.errorMsg}');
        // Handle timeout error gracefully
        if (error.errorMsg == 'error_speech_timeout') {
          debugPrint('Speech timeout detected - attempting to restart');
          // Don't add to command stream, just restart listening if we're supposed to be listening
          if (isListening.value) {
            _restartListeningWithoutReset();
          }
        }
      },
      onStatus: (status) {
        debugPrint('Speech recognition status change: $status');

        // If listening stopped unexpectedly but we're supposed to be listening, restart it
        if ((status == 'done' || status == 'notListening') &&
            isListening.value) {
          // This is the key part - if the speech service stops but our isListening flag
          // is still true (meaning the user didn't tap stop), we need to restart
          debugPrint(
              'Speech recognition stopped unexpectedly - attempting to restart');
          _restartListeningWithoutReset();
        }
      },
    );
  }

  // A new method to restart listening without resetting the recognized text
  Future<void> _restartListeningWithoutReset() async {
    // Short delay to let the previous session properly close
    await Future.delayed(const Duration(milliseconds: 300));

    // Only restart if we're still supposed to be listening
    if (isListening.value) {
      debugPrint('Restarting speech recognition while preserving text');
      // Save current recognized text
      final currentText = recognizedText.value;

      // Start a new listening session
      await _speech.listen(
        onResult: (result) {
          // Append new results to existing text
          if (result.recognizedWords.isNotEmpty) {
            if (currentText.isNotEmpty) {
              recognizedText.value = '$currentText ${result.recognizedWords}';
            } else {
              recognizedText.value = result.recognizedWords;
            }
            confidence.value = result.confidence;
          }
        },
        listenFor: const Duration(minutes: 5),
        localeId: 'en_US',
        onSoundLevelChange: (level) {
          soundLevel.value = level;
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          autoPunctuation: false,
        ),
      );
    }
  }

  // Request microphone permission
  Future<bool> _requestMicrophonePermission() async {
    var status = await Permission.microphone.status;

    if (status.isDenied) {
      // Request permission
      status = await Permission.microphone.request();
    }

    if (status.isPermanentlyDenied) {
      // The user opted to never again see the permission request dialog.
      // The only way to change the permission's status now is to use the device's settings
      _showPermissionSettingsDialog();
      return false;
    }

    return status.isGranted;
  }

  // Show a dialog prompting user to open settings when permission is permanently denied
  void _showPermissionSettingsDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Microphone Permission Required'),
        content: const Text(
            'Mi Expense needs microphone access for voice commands. Please enable it in app settings.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> startListening() async {
    recognizedText.value = '';
    soundLevel.value = 0.0;

    // First check microphone permission before starting
    final permissionGranted = await _requestMicrophonePermission();

    if (!permissionGranted) {
      Get.snackbar(
        'Permission Denied',
        'Microphone access is required for voice commands',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
      );
      return;
    }

    if (isAvailable.value) {
      isListening.value = true;

      // Set up a very long listening session - we'll manually control when to stop
      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(minutes: 5), // Very long maximum time
        localeId: 'en_US', // Set to appropriate locale

        onSoundLevelChange: (level) {
          // Update sound level for UI feedback
          soundLevel.value = level;
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true, // Get partial results as the user speaks
          listenMode:
              stt.ListenMode.dictation, // Best for natural speech with pauses
          cancelOnError: false, // Don't cancel on error to handle gracefully
          autoPunctuation:
              false, // Disable auto-punctuation which might interfere with command parsing
        ),
      );
    } else {
      await _initSpeechRecognizer();
      if (isAvailable.value) {
        startListening();
      } else {
        Get.snackbar(
          'Speech Recognition Not Available',
          'Please check microphone permissions and try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.7),
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> stopListening() async {
    if (isListening.value) {
      debugPrint('User explicitly stopped listening');

      // First update our state immediately
      isListening.value = false;

      // Then stop the speech service
      await _speech.stop();

      // Process the final command with a small delay to ensure all words are captured
      if (recognizedText.value.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 300));
        _commandStreamController.add(recognizedText.value);
      }
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    // Update even with partial results
    if (result.recognizedWords.isNotEmpty) {
      recognizedText.value = result.recognizedWords;
      confidence.value = result.confidence;
    }
  }
}
