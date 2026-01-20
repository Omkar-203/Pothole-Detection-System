import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pathole_app/api/api_manager.dart';
import 'session_details_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

enum ReportStatus { pending, progress, fixed }

enum RiskLevel { high, medium, low }

class ReportItem {
  final String id;
  final String title;
  final DateTime createdAt;
  final double depthCm;
  final double costUsd;
  final ReportStatus status;
  final RiskLevel risk;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String? streetName;

  ReportItem({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.depthCm,
    required this.costUsd,
    required this.status,
    required this.risk,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.streetName,
  });

  factory ReportItem.fromJson(Map<String, dynamic> json) {
    ReportStatus status;
    // Map backend status to enum
    switch (json['status']) {
      case 'pending':
        status = ReportStatus.pending;
        break;
      case 'in_progress':
        status = ReportStatus.progress;
        break;
      case 'fixed':
        status = ReportStatus.fixed;
        break;
      default:
        status = ReportStatus.pending;
    }

    RiskLevel risk;
    // Map severity to risk level
    switch (json['severity']) {
      case 'Major':
        risk = RiskLevel.high;
        break;
      case 'Medium':
        risk = RiskLevel.medium;
        break;
      case 'Minor':
        risk = RiskLevel.low;
        break;
      default:
        risk = RiskLevel.medium;
    }

    // Calculate estimated cost based on severity and depth
    double costUsd = 0.0;
    double depth = json['depth']?.toDouble() ?? 0.0;
    switch (json['severity']) {
      case 'Major':
        costUsd = depth * 50.0; // Higher cost for major potholes
        break;
      case 'Medium':
        costUsd = depth * 30.0;
        break;
      case 'Minor':
        costUsd = depth * 15.0;
        break;
    }

    // Create a more descriptive title
    String title = 'Pothole on ${json['street_name'] ?? 'Unknown Street'}';
    if (json['street_name'] == null) {
      title = 'Pothole Report #${json['id']}';
    }

    return ReportItem(
      id: json['id'].toString(),
      title: title,
      createdAt: DateTime.parse(json['created_at']), // Keep as UTC from backend
      depthCm: json['depth']?.toDouble() ?? 0.0,
      costUsd: costUsd,
      status: status,
      risk: risk,
      imageUrl: json['image_path'] != null
          ? '${ApiManager.instance.baseUrl}/${json['image_path']}'
          : null,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      streetName: json['street_name'],
    );
  }
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportStatus? _filter; // null means All
  List<ReportItem> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final apiManager = ApiManager.instance;
      final reportsData = await apiManager.getReports();

      setState(() {
        _items = reportsData.map((json) => ReportItem.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _items = []; // Empty list on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == null
        ? _items
        : _items.where((e) => e.status == _filter).toList();
    final totals = _summaryCounts();

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F7FA),
        appBar: AppBar(
          title: const Text('Reports'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F7FA),
        appBar: AppBar(
          title: const Text('Reports'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load reports',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(fontSize: 12, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadReports,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _summaryCard(totals),
          const SizedBox(height: 18),
          _filterTabs(),
          const SizedBox(height: 14),
          for (final r in filtered) ...[
            _reportCard(r),
            const SizedBox(height: 14),
          ],
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                'No reports for this filter',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Map<String, dynamic> _summaryCounts() {
    final total = _items.length;
    final pending =
        _items.where((e) => e.status == ReportStatus.pending).length;
    final progress =
        _items.where((e) => e.status == ReportStatus.progress).length;
    final fixed = _items.where((e) => e.status == ReportStatus.fixed).length;

    // Calculate some additional stats
    final highRisk = _items.where((e) => e.risk == RiskLevel.high).length;
    final avgDepth = total > 0
        ? _items.fold<double>(0, (sum, item) => sum + item.depthCm) / total
        : 0;

    return {
      'total': total,
      'pending': pending,
      'progress': progress,
      'fixed': fixed,
      'highRisk': highRisk,
      'avgDepth': avgDepth,
    };
  }

  Widget _summaryCard(Map<String, dynamic> counts) {
    TextStyle numStyle(Color c) =>
        TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Pothole Reports',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Total detections: ${counts['total']}  •  High risk: ${counts['highRisk']}',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryStat(
                numStyle(const Color(0xFF1F2D3D)),
                counts['total'],
                'Total',
              ),
              _summaryStat(
                numStyle(Colors.orange.shade700),
                counts['pending'],
                'Pending',
              ),
              _summaryStat(
                numStyle(const Color(0xFF1565C0)),
                counts['progress'],
                'Progress',
              ),
              _summaryStat(
                numStyle(Colors.green.shade600),
                counts['fixed'],
                'Fixed',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      '${counts['avgDepth'].toStringAsFixed(1)} cm',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const Text(
                      'Avg Depth',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(TextStyle style, dynamic value, String label) {
    String displayValue;
    if (value is int) {
      displayValue = value.toString();
    } else if (value is double) {
      displayValue = value.toStringAsFixed(value < 10 ? 1 : 0);
    } else {
      displayValue = value.toString();
    }

    return Column(
      children: [
        Text(displayValue, style: style),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _filterTabs() {
    final entries = <(String, ReportStatus?)>[
      ('All', null),
      ('Pending', ReportStatus.pending),
      ('Progress', ReportStatus.progress),
      ('Fixed', ReportStatus.fixed),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(children: [for (final e in entries) _filterChip(e.$1, e.$2)]),
    );
  }

  Widget _filterChip(String label, ReportStatus? status) {
    final isActive = _filter == status;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.black : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _reportCard(ReportItem r) {
    return GestureDetector(
      onTap: () {
        // Create a single pothole at the reported location
        final potholes = [
          SessionPothole(
            position: LatLng(r.latitude ?? 18.5204, r.longitude ?? 73.8567),
            severity: (r.depthCm / 10).clamp(0.1, 1.0),
            timestamp: r.createdAt,
            depthCm: r.depthCm,
            widthCm: 35 + (r.depthCm * 2),
          ),
        ];

        // Create a simple route around the pothole location
        final baseLat = r.latitude ?? 18.5204;
        final baseLng = r.longitude ?? 73.8567;
        final shift = 0.001; // Small shift for route points
        final route = [
          LatLng(baseLat - shift, baseLng - shift),
          LatLng(baseLat, baseLng), // Pothole location
          LatLng(baseLat + shift, baseLng + shift),
        ];

        final args = SessionDetailsArgs(
          sessionId: r.id,
          startedAt: r.createdAt,
          duration:
              const Duration(minutes: 5), // Shorter duration for single reports
          distanceKm: 0.1, // Short distance for single reports
          potholes: potholes,
          routePoints: route,
        );
        Get.to(() => const SessionDetailsScreen(), arguments: args);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _thumb(r),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          r.title,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _riskBadge(r.risk),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.black45,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          r.streetName ?? 'Unknown Location',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.black45,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _timeAgo(r.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Depth: ${r.depthCm.toStringAsFixed(1)} cm',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getSeverityColor(r.risk),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getSeverityText(r.risk),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _statusPill(r.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumb(ReportItem r) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(color: Colors.grey.shade300),
        child: r.imageUrl == null
            ? const Icon(Icons.terrain, color: Colors.brown, size: 30)
            : Image.network(
                r.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.terrain,
                      color: Colors.brown, size: 30);
                },
              ),
      ),
    );
  }

  Widget _riskBadge(RiskLevel risk) {
    late Color bg;
    late Color fg;
    late String text;
    switch (risk) {
      case RiskLevel.high:
        bg = const Color(0xFFFFE5E6);
        fg = const Color(0xFFD93025);
        text = 'High Risk';
        break;
      case RiskLevel.medium:
        bg = const Color(0xFFFFF0DB);
        fg = const Color(0xFFEE8500);
        text = 'Medium Risk';
        break;
      case RiskLevel.low:
        bg = const Color(0xFFE6F9EC);
        fg = const Color(0xFF0F8E44);
        text = 'Low Risk';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _statusPill(ReportStatus status) {
    late Color bg;
    late Color fg;
    late IconData icon;
    late String text;
    switch (status) {
      case ReportStatus.pending:
        bg = const Color(0xFFFFF2E0);
        fg = const Color(0xFFDB8600);
        icon = Icons.timer;
        text = 'Pending';
        break;
      case ReportStatus.progress:
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1671C4);
        icon = Icons.info_outline;
        text = 'In Progress';
        break;
      case ReportStatus.fixed:
        bg = const Color(0xFFE3F8EC);
        fg = const Color(0xFF138F4E);
        icon = Icons.check_circle_outline;
        text = 'Fixed';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime d) {
    // d is UTC from backend, convert to IST
    final dIst = d.add(const Duration(hours: 5, minutes: 30));
    // Current time in IST
    final nowUtc = DateTime.now().toUtc();
    final nowIst = nowUtc.add(const Duration(hours: 5, minutes: 30));
    final diff = nowIst.difference(dIst);
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return '1 day ago';
    return '${diff.inDays} days ago';
  }

  Color _getSeverityColor(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.high:
        return Colors.red.shade600;
      case RiskLevel.medium:
        return Colors.orange.shade600;
      case RiskLevel.low:
        return Colors.green.shade600;
    }
  }

  String _getSeverityText(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.high:
        return 'High';
      case RiskLevel.medium:
        return 'Medium';
      case RiskLevel.low:
        return 'Low';
    }
  }
}
