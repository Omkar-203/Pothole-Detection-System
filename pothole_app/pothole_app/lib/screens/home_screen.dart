import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controller/home_controller.dart';
import '../widgets/stat_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Obx(
          () => Text(
            controller.greeting.value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => controller.refreshDashboard(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0046FF), Color(0xFF00C07F)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.brightness_auto,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Obx(
                            () => Text(
                              controller.aiSystemActive.value
                                  ? 'AI Vision System Active'
                                  : 'AI System Offline',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Obx(
                            () => CircleAvatar(
                              radius: 4,
                              backgroundColor: controller.aiSystemActive.value
                                  ? Colors.lightGreenAccent
                                  : Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'AI Pothole Scanner',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap to start detection',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Critical alert banner (simplified)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Critical pothole detected',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'on Main St. AI confidence: 96%. Avoid area.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Stats row 1
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: controller.isLoadingStats.value
                            ? _LoadingStatCard()
                            : StatCard(
                                label: 'High Severity Nearby',
                                value: controller.highSeverityNearby.value
                                    .toString(),
                                delta: '+8%',
                                icon: Icons.warning_amber_rounded,
                                color: Colors.red,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: controller.isLoadingStats.value
                            ? _LoadingStatCard()
                            : StatCard(
                                label: 'AI Detections Today',
                                value: controller.aiDetectionsToday.value
                                    .toString(),
                                delta: '+12%',
                                icon: Icons.visibility,
                                color: Colors.blue,
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: controller.isLoadingStats.value
                            ? _LoadingStatCard()
                            : StatCard(
                                label: 'Predicted Risks',
                                value:
                                    controller.predictedRisks.value.toString(),
                                delta: '-5%',
                                icon: Icons.shield,
                                color: Colors.orange,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: controller.isLoadingStats.value
                            ? _LoadingStatCard()
                            : StatCard(
                                label: 'Active Scanners',
                                value:
                                    controller.activeScanners.value.toString(),
                                delta: '+23%',
                                icon: Icons.monitor_heart,
                                color: Colors.green,
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Detection Analytics',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  if (controller.isLoadingAnalytics.value) {
                    return Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.show_chart,
                                  size: 18, color: Color(0xFF0046FF)),
                              SizedBox(width: 6),
                              Text(
                                'Detection Analytics',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Loading analytics data...',
                            style:
                                TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 140,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(
                                7,
                                (index) => Expanded(
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      left: index == 0 ? 0 : 4,
                                      right: index == 6 ? 0 : 4,
                                    ),
                                    height: 110,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF0046FF)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return detectionAnalyticsChart();
                }),
                const SizedBox(height: 24),
                const Text(
                  'Nearby Potholes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                // // Compact nearby potholes horizontal list
                // Obx(() {
                //   if (controller.isLoadingNearby.value) {
                //     return SizedBox(
                //       height: 90,
                //       child: ListView.separated(
                //         scrollDirection: Axis.horizontal,
                //         itemCount: 3,
                //         separatorBuilder: (_, __) => const SizedBox(width: 10),
                //         itemBuilder: (context, index) {
                //           return Container(
                //             width: 140,
                //             padding: const EdgeInsets.all(10),
                //             decoration: BoxDecoration(
                //               color: Colors.white,
                //               borderRadius: BorderRadius.circular(14),
                //               boxShadow: [
                //                 BoxShadow(
                //                   color: Colors.black.withOpacity(0.05),
                //                   blurRadius: 6,
                //                   offset: const Offset(0, 3),
                //                 ),
                //               ],
                //             ),
                //             child: Column(
                //               crossAxisAlignment: CrossAxisAlignment.start,
                //               children: [
                //                 Container(
                //                   width: 80,
                //                   height: 12,
                //                   decoration: BoxDecoration(
                //                     color: Colors.grey.shade300,
                //                     borderRadius: BorderRadius.circular(6),
                //                   ),
                //                 ),
                //                 const Spacer(),
                //                 Container(
                //                   width: 50,
                //                   height: 10,
                //                   decoration: BoxDecoration(
                //                     color: Colors.grey.shade300,
                //                     borderRadius: BorderRadius.circular(5),
                //                   ),
                //                 ),
                //                 const SizedBox(height: 4),
                //                 Container(
                //                   width: 100,
                //                   height: 6,
                //                   decoration: BoxDecoration(
                //                     color: Colors.grey.shade300,
                //                     borderRadius: BorderRadius.circular(3),
                //                   ),
                //                 ),
                //               ],
                //             ),
                //           );
                //         },
                //       ),
                //     );
                //   }

                //   final list = controller.nearbyPotholes;
                //   if (list.isEmpty) {
                //     return Container(
                //       padding: const EdgeInsets.all(16),
                //       decoration: BoxDecoration(
                //         color: Colors.white,
                //         borderRadius: BorderRadius.circular(16),
                //       ),
                //       child: const Text(
                //         'No nearby potholes detected',
                //         style: TextStyle(fontSize: 12, color: Colors.black54),
                //       ),
                //     );
                //   }
                //   return SizedBox(
                //     height: 90,
                //     child: ListView.separated(
                //       scrollDirection: Axis.horizontal,
                //       itemCount: list.length,
                //       separatorBuilder: (_, __) => const SizedBox(width: 10),
                //       itemBuilder: (context, index) {
                //         final p = list[index];
                //         return nearbyPotholeCard(p);
                //       },
                //     ),
                //   );
                // }),
                const SizedBox(height: 16),
                Obx(() {
                  if (controller.isLoadingNearby.value) {
                    return Container(
                      height: 200,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF0046FF)),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Loading nearby map...',
                            style:
                                TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    );
                  }

                  final list = controller.nearbyPotholes;
                  if (list.isEmpty) {
                    return Container(
                      height: 200,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'No map data',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    );
                  }

                  // Filter out invalid coordinates
                  final validPotholes = list
                      .where((p) =>
                          p.lat >= -90 &&
                          p.lat <= 90 &&
                          p.lng >= -180 &&
                          p.lng <= 180)
                      .toList();

                  if (validPotholes.isEmpty) {
                    return Container(
                      height: 200,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Invalid location data',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    );
                  }

                  final centerLat =
                      validPotholes.map((e) => e.lat).reduce((a, b) => a + b) /
                          validPotholes.length;
                  final centerLng =
                      validPotholes.map((e) => e.lng).reduce((a, b) => a + b) /
                          validPotholes.length;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(centerLat, centerLng),
                              zoom: 13.8,
                            ),
                            zoomControlsEnabled: false,
                            myLocationEnabled: false,
                            myLocationButtonEnabled: false,
                            compassEnabled: false,
                            tiltGesturesEnabled: false,
                            rotateGesturesEnabled: false,
                            mapToolbarEnabled: false,
                            onMapCreated: (GoogleMapController controller) {
                              // Map is ready
                              print('Map created successfully');
                            },
                            markers: validPotholes
                                .map(
                                  (p) => Marker(
                                    markerId: MarkerId(p.id),
                                    position: LatLng(p.lat, p.lng),
                                    icon: BitmapDescriptor.defaultMarkerWithHue(
                                      _severityHue(p.severity),
                                    ),
                                    infoWindow: InfoWindow(
                                      title: p.street,
                                      snippet:
                                          'Severity ${(p.severity * 100).toStringAsFixed(0)}%  •  ${(p.distanceM).toStringAsFixed(0)}m',
                                    ),
                                  ),
                                )
                                .toSet(),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(.45),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Nearby Map',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

double _severityHue(double s) {
  // Map severity 0..1 to green (120) -> orange (~38) -> red (0)
  if (s >= 0.7) return BitmapDescriptor.hueRed; // 0
  if (s >= 0.4) return 30; // orange-ish
  return 120; // green
}

Widget nearbyPotholeCard(NearbyPothole p) {
  Color cardColor;
  if (p.severity >= 0.7) {
    cardColor = Colors.red;
  } else if (p.severity >= 0.4) {
    cardColor = Colors.orange;
  } else {
    cardColor = Colors.green;
  }
  return Container(
    width: 140,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
      border: Border.all(color: cardColor.withOpacity(.35), width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.radio_button_checked, size: 14, color: cardColor),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                p.street,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          '${p.distanceM.toStringAsFixed(0)} m away',
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        _severityBarInline(p.severity, cardColor),
      ],
    ),
  );
}

Widget _severityBarInline(double severity, Color color) {
  return Stack(
    children: [
      Container(
        height: 6,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      FractionallySizedBox(
        widthFactor: severity.clamp(0, 1),
        child: Container(
          height: 6,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(.15), color],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    ],
  );
}

Widget detectionAnalyticsChart() {
  final controller = Get.find<HomeController>();
  return Obx(() {
    final data = controller.weeklyDetections;
    final maxVal =
        (data.isEmpty ? 0 : data.reduce((a, b) => a > b ? a : b)).clamp(0, 32);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.show_chart, size: 18, color: Color(0xFF0046FF)),
              SizedBox(width: 6),
              Text(
                'Detection Analytics',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'AI detection patterns this week',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Y axis labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _yAxisLabel('32'),
                    _yAxisLabel('24'),
                    _yAxisLabel('16'),
                    _yAxisLabel('8'),
                    _yAxisLabel('0'),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final barWidth = (constraints.maxWidth - (6 * 10)) /
                          7; // 10px gap between bars
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (int i = 0; i < 7; i++) ...[
                            _bar(
                              value: i < data.length ? data[i].toDouble() : 0,
                              maxVal: maxVal.toDouble().clamp(1, 32),
                              width: barWidth,
                            ),
                            if (i != 6) const SizedBox(width: 10),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final d in days)
                Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  });
}

Widget _yAxisLabel(String text) {
  return Text(text, style: const TextStyle(fontSize: 9, color: Colors.black54));
}

Widget _bar({
  required double value,
  required double maxVal,
  required double width,
}) {
  final fraction = (value / maxVal).clamp(0, 1);
  final barHeight = 110 * fraction; // 110 logical px for chart area
  return Container(
    width: width,
    height: 110,
    alignment: Alignment.bottomCenter,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      width: width,
      height: barHeight.toDouble(),
      decoration: BoxDecoration(
        color: const Color(0xFF0D3F91),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            value.toInt().toString(),
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  );
}

class _LoadingStatCard extends StatelessWidget {
  const _LoadingStatCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 80,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 60,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }
}
