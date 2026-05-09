import 'package:flutter/material.dart';

import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/documents/presentation/documents_screen.dart';
import '../../features/fuel/presentation/fuel_screen.dart';
import '../../features/maintenance/presentation/maintenance_screen.dart';
import '../../features/penalty_points/presentation/penalty_screen.dart';
import '../../features/scanner/presentation/scanner_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/vehicle/presentation/vehicle_list_screen.dart';
import '../../features/vehicle/presentation/vehicle_form_screen.dart';

class AppRouter {
  static const String dashboard = '/';
  static const String vehicles = '/vehicles';
  static const String vehicleForm = '/vehicles/form';
  static const String documents = '/documents';
  static const String scanner = '/scanner';
  static const String maintenance = '/maintenance';
  static const String fuel = '/fuel';
  static const String penalty = '/penalty';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings s) {
    switch (s.name) {
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case vehicles:
        return MaterialPageRoute(builder: (_) => const VehicleListScreen());
      case vehicleForm:
        return MaterialPageRoute(
          builder: (_) => VehicleFormScreen(vehicleId: s.arguments as String?),
        );
      case documents:
        return MaterialPageRoute(builder: (_) => const DocumentsScreen());
      case scanner:
        return MaterialPageRoute(builder: (_) => const ScannerScreen());
      case maintenance:
        return MaterialPageRoute(builder: (_) => const MaintenanceScreen());
      case fuel:
        return MaterialPageRoute(builder: (_) => const FuelScreen());
      case penalty:
        return MaterialPageRoute(builder: (_) => const PenaltyScreen());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
    }
  }
}
