import 'package:get/get.dart';
import 'voice_service.dart';
import 'voice_command_controller.dart';

/// Initializes all voice-related services and controllers for the app
class VoiceBindings extends Bindings {
  @override
  void dependencies() {
    // Register voice service as a permanent service
    Get.put<VoiceService>(VoiceService(), permanent: true);

    // Register voice command controller (available only when needed)
    Get.lazyPut<VoiceCommandController>(() => VoiceCommandController());
  }
}
