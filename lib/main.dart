import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'routes/app_routes.dart';
import 'utils/theme_config.dart';
import 'services/database_service.dart';
import 'controllers/transaction_controller.dart';
import 'controllers/category_controller.dart';
import 'controllers/budget_controller.dart';
import 'voice/voice_bindings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await initServices();

  runApp(const MyApp());
}

Future<void> initServices() async {
  // Register services using GetX dependency injection
  Get.put(DatabaseService());

  // Register controllers
  Get.put(CategoryController());
  Get.put(TransactionController());
  Get.put(BudgetController());

  // Initialize voice services
  final voiceBindings = VoiceBindings();
  voiceBindings.dependencies();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Mi Expense',
      debugShowCheckedModeBanner: false,
      theme: ThemeConfig.lightTheme,
      darkTheme: ThemeConfig.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.home,
      getPages: AppRoutes.routes,
      defaultTransition: Transition.fade,
    );
  }
}
