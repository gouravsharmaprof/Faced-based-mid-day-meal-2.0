import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../utils/api_service.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});
  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  DateTime _selectedMonth = DateTime.now();
  Map<String, dynamic>? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() { _loading = true; _error = null; });
    try {
      final month = DateFormat('yyyy-MM').format(_selectedMonth);
      final data = await ApiService.getMonthlyReport(month: month);
      setState(() { _report = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    DateTime temp = _selectedMonth;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Select Month', style: GoogleFonts.poppins(color: Colors.white)),
        content: SizedBox(
          width: 280,
          child: YearMonth(
            initial: temp,
            onChanged: (d) => temp = d,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.textMuted))),
          TextButton(
              onPressed: () { Navigator.pop(ctx); setState(() => _selectedMonth = temp); _fetchReport(); },
              child: Text('OK', style: GoogleFonts.poppins(color: AppTheme.primary))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildError()
                        : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Monthly Report',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          GestureDetector(
            onTap: _pickMonth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                DateFormat('MMM yyyy').format(_selectedMonth),
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(_error ?? 'Error', style: GoogleFonts.poppins(color: AppTheme.error)),
    ),
  );

  Widget _buildContent() {
    final report = _report!;
    final summary = report['summary'] as Map<String, dynamic>? ?? {};
    final nutrients = report['avg_nutrients_per_meal'] as Map<String, dynamic>? ?? {};
    final deficiencies = (report['top_deficiencies'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final forecast = report['next_month_forecast'] as Map<String, dynamic>? ?? {};
    final foodDemand = forecast['food_demand'] as Map<String, dynamic>? ?? {};
    final daily = (report['daily_breakdown'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Summary row
          Row(
            children: [
              _summaryCard('Total Served', '${summary['total_served'] ?? 0}',
                  Icons.people_rounded, AppTheme.primary),
              const SizedBox(width: 12),
              _summaryCard('Active Days', '${summary['active_days'] ?? 0}',
                  Icons.calendar_today_rounded, AppTheme.success),
              const SizedBox(width: 12),
              _summaryCard('Avg/Day', '${summary['avg_per_day'] ?? 0}',
                  Icons.trending_up_rounded, AppTheme.warning),
            ],
          ),
          const SizedBox(height: 20),

          // Avg nutrients
          _sectionCard(
            title: 'AVG NUTRIENTS PER MEAL',
            icon: Icons.pie_chart_rounded,
            color: AppTheme.primary,
            child: Column(
              children: [
                _nutrientBar('Carbs',    nutrients['carbohydrates']?.toDouble() ?? 0, 100, const Color(0xFF6C63FF)),
                const SizedBox(height: 10),
                _nutrientBar('Proteins', nutrients['proteins']?.toDouble()      ?? 0, 60,  const Color(0xFF00D4AA)),
                const SizedBox(height: 10),
                _nutrientBar('Fat',      nutrients['fat']?.toDouble()           ?? 0, 50,  const Color(0xFFFF8E53)),
                const SizedBox(height: 10),
                _nutrientBar('Calories', nutrients['calories']?.toDouble()      ?? 0, 800, const Color(0xFFFF6B6B)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Deficiencies
          if (deficiencies.isNotEmpty)
            _sectionCard(
              title: 'TOP SCHOOL-WIDE DEFICIENCIES',
              icon: Icons.medical_information_rounded,
              color: AppTheme.error,
              child: Wrap(
                spacing: 8, runSpacing: 8,
                children: deficiencies.map((d) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${d['nutrient']} (${d['count']} students)',
                    style: GoogleFonts.poppins(color: AppTheme.error, fontSize: 12),
                  ),
                )).toList(),
              ),
            ),
          const SizedBox(height: 16),

          // Next month forecast
          _sectionCard(
            title: 'NEXT MONTH FOOD DEMAND',
            icon: Icons.shopping_cart_rounded,
            color: AppTheme.success,
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.arrow_forward_rounded, color: AppTheme.success, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Forecast for ${forecast['month'] ?? ''}: ~${forecast['estimated_meals'] ?? 0} meals',
                      style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.5,
                  children: [
                    _demandTile('🍚 Rice',       '${foodDemand['rice_kg'] ?? 0} kg'),
                    _demandTile('🫘 Dal/Lentils','${foodDemand['dal_kg'] ?? 0} kg'),
                    _demandTile('🥦 Vegetables', '${foodDemand['vegetables_kg'] ?? 0} kg'),
                    _demandTile('🥛 Milk',       '${foodDemand['milk_liters'] ?? 0} L'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Daily breakdown
          _sectionCard(
            title: 'DAILY ATTENDANCE',
            icon: Icons.bar_chart_rounded,
            color: AppTheme.primary,
            child: Column(
              children: daily.where((d) => (d['served'] as int? ?? 0) > 0).map((d) {
                final served = d['served'] as int? ?? 0;
                final maxServed = daily.fold<int>(1, (m, e) => (e['served'] as int? ?? 0) > m ? (e['served'] as int) : m);
                final ratio = served / maxServed;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Text(d['date'].toString().substring(8),
                            style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            backgroundColor: AppTheme.surfaceLight,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                            minHeight: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 28,
                        child: Text('$served',
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 11)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            Text(label, style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required Color color, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _nutrientBar(String label, double value, double max, Color color) {
    final ratio = (value / max).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(width: 62, child: Text(label, style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppTheme.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('$value', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11)),
      ],
    );
  }

  Widget _demandTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
          Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// Simple month/year picker widget
class YearMonth extends StatefulWidget {
  final DateTime initial;
  final ValueChanged<DateTime> onChanged;
  const YearMonth({super.key, required this.initial, required this.onChanged});
  @override
  State<YearMonth> createState() => _YearMonthState();
}

class _YearMonthState extends State<YearMonth> {
  late int _year;
  late int _month;
  final _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  @override
  void initState() {
    super.initState();
    _year  = widget.initial.year;
    _month = widget.initial.month;
  }

  void _emit() => widget.onChanged(DateTime(_year, _month));

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(onPressed: () { setState(() => _year--); _emit(); },
                icon: const Icon(Icons.chevron_left, color: Colors.white)),
            Text('$_year', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            IconButton(onPressed: () { setState(() => _year++); _emit(); },
                icon: const Icon(Icons.chevron_right, color: Colors.white)),
          ],
        ),
        GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, childAspectRatio: 1.6),
          itemCount: 12,
          itemBuilder: (_, i) {
            final sel = (i + 1) == _month;
            return GestureDetector(
              onTap: () { setState(() => _month = i+1); _emit(); },
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(_months[i],
                    style: GoogleFonts.poppins(
                        color: sel ? Colors.white : AppTheme.textSecondary,
                        fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
              ),
            );
          },
        ),
      ],
    );
  }
}
