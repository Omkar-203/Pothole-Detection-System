import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class SessionPothole {
  final LatLng position;
  final double severity;
  final DateTime timestamp;
  final double depthCm;
  final double widthCm;
  SessionPothole({
    required this.position,
    required this.severity,
    required this.timestamp,
    required this.depthCm,
    required this.widthCm,
  });
}

class SessionDetailsArgs {
  final String sessionId;
  final DateTime startedAt;
  final Duration duration;
  final double distanceKm;
  final List<SessionPothole> potholes;

  /// Ordered GPS points representing the driven route for this session.
  final List<LatLng> routePoints;
  SessionDetailsArgs({
    required this.sessionId,
    required this.startedAt,
    required this.duration,
    required this.distanceKm,
    required this.potholes,
    required this.routePoints,
  });
}

class SessionDetailsScreen extends StatefulWidget {
  const SessionDetailsScreen({super.key});
  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  GoogleMapController? _mapController;
  bool _mapReady = false;
  bool _hasLocationPermission = false;
  bool _mapTimedOut = false;
  SessionDetailsArgs get args => Get.arguments as SessionDetailsArgs;

  Set<Marker> get _markers => args.potholes
      .asMap()
      .entries
      .map(
        (e) => Marker(
          markerId: MarkerId('p_${e.key}'),
          position: e.value.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            (e.value.severity * 120).clamp(0, 120).toDouble(),
          ),
          infoWindow: InfoWindow(
            title: 'Pothole',
            snippet:
                'Depth: ${e.value.depthCm.toStringAsFixed(1)}cm  Width: ${e.value.widthCm.toStringAsFixed(1)}cm',
          ),
        ),
      )
      .toSet();

  Set<Polyline> get _polylines {
    if (args.routePoints.length < 2) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: args.routePoints,
        color: const Color(0xFF1976D2),
        width: 5,
        geodesic: true,
      ),
    };
  }

  // === Severity Enhanced Polylines ===
  Set<Polyline> get _severityPolylines {
    final pts = args.routePoints;
    if (pts.length < 2) return {};
    if (args.potholes.isEmpty) return _polylines;
    final segs = <Polyline>{};
    for (int i = 0; i < pts.length - 1; i++) {
      final a = pts[i];
      final b = pts[i + 1];
      final mid = LatLng(
        (a.latitude + b.latitude) / 2,
        (a.longitude + b.longitude) / 2,
      );
      double? best;
      double sev = 0;
      for (final p in args.potholes) {
        final d = _distanceSq(mid, p.position);
        if (best == null || d < best) {
          best = d;
          sev = p.severity;
        }
      }
      segs.add(
        Polyline(
          polylineId: PolylineId('seg_$i'),
          points: [a, b],
          width: 6,
          geodesic: true,
          color: _severityColor(sev),
        ),
      );
    }
    return segs;
  }

  Color _severityColor(double s) {
    if (s >= 0.7) return const Color(0xFFE53935);
    if (s >= 0.4) return const Color(0xFFFFA000);
    return const Color(0xFF43A047);
  }

  double _distanceSq(LatLng a, LatLng b) {
    final dx = a.latitude - b.latitude;
    final dy = a.longitude - b.longitude;
    return dx * dx + dy * dy;
  }

  (double avg, double max) _severityStats() {
    if (args.potholes.isEmpty) return (0, 0);
    double sum = 0;
    double maxSev = 0;
    for (final p in args.potholes) {
      sum += p.severity;
      if (p.severity > maxSev) maxSev = p.severity;
    }
    return (sum / args.potholes.length, maxSev);
  }

  CameraPosition get _initialCamera {
    LatLng target;
    double zoom;
    if (args.potholes.isNotEmpty) {
      target = args.potholes.first.position;
      zoom = 14.5;
    } else if (args.routePoints.isNotEmpty) {
      target = args.routePoints.first;
      zoom = 13.5;
    } else {
      // Default to a neutral world view
      target = const LatLng(20.0, 0.0);
      zoom = 2.5;
    }
    return CameraPosition(target: target, zoom: zoom);
  }

  @override
  void initState() {
    super.initState();
    _initLocationPermission();
    // Fallback timeout if map creation or tiles stall
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && !_mapReady) setState(() => _mapTimedOut = true);
    });
  }

  Future<void> _initLocationPermission() async {
    final status = await Permission.location.status;
    if (status.isGranted) {
      if (mounted) setState(() => _hasLocationPermission = true);
    }
  }

  Future<void> _requestLocationPermission() async {
    final result = await Permission.location.request();
    if (result.isGranted) {
      if (mounted) setState(() => _hasLocationPermission = true);
    } else if (result.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  void _onMyLocationTap() async {
    if (!_hasLocationPermission) {
      await _requestLocationPermission();
      return;
    }
    _fitAllBounds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _fullMap()),
          if (!_mapReady)
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black87),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            ),
          // Top summary overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.38),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _circleBtn(
                        Icons.arrow_back_ios_new_rounded,
                        () => Get.back(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: _sessionSummaryChips()),
                      const SizedBox(width: 8),
                      _circleBtn(Icons.my_location, _onMyLocationTap),
                      const SizedBox(width: 8),
                      _circleBtn(Icons.center_focus_strong, _fitAllBounds),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Severity legend (kept above sheet)
          Positioned(left: 8, bottom: 130, child: _severityLegend()),
          // Bottom draggable list
          _potholeDraggableSheet(),
          if (_mapTimedOut && !_mapReady)
            Positioned(
              top: 120,
              left: 24,
              right: 24,
              child: Card(
                color: Colors.red.withOpacity(.92),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Map loading is taking longer than expected',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Check internet, Google Play Services update, API key billing & restrictions, and that the emulator image supports Google APIs.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sessionSummaryChips() {
    final sid = args.sessionId;
    final shortId = sid.length > 8 ? sid.substring(0, 8) : sid;
    final items = [
      _infoChip('Session', shortId),
      _infoChip('Started', _fmtDate(args.startedAt)),
      _infoChip('Duration', _fmtDuration(args.duration)),
      _infoChip('Distance', '${args.distanceKm.toStringAsFixed(2)} km'),
      _infoChip('Potholes', args.potholes.length.toString()),
    ];
    final (avg, max) = _severityStats();
    items.add(_infoChip('Avg Sev', '${(avg * 100).toStringAsFixed(0)}%'));
    items.add(_infoChip('Max Sev', '${(max * 100).toStringAsFixed(0)}%'));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items
            .map(
              (w) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: w,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _fullMap() {
    return GoogleMap(
      initialCameraPosition: _initialCamera,
      markers: _markers,
      polylines: _severityPolylines,
      myLocationButtonEnabled: false,
      myLocationEnabled: _hasLocationPermission,
      mapType: MapType.normal,
      onMapCreated: (c) {
        _mapController = c;
        // Delay lightly to allow tiles to start loading before hiding overlay
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _mapReady = true);
          // After map ready, auto-fit bounds if we have any data.
          if ((_markers.isNotEmpty || args.routePoints.isNotEmpty) && mounted) {
            Future.delayed(const Duration(milliseconds: 250), _fitAllBounds);
          }
        });
        debugPrint(
          '[SessionDetails] Map created markers=${_markers.length} routePts=${args.routePoints.length}',
        );
      },
    );
  }

  Widget _potholeDraggableSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.15,
      minChildSize: 0.12,
      maxChildSize: 0.55,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(width: 16),
                  const Text(
                    'Detected Potholes',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '${args.potholes.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: args.potholes.isEmpty
                    ? const Center(
                        child: Text('No potholes in this session'),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: args.potholes.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final p = args.potholes[index];
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor: Colors.red.withOpacity(.15),
                              child: Text(
                                (index + 1).toString(),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            title: Text(
                              'Depth ${p.depthCm.toStringAsFixed(1)}cm  •  Width ${p.widthCm.toStringAsFixed(1)}cm',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${p.position.latitude.toStringAsFixed(4)}, ${p.position.longitude.toStringAsFixed(4)}\n${_fmtTime(p.timestamp)}',
                              style: const TextStyle(
                                fontSize: 11,
                                height: 1.2,
                              ),
                            ),
                            trailing: _severityChip(p.severity),
                            onTap: () => _animateTo(p.position),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _severityChip(double sev) {
    Color color;
    if (sev >= 0.7) {
      color = Colors.red;
    } else if (sev >= 0.4) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        '${(sev * 100).round()}%',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.95),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.94),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.black87),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _animateTo(LatLng pos) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: pos, zoom: 16)),
    );
  }

  Widget _severityLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendItem(const Color(0xFF43A047), 'Low'),
          const SizedBox(width: 6),
          _legendItem(const Color(0xFFFFA000), 'Med'),
          const SizedBox(width: 6),
          _legendItem(const Color(0xFFE53935), 'High'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }

  void _fitAllBounds() {
    if (_mapController == null) return;
    final points = <LatLng>[];
    points.addAll(_markers.map((m) => m.position));
    points.addAll(args.routePoints);
    if (points.isEmpty) return;
    double minLat = points.first.latitude;
    double maxLat = minLat;
    double minLng = points.first.longitude;
    double maxLng = minLng;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _fmtTime(DateTime d) {
    // d is UTC from backend, convert to IST for display
    final istTime = d.add(const Duration(hours: 5, minutes: 30));
    return '${istTime.hour.toString().padLeft(2, '0')}:${istTime.minute.toString().padLeft(2, '0')}:${istTime.second.toString().padLeft(2, '0')}';
  }

  String _fmtDuration(Duration dur) {
    final h = dur.inHours;
    final m = dur.inMinutes % 60;
    final s = dur.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}
