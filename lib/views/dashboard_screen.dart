import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:clinicbackend/services/supabase_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;

  // Stats
  int _todayAppointments = 0;
  double _totalRevenue = 0;
  int _activeDoctors = 0;

  // Chart data
  List<Map<String, dynamic>> _chartData = [];
  bool _showRevenue = false; // false = appointments, true = revenue

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final service = SupabaseService.instance;
      final results = await Future.wait([
        service.getTodayAppointmentsCount(),
        service.getTotalRevenue(),
        service.getActiveDoctorsCount(),
        _showRevenue
            ? service.getRevenueLast7Days()
            : service.getAppointmentsLast7Days(),
      ]);

      if (mounted) {
        setState(() {
          _todayAppointments = results[0] as int;
          _totalRevenue = results[1] as double;
          _activeDoctors = results[2] as int;
          _chartData = results[3] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _loadChartData() async {
    try {
      final service = SupabaseService.instance;
      final data = _showRevenue
          ? await service.getRevenueLast7Days()
          : await service.getAppointmentsLast7Days();
      if (mounted) setState(() => _chartData = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải biểu đồ: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // ─── UI ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Đang tải dữ liệu...',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Welcome Header ─────────────────────────────────
            Text(
              'Xin chào, Quản trị viên 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tổng quan hoạt động phòng khám hôm nay',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 28),

            // ─── Stats Cards ────────────────────────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 700;
                if (isNarrow) {
                  return Column(
                    children: [
                      _buildStatCard(
                        icon: Icons.calendar_month_rounded,
                        label: 'Ca khám hôm nay',
                        value: '$_todayAppointments',
                        color: const Color(0xFF0D9488),
                        bgColor: const Color(0xFFCCFBF1),
                      ),
                      const SizedBox(height: 16),
                      _buildStatCard(
                        icon: Icons.payments_rounded,
                        label: 'Tổng doanh thu',
                        value: _formatCurrency(_totalRevenue),
                        color: const Color(0xFF2563EB),
                        bgColor: const Color(0xFFDBEAFE),
                      ),
                      const SizedBox(height: 16),
                      _buildStatCard(
                        icon: Icons.medical_services_rounded,
                        label: 'Bác sĩ hoạt động',
                        value: '$_activeDoctors',
                        color: const Color(0xFF7C3AED),
                        bgColor: const Color(0xFFEDE9FE),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.calendar_month_rounded,
                        label: 'Ca khám hôm nay',
                        value: '$_todayAppointments',
                        color: const Color(0xFF0D9488),
                        bgColor: const Color(0xFFCCFBF1),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.payments_rounded,
                        label: 'Tổng doanh thu',
                        value: _formatCurrency(_totalRevenue),
                        color: const Color(0xFF2563EB),
                        bgColor: const Color(0xFFDBEAFE),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.medical_services_rounded,
                        label: 'Bác sĩ hoạt động',
                        value: '$_activeDoctors',
                        color: const Color(0xFF7C3AED),
                        bgColor: const Color(0xFFEDE9FE),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // ─── Line Chart ─────────────────────────────────────
            _buildChartSection(colorScheme),
          ],
        ),
      ),
    );
  }

  // ─── Stat Card Widget ──────────────────────────────────────────

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Chart Section ─────────────────────────────────────────────

  Widget _buildChartSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _showRevenue
                        ? 'Doanh thu 7 ngày gần nhất'
                        : 'Số ca khám 7 ngày gần nhất',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Biểu đồ theo ngày',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              // Toggle button
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Ca khám'),
                    icon: Icon(Icons.event_note_rounded, size: 18),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Doanh thu'),
                    icon: Icon(Icons.attach_money_rounded, size: 18),
                  ),
                ],
                selected: {_showRevenue},
                onSelectionChanged: (set) {
                  setState(() => _showRevenue = set.first);
                  _loadChartData();
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStatePropertyAll(
                    Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Chart
          SizedBox(
            height: 300,
            child: _chartData.isEmpty
                ? Center(
                    child: Text(
                      'Chưa có dữ liệu',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : _buildLineChart(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(ColorScheme colorScheme) {
    final spots = <FlSpot>[];
    final bottomLabels = <String>[];

    for (int i = 0; i < _chartData.length; i++) {
      final entry = _chartData[i];
      final value = _showRevenue
          ? (entry['amount'] as num).toDouble()
          : (entry['count'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), value));

      // Format date label: "14/06"
      final dateStr = entry['date'] as String;
      final date = DateTime.parse(dateStr);
      bottomLabels.add('${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}');
    }

    final maxY = spots.isEmpty
        ? 10.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final ceilMaxY = maxY <= 0 ? 10.0 : (maxY * 1.3);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ceilMaxY / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= bottomLabels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    bottomLabels[idx],
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              interval: ceilMaxY / 4,
              getTitlesWidget: (value, meta) {
                return Text(
                  _showRevenue
                      ? _formatShortCurrency(value)
                      : value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (_chartData.length - 1).toDouble(),
        minY: 0,
        maxY: ceilMaxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 5,
                color: colorScheme.surface,
                strokeWidth: 3,
                strokeColor: colorScheme.primary,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.25),
                  colorScheme.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                colorScheme.inverseSurface,
            tooltipRoundedRadius: 10,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.spotIndex;
                final dateLabel =
                    idx < bottomLabels.length ? bottomLabels[idx] : '';
                final valueStr = _showRevenue
                    ? _formatCurrency(spot.y)
                    : '${spot.y.toInt()} ca';
                return LineTooltipItem(
                  '$dateLabel\n$valueStr',
                  TextStyle(
                    color: colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  // ─── Formatters ────────────────────────────────────────────────

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)} đ';
  }

  String _formatShortCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toInt().toString();
  }
}
