import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/reports_service.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final ReportsService _service = ReportsService();

  bool _loading = true;
  int _activeUsers = 0;
  int _totalRatings = 0;
  Map<String, dynamic> _mostViewed = {};
  List<Map<String, dynamic>> _userGrowth = [];
  Map<String, int> _categoryDist = {};
  List<Map<String, dynamic>> _topPlaces = [];

  String _selectedPeriod = 'lastQuarter';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.getActiveUsersCount(),
        _service.getTotalRatingsCount(),
        _service.getMostViewedPlace(),
        _service.getUserGrowth(),
        _service.getCategoryDistribution(),
        _service.getTopRatedPlaces(),
      ]);
      if (!mounted) return;
      setState(() {
        _activeUsers = results[0] as int;
        _totalRatings = results[1] as int;
        _mostViewed = results[2] as Map<String, dynamic>;
        _userGrowth = results[3] as List<Map<String, dynamic>>;
        _categoryDist = results[4] as Map<String, int>;
        _topPlaces = results[5] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error cargando datos: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _downloadPDF() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      setState(() => _loading = true);

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Reporte Toro Toro', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text('${l10n.activeUsers.replaceAll('\n', ' ')}: $_activeUsers'),
                pw.Text('${l10n.totalRatings.replaceAll('\n', ' ')}: $_totalRatings'),
                pw.Text('${l10n.mostViewed.replaceAll('\n', ' ')}: ${_mostViewed['name'] ?? 'N/A'}'),
                pw.SizedBox(height: 20),
                pw.Text(l10n.topPlaces, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ..._topPlaces.map((p) => pw.Text('${p['name']}: ${p['count']} ${l10n.totalRatings.toLowerCase()}')),
              ],
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'reporte_torotoro_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pdfExported)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.errorExportingPDF}: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return Scaffold(appBar: AppBar(title: Text(l10n.reports)), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2E8D5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2E8D5),
        elevation: 0,
        title: Text(l10n.reports, style: const TextStyle(color: Color(0xFF5B4636))),
        iconTheme: const IconThemeData(color: Color(0xFF5B4636)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${l10n.filter}:', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedPeriod,
                  items: [
                    DropdownMenuItem(value: 'lastQuarter', child: Text(l10n.lastQuarter)),
                    DropdownMenuItem(value: 'lastMonth', child: Text(l10n.lastMonth)),
                    DropdownMenuItem(value: 'lastWeek', child: Text(l10n.lastWeek)),
                    DropdownMenuItem(value: 'allTime', child: Text(l10n.allTime)),
                  ],
                  onChanged: (v) => setState(() => _selectedPeriod = v ?? _selectedPeriod),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _downloadPDF,
                  icon: const Icon(Icons.download, size: 18),
                  label: Text(l10n.downloadPDF),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6B7C3F),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildStatCard(l10n.activeUsers, _activeUsers.toString(), Icons.people)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(l10n.totalRatings, _totalRatings.toString(), Icons.star)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(l10n.mostViewed, (_mostViewed['name'] ?? 'N/A').toString(), Icons.location_on)),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(l10n.userGrowth),
            const SizedBox(height: 12),
            _buildUserGrowthChart(l10n),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(l10n.categoryDistribution),
                      const SizedBox(height: 12),
                      _buildCategoryPieChart(l10n),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(l10n.topPlaces),
                      const SizedBox(height: 12),
                      _buildTopPlacesList(l10n),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), // ✅ reemplazo de withOpacity
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6B7C3F), size: 28),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.3)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5B4636)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ❌ No puede ser const porque 'title' no es constante
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5B4636)),
    );
  }

  Widget _buildUserGrowthChart(AppLocalizations l10n) {
    if (_userGrowth.isEmpty) {
      return Container(height: 200, alignment: Alignment.center, child: Text(l10n.noGrowthData));
    }
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i >= 0 && i < _userGrowth.length) {
                    final m = _userGrowth[i]['month'].toString();
                    return Text(m.length >= 7 ? m.substring(5) : m);
                  }
                  return const Text('');
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _userGrowth
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), (e.value['count'] as num).toDouble()))
                  .toList(),
              isCurved: true,
              color: const Color(0xFF6B7C3F),
              barWidth: 3,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart(AppLocalizations l10n) {
    if (_categoryDist.isEmpty) {
      return Container(height: 200, alignment: Alignment.center, child: Text(l10n.noData));
    }

    final total = _categoryDist.values.fold<int>(0, (sum, v) => sum + v);
    final colors = [
      const Color(0xFF6B7C3F),
      const Color(0xFF8B9C5F),
      const Color(0xFFABBC7F),
      const Color(0xFFCBDC9F),
    ];

    final entries = _categoryDist.entries.toList();

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 140,
              child: PieChart(
                PieChartData(
                  sections: List.generate(entries.length, (index) {
                    final cat = entries[index];
                    final percentage = total > 0 ? ((cat.value / total * 100)).round() : 0;
                    return PieChartSectionData(
                      value: cat.value.toDouble(),
                      title: '$percentage%',
                      color: colors[index % colors.length],
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(entries.length, (index) {
              final cat = entries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[index % colors.length], shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Flexible(child: Text(cat.key, style: const TextStyle(fontSize: 12))),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPlacesList(AppLocalizations l10n) {
    if (_topPlaces.isEmpty) {
      return Container(height: 200, alignment: Alignment.center, child: Text(l10n.noData));
    }

    final maxCount = _topPlaces.map((p) => (p['count'] as int)).fold<int>(0, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: _topPlaces.map((place) {
          final count = (place['count'] as int);
          final percent = maxCount > 0 ? count / maxCount : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Stack(
                  children: [
                    Container(height: 8, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4))),
                    FractionallySizedBox(
                      widthFactor: percent,
                      child: Container(height: 8, decoration: BoxDecoration(color: const Color(0xFF6B7C3F), borderRadius: BorderRadius.circular(4))),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
