import 'package:get/get.dart';
import 'dart:async';
import '../api/api_manager.dart';

class NearbyPothole {
  final String id;
  final String street;
  final double distanceM; // meters from current location
  final double severity; // 0..1
  final double lat;
  final double lng;
  NearbyPothole({
    required this.id,
    required this.street,
    required this.distanceM,
    required this.severity,
    required this.lat,
    required this.lng,
  });
}

class HomeController extends GetxController {
  // Observables
  final greeting = 'Good morning!'.obs;
  final aiSystemActive = true.obs;
  final highSeverityNearby = 0.obs;
  final aiDetectionsToday = 0.obs;
  final predictedRisks = 0.obs;
  final activeScanners = 0.obs;
  final weeklyDetections = <int>[0, 0, 0, 0, 0, 0, 0].obs; // Mon..Sun
  final nearbyPotholes = <NearbyPothole>[].obs;
  final userId = ''.obs; // Assume set from login

  // Loading states
  final isLoadingStats = true.obs;
  final isLoadingAnalytics = true.obs;
  final isLoadingNearby = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
    // Timer for periodic updates
    Timer.periodic(const Duration(minutes: 5), (_) => refreshDashboardData());
  }

  Future<void> loadDashboardData() async {
    await Future.wait([
      loadDashboardStats(),
      loadWeeklyAnalytics(),
      loadNearbyPotholes(),
    ]);
    updateGreeting();
  }

  Future<void> loadDashboardStats() async {
    try {
      isLoadingStats.value = true;
      final data = await ApiManager.instance.getDashboardStats();
      highSeverityNearby.value = data['high_severity_nearby'] ?? 0;
      aiDetectionsToday.value = data['ai_detections_today'] ?? 0;
      predictedRisks.value = data['predicted_risks'] ?? 0;
      activeScanners.value = data['active_scanners'] ?? 0;
    } catch (e) {
      // Keep default values on error
      print('Error loading dashboard stats: $e');
    } finally {
      isLoadingStats.value = false;
    }
  }

  Future<void> loadWeeklyAnalytics() async {
    try {
      isLoadingAnalytics.value = true;
      final data = await ApiManager.instance.getWeeklyAnalytics();
      final weeklyData = data['weekly_detections'] as List<dynamic>? ?? [];
      weeklyDetections.assignAll(weeklyData.map((e) => e as int).toList());
    } catch (e) {
      // Keep default values on error
      print('Error loading weekly analytics: $e');
    } finally {
      isLoadingAnalytics.value = false;
    }
  }

  Future<void> loadNearbyPotholes() async {
    try {
      isLoadingNearby.value = true;
      print('Loading nearby potholes...');
      final data = await ApiManager.instance.getNearbyPotholes();
      print('Nearby potholes API response: $data');
      final potholesData = data['nearby_potholes'] as List<dynamic>? ?? [];
      print('Found ${potholesData.length} nearby potholes');

      nearbyPotholes.value = potholesData
          .map((p) => NearbyPothole(
                id: p['id'].toString(),
                street: p['street'] ?? 'Unknown Street',
                distanceM: (p['distance_m'] ?? 0.0).toDouble(),
                severity: (p['severity'] ?? 0.0).toDouble(),
                lat: (p['latitude'] ?? 0.0).toDouble(),
                lng: (p['longitude'] ?? 0.0).toDouble(),
              ))
          .toList();
      print('Loaded ${nearbyPotholes.length} nearby potholes for map');
    } catch (e) {
      // Keep empty list on error
      print('Error loading nearby potholes: $e');
    } finally {
      isLoadingNearby.value = false;
    }
  }

  void updateGreeting() {
    final nowUtc = DateTime.now().toUtc();
    final istTime = nowUtc.add(const Duration(hours: 5, minutes: 30));
    final hour = istTime.hour;
    if (hour < 12) {
      greeting.value = 'Good morning!';
    } else if (hour < 17) {
      greeting.value = 'Good afternoon!';
    } else {
      greeting.value = 'Good evening!';
    }
  }

  // Simulate refresh or data fetch
  Future<void> refreshDashboard() async {
    await refreshDashboardData();
  }

  Future<void> refreshDashboardData() async {
    await Future.wait([
      loadDashboardStats(),
      loadWeeklyAnalytics(),
      loadNearbyPotholes(),
    ]);
  }
}
