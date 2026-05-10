import 'package:flutter/material.dart';

import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/documents/presentation/documents_screen.dart';
import '../../features/documents/presentation/personal_documents_screen.dart';
import '../../features/equipment/presentation/equipment_screen.dart';
import '../../features/fuel/presentation/fuel_screen.dart';
import '../../features/maintenance/presentation/maintenance_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/theme_picker_screen.dart';
import '../../features/penalty_points/presentation/penalty_screen.dart';
import '../../features/reminders/presentation/custom_reminders_screen.dart';
import '../../features/scanner/presentation/scanner_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/vehicle/presentation/vehicle_form_screen.dart';
import '../../features/vehicle/presentation/vehicle_list_screen.dart';

class AppRouter {
  static const String dashboard = '/';
  static const String onboarding = '/onboarding';
  static const String themePicker = '/settings/theme';
  static const String vehicles = '/vehicles';
  static const String vehicleForm = '/vehicles/form';
  static const String documents = '/documents';
  static const String personalDocuments = '/documents/personal';
  static const String scanner = '/scanner';
  static const String maintenance = '/maintenance';
  static const String fuel = '/fuel';
  static const String penalty = '/penalty';
  static const String equipment = '/equipment';
  static const String reminders = '/reminders';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings s) {
    switch (s.name) {
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case themePicker:
        return MaterialPageRoute(builder: (_) => const ThemePickerScreen());
      case vehicles:
        return MaterialPageRoute(builder: (_) => const VehicleListScreen());
      case vehicleForm:
        return MaterialPageRoute(
          builder: (_) =>
              VehicleFormScreen(vehicleId: s.arguments as String?),
        );
      case documents:
        return MaterialPageRoute(builder: (_) => const DocumentsScreen());
      case personalDocuments:
        return MaterialPageRoute(
            builder: (_) => const PersonalDocumentsScreen());
      case scanner:
        return MaterialPageRoute(builder: (_) => const ScannerScreen());
      case maintenance:
        return MaterialPageRoute(builder: (_) => const MaintenanceScreen());
      case fuel:
        return MaterialPageRoute(builder: (_) => const FuelScreen());
      case penalty:
        return MaterialPageRoute(builder: (_) => const PenaltyScreen());
      case equipment:
        return MaterialPageRoute(builder: (_) => const EquipmentScreen());
      case reminders:
        return MaterialPageRoute(
            builder: (_) => const CustomRemindersScreen());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
    }
  }
}
