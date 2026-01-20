import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ProfileController());
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: RefreshIndicator(
        onRefresh: c.pullToRefresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(c: c)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: const [
                    SizedBox(height: 20),
                    _ImpactDashboard(),
                    SizedBox(height: 20),
                    _WeeklyActivityCard(),
                    SizedBox(height: 20),
                    _AchievementSection(),
                    SizedBox(height: 20),
                    _SettingsSection(),
                    SizedBox(height: 20),
                    _AccountSection(),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ProfileController c;
  const _Header({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3CFF), Color(0xFF8600FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Obx(
              () => c.isLoadingProfile.value
                  ? const CircularProgressIndicator(color: Color(0xFF1E3CFF))
                  : Text(
                      c.userName.value
                          .split(' ')
                          .map((e) => e[0])
                          .take(2)
                          .join(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  c.isLoadingProfile.value
                      ? Container(
                          width: 120,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        )
                      : Text(
                          c.userName.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  const SizedBox(height: 4),
                  c.isLoadingProfile.value
                      ? Container(
                          width: 150,
                          height: 13,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        )
                      : Text(
                          c.userEmail.value,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      c.isLoadingProfile.value
                          ? Container(
                              width: 100,
                              height: 13,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            )
                          : Text(
                              c.role.value == 'admin'
                                  ? 'Administrator'
                                  : 'Community Member',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                      const SizedBox(width: 4),
                      c.isLoadingProfile.value
                          ? const SizedBox.shrink()
                          : Icon(
                              c.role.value == 'admin'
                                  ? Icons.admin_panel_settings
                                  : Icons.people,
                              color: Colors.amber,
                              size: 16,
                            ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _Tag(label: c.levelLabel.value, color: Colors.amber),
                      _Tag(
                        label: '${c.accuracy.value}% Accuracy',
                        color: Colors.white,
                        textColor: Colors.black87,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactDashboard extends StatelessWidget {
  const _ImpactDashboard();
  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProfileController>();
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.show_chart, size: 18, color: Color(0xFF6A00FF)),
              SizedBox(width: 6),
              Text(
                'Your Impact Dashboard',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'AI-powered community contributions',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          // Responsive grid to avoid vertical overflow on small devices.
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int crossAxisCount;
              if (width >= 900) {
                crossAxisCount = 4;
              } else if (width >= 600) {
                crossAxisCount = 3;
              } else {
                crossAxisCount = 2;
              }
              double aspect;
              if (width < 340) {
                aspect = 1.15;
              } else if (width < 380) {
                aspect = 1.25;
              } else if (width < 430) {
                aspect = 1.35;
              } else if (width < 600) {
                aspect = 1.45;
              } else {
                aspect = 1.55;
              }
              // Obx only around the part that actually reads reactive values.
              return Obx(() {
                if (c.isLoadingStats.value) {
                  return GridView.builder(
                    itemCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: aspect,
                    ),
                    itemBuilder: (context, i) => _LoadingStatTile(),
                  );
                }

                final tiles = [
                  _StatTile(
                    icon: Icons.bar_chart,
                    color: Colors.indigo,
                    value: c.reportsSubmitted.value.toString(),
                    label: 'Reports Submitted',
                    delta: '+${c.reportsDelta.value} this week',
                  ),
                  _StatTile(
                    icon: Icons.brightness_high,
                    color: Colors.amber.shade700,
                    value: c.communityImpact.value.toString(),
                    label: 'Community Impact',
                    delta: '+${c.impactDelta.value} this week',
                  ),
                  _StatTile(
                    icon: Icons.terrain,
                    color: Colors.green.shade600,
                    value: c.roadsImproved.value.toString(),
                    label: 'Roads Improved',
                    delta: '+${c.roadsDelta.value} this week',
                  ),
                  _StatTile(
                    icon: Icons.track_changes,
                    color: Colors.purple,
                    value: '${c.aiAccuracy.value}%',
                    label: 'AI Accuracy',
                    delta: '+${c.accuracyDelta.value}% this week',
                  ),
                ];
                return GridView.builder(
                  itemCount: tiles.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: aspect,
                  ),
                  itemBuilder: (context, i) => tiles[i],
                );
              });
            },
          ),
        ],
      ),
    );
  }
}

class _WeeklyActivityCard extends StatelessWidget {
  const _WeeklyActivityCard();
  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProfileController>();
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Detection Activity',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your AI scanning patterns',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (c.isLoadingStats.value) {
              return Container(
                height: 170,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
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
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final data = c.weeklyDetections;
            final maxVal =
                (data.isEmpty ? 0 : data.reduce((a, b) => a > b ? a : b))
                    .toDouble();
            final safeMax = maxVal == 0 ? 1 : maxVal;
            return GestureDetector(
              onLongPress: c.randomizeWeekly,
              child: Container(
                height: 170,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
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
                child: _WeeklyLineChart(
                  values: data.toList(),
                  maxValue: safeMax.toDouble(),
                  labels: c.weekDays,
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF2FF),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Obx(
                  () => Text(
                    'Total: ${c.weeklyDetections.reduce((a, b) => a + b)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3CFF),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: c.randomizeWeekly,
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Simulate', style: TextStyle(fontSize: 12)),
              ),
              const Spacer(),
              const Text(
                'Long press chart to randomize',
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyLineChart extends StatelessWidget {
  final List<int> values;
  final double maxValue;
  final List<String> labels;
  const _WeeklyLineChart({
    required this.values,
    required this.maxValue,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final stepX = w / (values.length - 1);
        final points = <Offset>[];
        for (var i = 0; i < values.length; i++) {
          final v = values[i];
          final y = h - (v / maxValue) * (h - 26) - 18; // padding top/bottom
          points.add(Offset(stepX * i, y));
        }
        return CustomPaint(
          painter: _WeeklyChartPainter(
            points: points,
            values: values,
            maxValue: maxValue,
            labels: labels,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _WeeklyChartPainter extends CustomPainter {
  final List<Offset> points;
  final List<int> values;
  final double maxValue;
  final List<String> labels;
  _WeeklyChartPainter({
    required this.points,
    required this.values,
    required this.maxValue,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = const Color(0xFFDFE5F2)
      ..strokeWidth = 1;
    // Horizontal guide lines (4)
    for (int i = 0; i <= 4; i++) {
      final y = 8 + (size.height - 40) * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), axisPaint);
    }

    if (points.isEmpty) return;

    final gradientPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      gradientPath.lineTo(points[i].dx, points[i].dy);
    }
    gradientPath.lineTo(points.last.dx, size.height - 20);
    gradientPath.lineTo(points.first.dx, size.height - 20);
    gradientPath.close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1E3CFF), Color(0xFF8600FF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill
      ..colorFilter = const ColorFilter.mode(
        Colors.white24,
        BlendMode.srcOver,
      )
      ..isAntiAlias = true
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawPath(gradientPath, fillPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF1E3CFF)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = const Color(0xFF1E3CFF);
    final highlightPaint = Paint()..color = const Color(0xFFFFFFFF);
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      canvas.drawCircle(p, 5, dotPaint);
      canvas.drawCircle(p, 2, highlightPaint);

      // value label above
      final valueLabel = values[i].toString();
      textPainter.text = TextSpan(
        text: valueLabel,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E3CFF),
        ),
      );
      textPainter.layout(minWidth: 0, maxWidth: 50);
      textPainter.paint(
        canvas,
        Offset(p.dx - textPainter.width / 2, p.dy - 18),
      );

      // day label at bottom
      final day = labels[i];
      final dayPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      dayPainter.text = TextSpan(
        text: day,
        style: const TextStyle(fontSize: 10, color: Colors.black54),
      );
      dayPainter.layout(minWidth: 0, maxWidth: 40);
      dayPainter.paint(
        canvas,
        Offset(p.dx - dayPainter.width / 2, size.height - 20),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _AchievementSection extends StatelessWidget {
  const _AchievementSection();
  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProfileController>();
    return _Card(
      color: const Color(0xFFFFFBF2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.emoji_events_outlined, size: 18, color: Colors.amber),
              SizedBox(width: 6),
              Text(
                'Achievement System',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'AI detection milestones and community goals',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (c.isLoadingStats.value) {
              return Column(
                children: List.generate(
                  3,
                  (index) => Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 120,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 200,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Column(
              children:
                  c.achievements.map((a) => _AchievementTile(a: a)).toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();
  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProfileController>();
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.settings, size: 18),
              SizedBox(width: 6),
              Text('Settings', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Adjust preferences',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 14),
          Obx(() {
            if (c.isLoadingSettings.value) {
              return Column(
                children: List.generate(
                  3,
                  (index) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 120,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: 180,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: [
                Obx(
                  () => _SettingToggle(
                    label: 'Push Notifications',
                    subtitle: 'Get alerts about nearby potholes',
                    value: c.pushNotifications.value,
                    onChanged: c.togglePush,
                    icon: Icons.notifications_active_outlined,
                  ),
                ),
                Obx(
                  () => _SettingToggle(
                    label: 'Dark Mode',
                    subtitle: 'Switch to dark theme',
                    value: c.darkMode.value,
                    onChanged: c.toggleDark,
                    icon: Icons.dark_mode_outlined,
                  ),
                ),
                Obx(
                  () => _SettingToggle(
                    label: 'Auto Report',
                    subtitle: 'Automatically submit high-severity detections',
                    value: c.autoReport.value,
                    onChanged: c.toggleAutoReport,
                    icon: Icons.shield_outlined,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection();
  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProfileController>();
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.account_circle, size: 18),
              SizedBox(width: 6),
              Text('Account', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage your account',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 14),
          Obx(() {
            if (c.isLoadingAccount.value) {
              return Column(
                children: List.generate(
                  3,
                  (index) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 100,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: 150,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: [
                _AccountAction(
                  label: 'Edit Profile',
                  subtitle: 'Update your profile information',
                  icon: Icons.person_outline_rounded,
                  onTap: () => c.editProfile(),
                ),
                _AccountAction(
                  label: 'Help & Support',
                  subtitle: 'Get help and contact support',
                  icon: Icons.help_outline_rounded,
                  onTap: () => c.openHelp(),
                ),
                const Divider(height: 1),
                _AccountAction(
                  label: 'Sign Out',
                  subtitle: 'Log out of your account',
                  icon: Icons.logout_rounded,
                  onTap: () => c.signOut(),
                  isDestructive: true,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _AccountAction extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const _AccountAction({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive ? Colors.red : Colors.black87,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? Colors.red : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final Color? color;
  const _Card({required this.child, this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  const _Tag({required this.label, required this.color, this.textColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor ?? Colors.black87,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String delta;
  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.delta,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [Icon(icon, color: color, size: 22)]),
          FittedBox(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
              height: 1.15,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              delta,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3CFF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingStatTile extends StatelessWidget {
  const _LoadingStatTile();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          Container(
            width: 40,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Container(
            width: 60,
            height: 11,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 50,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement a;
  const _AchievementTile({required this.a});
  @override
  Widget build(BuildContext context) {
    final unlocked = a.unlocked;
    final progress = a.progress;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: unlocked ? Colors.amber.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: unlocked ? Colors.amber : Colors.grey.shade300,
            child: Text(a.badge, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  a.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
                if (!unlocked) ...[
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E3CFF), Color(0xFF8600FF)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          unlocked
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E0),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Unlocked',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB57600),
                    ),
                  ),
                )
              : Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ],
      ),
    );
  }
}

class _SettingToggle extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;
  const _SettingToggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF1E3CFF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
