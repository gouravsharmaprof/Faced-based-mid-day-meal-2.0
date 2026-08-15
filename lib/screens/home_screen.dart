import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../utils/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _serverOnline = false;
  bool _checkingServer = true;
  int _studentCount = 0;
  int _servedToday = 0;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _checkServer();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkServer() async {
    setState(() => _checkingServer = true);
    final online = await ApiService.checkHealth();
    if (mounted) {
      setState(() {
        _serverOnline = online;
        _checkingServer = false;
      });
      if (online) _fetchStats();
    }
  }

  Future<void> _fetchStats() async {
    try {
      final result = await ApiService.getLogs();
      final logs = List<Map<String, dynamic>>.from(result['logs'] ?? []);
      final today = DateTime.now();
      final todayLogs = logs.where((log) {
        try {
          final ts = DateTime.parse(log['timestamp'] ?? '');
          return ts.year == today.year &&
              ts.month == today.month &&
              ts.day == today.day &&
              log['match_status'] == 'matched';
        } catch (_) {
          return false;
        }
      }).length;
      if (mounted) {
        setState(() {
          _servedToday = todayLogs;
          _studentCount = logs.map((l) => l['user_id']).toSet().length;
        });
      }
    } catch (_) {}
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  String _weekday() {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return days[DateTime.now().weekday - 1];
  }

  String _dateStr() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${_weekday()}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildTopBar(),
                  const SizedBox(height: 28),
                  _buildGreetingCard(),
                  const SizedBox(height: 14),
                  _buildStatsRow(),
                  const SizedBox(height: 28),
                  _buildSectionTitle('Quick Actions'),
                  const SizedBox(height: 14),
                  _buildActionGrid(),
                  const SizedBox(height: 28),
                  _buildSectionTitle('How It Works'),
                  const SizedBox(height: 14),
                  _buildHowItWorksCard(),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TOP BAR ──────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Row(
      children: [
        // Logo
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.restaurant_rounded,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SMART BIOMETRIC',
                style: GoogleFonts.inter(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2)),
            Text('Meal System',
                style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const Spacer(),

        // Server status dot
        GestureDetector(
          onTap: _checkServer,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) {
                    final dotColor = _checkingServer
                        ? AppTheme.warning
                        : _serverOnline
                            ? AppTheme.success
                            : AppTheme.error;
                    return Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor.withOpacity(
                          _checkingServer
                              ? 0.5 + _pulseCtrl.value * 0.5
                              : 1.0,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                Text(
                  _checkingServer
                      ? 'Checking'
                      : _serverOnline
                          ? 'Online'
                          : 'Offline',
                  style: GoogleFonts.inter(
                    color: _checkingServer
                        ? AppTheme.warning
                        : _serverOnline
                            ? AppTheme.success
                            : AppTheme.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Settings
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/settings'),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.settings_outlined,
                color: AppTheme.textSecondary, size: 18),
          ),
        ),
      ],
    );
  }

  // ── GREETING CARD ─────────────────────────────────────────────────────────

  Widget _buildGreetingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(24),
        // Subtle inner shadow via box shadow
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.30),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting(),
                    style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('Admin',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Text(_dateStr(),
                    style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          // Decorative icon circle
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_rounded,
                color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  // ── STATS ROW ─────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Students',
            value: '$_studentCount',
            icon: Icons.people_rounded,
            iconColor: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Served Today',
            value: '$_servedToday',
            icon: Icons.check_circle_rounded,
            iconColor: AppTheme.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Server',
            value: _checkingServer ? '...' : _serverOnline ? 'Live' : 'Down',
            icon: Icons.cloud_rounded,
            iconColor: _serverOnline ? AppTheme.success : AppTheme.error,
          ),
        ),
      ],
    );
  }

  // ── SECTION TITLE ─────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4));
  }

  // ── ACTION GRID ───────────────────────────────────────────────────────────

  Widget _buildActionGrid() {
    final items = [
      _MenuItem(
        icon: Icons.person_add_rounded,
        label: 'Register',
        description: 'Add students',
        color: const Color(0xFFFF5500),
        route: '/register',
      ),
      _MenuItem(
        icon: Icons.verified_user_rounded,
        label: 'Verify & Serve',
        description: '4-step biometrics',
        color: const Color(0xFF34C759),
        route: '/recognize',
      ),
      _MenuItem(
        icon: Icons.auto_awesome_rounded,
        label: 'Food Quality',
        description: 'Automated vision',
        color: const Color(0xFFFF9500),
        route: '/food-quality',
      ),
      _MenuItem(
        icon: Icons.analytics_rounded,
        label: 'Meal Logs',
        description: 'History & exports',
        color: const Color(0xFF5E5CE6),
        route: '/logs',
      ),
      _MenuItem(
        icon: Icons.bar_chart_rounded,
        label: 'Monthly',
        description: 'Reports & stats',
        color: const Color(0xFFFF2D55),
        route: '/monthly',
      ),
      _MenuItem(
        icon: Icons.settings_rounded,
        label: 'Settings',
        description: 'Configure app',
        color: const Color(0xFF636366),
        route: '/settings',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.88,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) => _ActionCard(item: items[i]),
    );
  }

  // ── HOW IT WORKS ──────────────────────────────────────────────────────────

  Widget _buildHowItWorksCard() {
    final steps = [
      (Icons.qr_code_scanner_rounded, 'QR Scan',
          'Student presents ID code', AppTheme.primary),
      (Icons.face_retouching_natural, 'Face Verify',
          'Biometric verification', const Color(0xFF5E5CE6)),
      (Icons.restaurant_rounded, 'Food Analysis',
          'System analyzes meal', AppTheme.warning),
      (Icons.auto_graph_rounded, 'Meal Logged',
          'Nutrition saved to records', AppTheme.success),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: List.generate(steps.length, (i) {
          final s = steps[i];
          final isLast = i == steps.length - 1;
          return Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, isLast ? 18 : 0),
            child: Row(
              children: [
                // Step bubble
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: s.$4.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(s.$1, color: s.$4, size: 20),
                    ),
                    if (!isLast)
                      Container(
                        width: 1.5,
                        height: 18,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: AppTheme.border,
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: s.$4.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text('Step ${i + 1}',
                                  style: GoogleFonts.inter(
                                      color: s.$4,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 8),
                            Text(s.$2,
                                style: GoogleFonts.inter(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(s.$3,
                            style: GoogleFonts.inter(
                                color: AppTheme.textSecondary, fontSize: 11)),
                        if (!isLast) const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CARD — compact metric tile
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MENU ITEM DATA
// ─────────────────────────────────────────────────────────────────────────────
class _MenuItem {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final String route;

  _MenuItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.route,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION CARD — Hume-style square icon tile
// ─────────────────────────────────────────────────────────────────────────────
class _ActionCard extends StatefulWidget {
  final _MenuItem item;
  const _ActionCard({required this.item});

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.93,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.item.color;
    return GestureDetector(
      onTapDown: (_) => _ac.reverse(),
      onTapUp: (_) {
        _ac.forward();
        Navigator.pushNamed(context, widget.item.route);
      },
      onTapCancel: () => _ac.forward(),
      child: AnimatedBuilder(
        animation: _ac,
        builder: (_, child) =>
            Transform.scale(scale: _ac.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon bubble
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.item.icon, color: c, size: 20),
                ),
                // Label
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.item.label,
                        style: GoogleFonts.inter(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.2),
                        maxLines: 2),
                    const SizedBox(height: 2),
                    Text(widget.item.description,
                        style: GoogleFonts.inter(
                            color: AppTheme.textMuted, fontSize: 9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
