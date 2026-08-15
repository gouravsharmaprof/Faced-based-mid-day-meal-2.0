import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';
import '../utils/api_service.dart';
import '../widgets/common_widgets.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<Map<String, dynamic>> _logs = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _searchQuery = '';
  String _filterStatus = 'all';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.getLogs();
      final logs = List<Map<String, dynamic>>.from(result['logs'] ?? []);
      if (mounted) {
        setState(() {
          _logs = logs.reversed.toList();
          _applyFilter();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load logs: $e')),
        );
      }
    }
  }

  void _applyFilter() {
    var filtered = List<Map<String, dynamic>>.from(_logs);
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((log) {
        return (log['name'] ?? '').toLowerCase().contains(q) ||
            (log['class'] ?? '').toLowerCase().contains(q) ||
            (log['roll'] ?? '').toLowerCase().contains(q);
      }).toList();
    }
    if (_filterStatus != 'all') {
      filtered = filtered
          .where((log) =>
              (log['match_status'] ?? '').toLowerCase() == _filterStatus)
          .toList();
    }
    setState(() => _filtered = filtered);
  }

  Future<void> _downloadExcel() async {
    try {
      final urlStr = await ApiService.getLogsExcelUrl();
      final uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot open download URL')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  String _formatTimestamp(String? ts) {
    if (ts == null || ts.isEmpty) return '';
    try {
      final dt = DateTime.parse(ts).toLocal();
      return DateFormat('dd MMM, hh:mm a').format(dt);
    } catch (_) {
      return ts;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildSearchBar(),
              _buildFilterChips(),
              _buildStats(),
              Expanded(child: _buildLogList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Text('Meal Logs',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const Spacer(),
          IconButton(
            onPressed: _loadLogs,
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
          ),
          IconButton(
            onPressed: _downloadExcel,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF00D4AA), Color(0xFF00B4D8)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.download_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        onChanged: (v) {
          _searchQuery = v;
          _applyFilter();
        },
        decoration: InputDecoration(
          hintText: 'Search by name, class, roll...',
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppTheme.textSecondary, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchCtrl.clear();
                    _searchQuery = '';
                    _applyFilter();
                  },
                  icon: const Icon(Icons.clear_rounded,
                      color: AppTheme.textSecondary, size: 18),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      ('all', 'All'),
      ('matched', 'Matched'),
      ('not_matched', 'Not Matched'),
      ('food_analyzed', 'Food Analyzed'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final selected = _filterStatus == f.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  _filterStatus = f.$1;
                  _applyFilter();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: selected ? AppTheme.primaryGradient : null,
                    color: selected ? null : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Text(
                    f.$2,
                    style: GoogleFonts.poppins(
                      color: selected ? Colors.white : AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStats() {
    final matched = _logs.where((l) => l['match_status'] == 'matched').length;
    final total = _logs.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          _StatChip(
            label: 'Total',
            value: total.toString(),
            color: AppTheme.primary,
          ),
          const SizedBox(width: 10),
          _StatChip(
            label: 'Verified',
            value: matched.toString(),
            color: AppTheme.success,
          ),
          const SizedBox(width: 10),
          _StatChip(
            label: 'Failed',
            value: (total - matched).toString(),
            color: AppTheme.error,
          ),
          const Spacer(),
          Text(
            '${_filtered.length} records',
            style: GoogleFonts.poppins(
                color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => const ShimmerCard(),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_rounded,
                size: 60, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text('No logs found',
                style: GoogleFonts.poppins(
                    color: AppTheme.textMuted, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: _filtered.length,
      itemBuilder: (ctx, i) => _LogCard(
        log: _filtered[i],
        formatTs: _formatTimestamp,
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(value,
              style: GoogleFonts.poppins(
                  color: color, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  final String Function(String?) formatTs;
  const _LogCard({required this.log, required this.formatTs});

  @override
  Widget build(BuildContext context) {
    final status = log['match_status'] ?? '';
    final isMatched = status == 'matched';
    final isFailed = status == 'not_matched';
    final statusColor = isMatched
        ? AppTheme.success
        : isFailed
            ? AppTheme.error
            : AppTheme.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.15),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 14),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                (log['name'] ?? 'S').isNotEmpty
                    ? (log['name'] as String)[0].toUpperCase()
                    : 'S',
                style: GoogleFonts.poppins(
                    color: statusColor, fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          title: Text(
            log['name'] ?? '',
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Class ${log['class'] ?? ''} • Roll ${log['roll'] ?? ''}',
                style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary, fontSize: 11),
              ),
              Text(
                formatTs(log['timestamp']),
                style: GoogleFonts.poppins(
                    color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
          trailing: StatusBadge(
            label: isMatched
                ? 'Matched'
                : isFailed
                    ? 'Failed'
                    : status.replaceAll('_', ' '),
            color: statusColor,
          ),
          children: [
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
            Text('Nutrition Data',
                style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _nutChip('Carbs', log['carbohydrates']),
                _nutChip('Protein', log['proteins']),
                _nutChip('Calories', log['calories']),
                _nutChip('Fat', log['fat']),
                _nutChip('Vitamins', log['vitamins']),
                _nutChip('Others', log['other_nutrients']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _nutChip(String label, String? value) {
    if (value == null || value.isEmpty || value == 'N/A') return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary, fontSize: 10),
            ),
            TextSpan(
              text: value,
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
