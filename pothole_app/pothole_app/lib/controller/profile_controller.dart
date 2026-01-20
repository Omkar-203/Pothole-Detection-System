import 'package:get/get.dart';
import '../api/api_manager.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_snackbar.dart';

class Achievement {
  final String title;
  final String description;
  final bool unlocked;
  final double progress; // 0-1 for locked ones
  final String badge; // simple emoji / icon text
  Achievement({
    required this.title,
    required this.description,
    this.unlocked = false,
    this.progress = 0,
    this.badge = '🎖️',
  });
}

class ProfileController extends GetxController {
  final userName = 'Loading...'.obs;
  final userEmail = ''.obs;
  final role = 'user'.obs;
  final levelLabel = 'Level 1'.obs;
  final accuracy = 85.obs; // percent

  // Dashboard stats
  final reportsSubmitted = 0.obs;
  final communityImpact = 0.obs;
  final roadsImproved = 0.obs;
  final aiAccuracy = 85.obs;

  // Weekly deltas
  final reportsDelta = 0.obs;
  final impactDelta = 0.obs;
  final roadsDelta = 0.obs;
  final accuracyDelta = 0.obs;

  // Achievements
  final achievements = <Achievement>[].obs;

  // Settings toggles
  final pushNotifications = true.obs;
  final darkMode = false.obs;
  final autoReport = true.obs;

  // Loading states
  final isLoadingProfile = true.obs;
  final isLoadingStats = true.obs;
  final isLoadingSettings = true.obs;
  final isLoadingAccount = false.obs;

  // Weekly detection counts (Mon -> Sun)
  final weeklyDetections = <int>[0, 0, 0, 0, 0, 0, 0].obs;
  final weekDays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void onInit() {
    super.onInit();
    loadAllData();
  }

  @override
  void onReady() {
    super.onReady();
    // Refresh data when screen becomes visible
    ever(isLoadingProfile, (_) => update());
    ever(isLoadingStats, (_) => update());
  }

  Future<void> loadAllData() async {
    await Future.wait([
      loadUserProfile(),
      loadUserStats(),
      loadUserSettings(),
    ]);
  }

  Future<void> refreshData() async {
    await loadAllData();
  }

  Future<void> loadUserProfile() async {
    try {
      isLoadingProfile.value = true;
      final profile = await ApiManager.instance.getProfile();
      userName.value =
          profile['email'].split('@')[0]; // Use email prefix as name
      userEmail.value = profile['email'];
      role.value = profile['role'];

      // Set level based on role
      if (role.value == 'admin') {
        levelLabel.value = 'Admin';
      } else {
        levelLabel.value = 'Community Member';
      }
    } catch (e) {
      userName.value = 'User';
      userEmail.value = 'user@example.com';
      role.value = 'user';
      levelLabel.value = 'Community Member';
    } finally {
      isLoadingProfile.value = false;
    }
  }

  Future<void> loadUserStats() async {
    try {
      isLoadingStats.value = true;
      final myPotholes = await ApiManager.instance.getMyPotholes();
      reportsSubmitted.value = myPotholes.length;

      // Calculate community impact (assume each report helps 3 people)
      communityImpact.value = reportsSubmitted.value * 3;

      // Calculate roads improved (assume 1 road per 5 reports)
      roadsImproved.value = (reportsSubmitted.value / 5).round();

      // Generate weekly data based on total reports
      generateWeeklyData();

      // Update achievements based on stats
      updateAchievements();

      // Calculate deltas (simulate weekly growth)
      calculateDeltas();
    } catch (e) {
      // Keep default values
    } finally {
      isLoadingStats.value = false;
    }
  }

  Future<void> loadUserSettings() async {
    try {
      isLoadingSettings.value = true;
      final prefs = await SharedPreferences.getInstance();

      // Load settings from local storage
      pushNotifications.value = prefs.getBool('push_notifications') ?? true;
      darkMode.value = prefs.getBool('dark_mode') ?? false;
      autoReport.value = prefs.getBool('auto_report') ?? true;
    } catch (e) {
      // Keep default values
    } finally {
      isLoadingSettings.value = false;
    }
  }

  Future<void> saveUserSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('push_notifications', pushNotifications.value);
      await prefs.setBool('dark_mode', darkMode.value);
      await prefs.setBool('auto_report', autoReport.value);
    } catch (e) {
      // Settings not saved, but continue
    }
  }

  void generateWeeklyData() {
    final totalReports = reportsSubmitted.value;
    if (totalReports == 0) {
      weeklyDetections.assignAll([0, 0, 0, 0, 0, 0, 0]);
      return;
    }

    final rnd = Random();
    int remaining = totalReports;

    for (var i = 0; i < weeklyDetections.length; i++) {
      if (i == weeklyDetections.length - 1) {
        // Last day gets remaining
        weeklyDetections[i] = remaining;
      } else {
        // Distribute randomly with more weight on recent days
        final weight = (i + 1) / weeklyDetections.length; // 0.14 to 1.0
        final maxForDay = (remaining * 0.4 * weight).round();
        final dayReports = maxForDay > 0 ? rnd.nextInt(maxForDay + 1) : 0;
        weeklyDetections[i] = dayReports;
        remaining -= dayReports;
      }
    }
    weeklyDetections.refresh();
  }

  void calculateDeltas() {
    // Calculate weekly deltas based on current stats
    final rnd = Random();
    reportsDelta.value = rnd.nextInt(15) + 5; // 5-20
    impactDelta.value = reportsDelta.value * 3;
    roadsDelta.value = (reportsDelta.value / 5).round();
    accuracyDelta.value = rnd.nextInt(5) + 1; // 1-5
  }

  void updateAchievements() {
    achievements.clear();

    final reportCount = reportsSubmitted.value;

    achievements.addAll([
      Achievement(
        title: 'First Report',
        description: 'Submitted your first pothole report',
        unlocked: reportCount >= 1,
        badge: '🎯',
      ),
      Achievement(
        title: 'Community Helper',
        description: 'Reported 5+ potholes',
        unlocked: reportCount >= 5,
        badge: '🤝',
      ),
      Achievement(
        title: 'Road Guardian',
        description: 'Reported 10+ potholes',
        unlocked: reportCount >= 10,
        badge: '🛡️',
      ),
      Achievement(
        title: 'Safety Champion',
        description: 'Reported 25+ potholes',
        unlocked: reportCount >= 25,
        badge: '🏆',
      ),
      Achievement(
        title: 'Legend',
        description: 'Reported 50+ potholes',
        unlocked: reportCount >= 50,
        badge: '👑',
      ),
    ]);
  }

  void randomizeWeekly() {
    final rnd = Random();
    for (var i = 0; i < weeklyDetections.length; i++) {
      // keep values in sensible range 5 - 30 with mild variance
      final base = weeklyDetections[i];
      var next = base + rnd.nextInt(11) - 5; // +/-5
      if (next < 0) next = 0;
      if (next > 32) next = 28 + rnd.nextInt(4);
      weeklyDetections[i] = next;
    }
    weeklyDetections.refresh();
    // adjust headline dashboard stats slightly (simulate growth)
    reportsSubmitted.value = weeklyDetections.reduce((a, b) => a + b);
    loadUserStats(); // Recalculate stats
  }

  void togglePush(bool v) async {
    pushNotifications.value = v;
    await saveUserSettings();
  }

  void toggleDark(bool v) async {
    darkMode.value = v;
    await saveUserSettings();
  }

  void toggleAutoReport(bool v) async {
    autoReport.value = v;
    await saveUserSettings();
  }

  // Method to refresh all data
  Future<void> pullToRefresh() async {
    await refreshData();
  }

  // Account action methods
  void editProfile() {
    // TODO: Navigate to edit profile screen
    CustomSnackbar.info(
      title: 'Coming Soon',
      message: 'Profile editing feature will be available soon.',
    );
  }

  void openHelp() {
    // TODO: Navigate to help screen or open URL
    CustomSnackbar.info(
      title: 'Help & Support',
      message: 'Contact support at support@potholedetection.com',
    );
  }

  void changePassword() {
    // TODO: Navigate to change password screen
    CustomSnackbar.info(
      title: 'Change Password',
      message: 'Password change feature will be available soon.',
    );
  }

  void openPrivacy() {
    // TODO: Navigate to privacy policy screen or open URL
    CustomSnackbar.info(
      title: 'Privacy Policy',
      message: 'Privacy policy will be available soon.',
    );
  }

  Future<void> signOut() async {
    try {
      isLoadingAccount.value = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      ApiManager.instance.setToken(''); // Clear token
      CustomSnackbar.success(
        title: 'Signed Out',
        message: 'You have been successfully signed out.',
      );
      Get.offAllNamed('/login');
    } catch (e) {
      CustomSnackbar.error(
        title: 'Sign Out Failed',
        message: 'Failed to sign out. Please try again.',
      );
    } finally {
      isLoadingAccount.value = false;
    }
  }
}
