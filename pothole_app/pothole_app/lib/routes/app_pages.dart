import 'package:get/get.dart';
import '../controller/home_binding.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/root_nav_screen.dart';
import '../screens/scan_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/session_details_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/splash_screen.dart';
import 'routes.dart';

class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: Routes.splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: Routes.register,
      page: () => const RegisterScreen(),
    ),
    GetPage(
      name: Routes.root,
      page: () => const RootNavScreen(),
      bindings: [HomeBinding()],
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
    GetPage(name: Routes.scan, page: () => const ScanScreen()),
    GetPage(name: Routes.reports, page: () => const ReportsScreen()),
    GetPage(name: Routes.profile, page: () => const ProfileScreen()),
    GetPage(
      name: Routes.sessionDetails,
      page: () => const SessionDetailsScreen(),
    ),
  ];
}
