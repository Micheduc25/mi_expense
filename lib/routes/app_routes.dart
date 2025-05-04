import 'package:get/get.dart';
import '../screens/home_screen.dart';
import '../screens/add_transaction_screen.dart';
import '../screens/transaction_detail_screen.dart';
import '../screens/category_screen.dart';
import '../screens/budget_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/edit_transaction_screen.dart';
import '../screens/help_support_screen.dart';
import '../voice/voice_command_screen.dart';
import '../voice/voice_bindings.dart';
import '../widgets/app_icon.dart';
import '../widgets/icon_generator.dart';

class AppRoutes {
  static const String HOME = '/';
  static const String ADD_TRANSACTION = '/add-transaction';
  static const String TRANSACTION_DETAIL = '/transaction-detail';
  static const String EDIT_TRANSACTION = '/edit-transaction';
  static const String CATEGORIES = '/categories';
  static const String BUDGET = '/budget';
  static const String ANALYTICS = '/analytics';
  static const String SETTINGS = '/settings';
  static const String HELP_SUPPORT = '/help-support';
  static const String VOICE_COMMAND = '/voice-command';
  static const String APP_ICON_PREVIEW = '/app-icon-preview';
  static const String ICON_GENERATOR = '/icon-generator';

  // For backwards compatibility
  static const String home = HOME;
  static const String addTransaction = ADD_TRANSACTION;
  static const String transactionDetail = TRANSACTION_DETAIL;
  static const String categories = CATEGORIES;
  static const String budget = BUDGET;
  static const String analytics = ANALYTICS;
  static const String settings = SETTINGS;
  static const String helpSupport = HELP_SUPPORT;
  static const String voiceCommand = VOICE_COMMAND;
  static const String appIconPreview = APP_ICON_PREVIEW;
  static const String iconGenerator = ICON_GENERATOR;

  static List<GetPage> routes = [
    GetPage(name: HOME, page: () => const HomeScreen()),
    GetPage(name: ADD_TRANSACTION, page: () => const AddTransactionScreen()),
    GetPage(
        name: TRANSACTION_DETAIL, page: () => const TransactionDetailScreen()),
    GetPage(name: EDIT_TRANSACTION, page: () => const EditTransactionScreen()),
    GetPage(name: CATEGORIES, page: () => const CategoryScreen()),
    GetPage(name: BUDGET, page: () => const BudgetScreen()),
    GetPage(name: ANALYTICS, page: () => const AnalyticsScreen()),
    GetPage(name: SETTINGS, page: () => const SettingsScreen()),
    GetPage(name: HELP_SUPPORT, page: () => const HelpSupportScreen()),
    GetPage(
      name: VOICE_COMMAND,
      page: () => VoiceCommandScreen(),
      binding: VoiceBindings(),
    ),
    GetPage(name: APP_ICON_PREVIEW, page: () => const AppIconPreview()),
    GetPage(name: ICON_GENERATOR, page: () => const IconGenerator()),
  ];
}
