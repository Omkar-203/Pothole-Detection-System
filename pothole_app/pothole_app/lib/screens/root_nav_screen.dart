import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/home_controller.dart';
import 'home_screen.dart';
import 'reports_screen.dart'; // Contains ReportsScreen
import 'profile_screen.dart';
import 'scan_screen.dart';

class RootNavController extends GetxController {
  final currentIndex = 0.obs;
  final pages = <Widget>[
    const HomeScreen(),
    const ScanScreen(),
    const ReportsScreen(),
    const ProfileScreen(),
  ];
  void changeTab(int i) => currentIndex.value = i;
}

class RootNavScreen extends StatelessWidget {
  const RootNavScreen({super.key});

  BottomNavigationBarItem _item({
    required IconData icon,
    required String label,
  }) {
    return BottomNavigationBarItem(icon: Icon(icon), label: label);
  }

  @override
  Widget build(BuildContext context) {
    // ensure HomeController exists (via binding) else create
    Get.put<HomeController>(HomeController(), permanent: true);
    final navCtrl = Get.put(RootNavController());
    return Obx(() {
      return Scaffold(
        body: navCtrl.pages[navCtrl.currentIndex.value],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: navCtrl.currentIndex.value,
            onTap: navCtrl.changeTab,
            selectedItemColor: const Color(0xFF0046FF),
            unselectedItemColor: Colors.grey[600],
            showUnselectedLabels: true,
            items: [
              _item(icon: Icons.home_rounded, label: 'Home'),
              _item(icon: Icons.photo_camera_rounded, label: 'Scan'),
              _item(icon: Icons.description_rounded, label: 'Reports'),
              _item(icon: Icons.person_rounded, label: 'Profile'),
            ],
          ),
        ),
      );
    });
  }
}
