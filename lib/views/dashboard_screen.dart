import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinicbackend/services/supabase_service.dart';

/// Filter mode enum for the dashboard
enum DateFilterMode { day, week, month, year, custom }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  bool _isChartLoading = false;

  // Stats
  int _filteredAppointments = 0;
  double _filteredRevenue = 0;
  int _activeDoctors = 0;

  // Chart data
  List<Map<String, dynamic>> _chartData = [];
  bool _showRevenue = false; // false = appointments, true = revenue

  // Date filter
  DateFilterMode _filterMode = DateFilterMode.week;
  DateTime _selectedDate = DateTime.now(); // for day/month/year
  DateTimeRange? _customRange; // for custom range

  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _setupRealtime();
  }

  void _setupRealtime() {
    _realtimeChannel = SupabaseService.instance.client
        .channel('public:dashboard_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'appointments',
          callback: (payload) => _loadDashboardData(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'payments',
          callback: (payload) => _loadDashboardData(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'users',
          callback: (payload) => _loadDashboardData(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  // ─── Date Range Helpers ─────────────────────────────────────────

  /// Calculate start & end dates based on the current filter mode
  (String, String) _getDateRange() {
    final now = DateTime.now();
    switch (_filterMode) {
      case DateFilterMode.day:
        final d = _selectedDate.toIso8601String().split('T')[0];
        return (d, d);
      case DateFilterMode.week:
        final start = _selectedDate.subtract(const Duration(days: 6));
        return (
          start.toIso8601String().split('T')[0],
          _selectedDate.toIso8601String().split('T')[0],
        );
      case DateFilterMode.month:
        final start = DateTime(_selectedDate.year, _selectedDate.month, 1);
        final end = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
        return (
          start.toIso8601String().split('T')[0],
          end.toIso8601String().split('T')[0],
        );
      case DateFilterMode.year:
        final start = DateTime(_selectedDate.year, 1, 1);
        final end = DateTime(_selectedDate.year, 12, 31);
        return (
          start.toIso8601String().split('T')[0],
          end.toIso8601String().split('T')[0],
        );
      case DateFilterMode.custom:
        if (_customRange != null) {
          return (
            _customRange!.start.toIso8601String().split('T')[0],
            _customRange!.end.toIso8601String().split('T')[0],
          );
        }
        // Fallback to last 7 days
        final start = now.subtract(const Duration(days: 6));
        return (
          start.toIso8601String().split('T')[0],
          now.toIso8601String().split('T')[0],
        );
    }
  }

  String _getFilterLabel() {
    final df = DateFormat('dd/MM/yyyy');
    switch (_filterMode) {
      case DateFilterMode.day:
        return df.format(_selectedDate);
      case DateFilterMode.week:
        final start = _selectedDate.subtract(const Duration(days: 6));
        return '${df.format(start)} – ${df.format(_selectedDate)}';
      case DateFilterMode.month:
        return DateFormat('MM/yyyy').format(_selectedDate);
      case DateFilterMode.year:
        return '${_selectedDate.year}';
      case DateFilterMode.custom:
        if (_customRange != null) {
          return '${df.format(_customRange!.start)} – ${df.format(_customRange!.end)}';
        }
        return 'Chọn khoảng thời gian';
    }
  }

  // ─── Data Loading ───────────────────────────────────────────────

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final service = SupabaseService.instance;
      final (startDate, endDate) = _getDateRange();

      final results = await Future.wait([
        service.getAppointmentsCountByRange(startDate, endDate),
        service.getRevenueByRange(startDate, endDate),
        service.getActiveDoctorsCount(),
        _showRevenue
            ? service.getRevenueByRangeGrouped(startDate, endDate)
            : service.getAppointmentsByRange(startDate, endDate),
      ]);

      if (mounted) {
        setState(() {
          _filteredAppointments = results[0] as int;
          _filteredRevenue = results[1] as double;
          _activeDoctors = results[2] as int;
          _chartData = results[3] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Lỗi tải dữ liệu: $e');
      }
    }
  }

  Future<void> _loadChartData() async {
    setState(() => _isChartLoading = true);
    try {
      final service = SupabaseService.instance;
      final (startDate, endDate) = _getDateRange();
      final data = _showRevenue
          ? await service.getRevenueByRangeGrouped(startDate, endDate)
          : await service.getAppointmentsByRange(startDate, endDate);
      if (mounted) {
        setState(() {
          _chartData = data;
          _isChartLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChartLoading = false);
        _showError('Lỗi tải biểu đồ: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── Filter Picker Actions ─────────────────────────────────────

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) {
      setState(() {
        _filterMode = DateFilterMode.day;
        _selectedDate = picked;
      });
      _loadDashboardData();
    }
  }

  Future<void> _pickMonth() async {
    // Show a date picker and use only year/month
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedDate.year, _selectedDate.month, 1),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) {
      setState(() {
        _filterMode = DateFilterMode.month;
        _selectedDate = DateTime(picked.year, picked.month, 1);
      });
      _loadDashboardData();
    }
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) {
      setState(() {
        _filterMode = DateFilterMode.custom;
        _customRange = picked;
      });
      _loadDashboardData();
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
            // ─── Header + Refresh ───────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chào, Quản trị viên 👋',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tổng quan hoạt động phòng khám',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _loadDashboardData,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Làm mới'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ─── Date Filter Bar ────────────────────────────────
            _buildFilterBar(colorScheme),
            const SizedBox(height: 24),

            // ─── Stats Cards ────────────────────────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 700;
                if (isNarrow) {
                  return Column(
                    children: [
                      _buildStatCard(
                        icon: Icons.calendar_month_rounded,
                        label: 'Ca khám thành công',
                        value: '$_filteredAppointments',
                        color: const Color(0xFF0D9488),
                        bgColor: const Color(0xFFCCFBF1),
                      ),
                      const SizedBox(height: 16),
                      _buildStatCard(
                        icon: Icons.payments_rounded,
                        label: 'Doanh thu',
                        value: _formatCurrency(_filteredRevenue),
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
                        label: 'Ca khám thành công',
                        value: '$_filteredAppointments',
                        color: const Color(0xFF0D9488),
                        bgColor: const Color(0xFFCCFBF1),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.payments_rounded,
                        label: 'Doanh thu',
                        value: _formatCurrency(_filteredRevenue),
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

  // ─── Filter Bar ────────────────────────────────────────────────

  Widget _buildFilterBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.filter_list_rounded,
                      size: 20, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Bộ lọc thời gian',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getFilterLabel(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip(
                    label: 'Hôm nay',
                    icon: Icons.today_rounded,
                    isSelected: _filterMode == DateFilterMode.day &&
                        _isSameDay(_selectedDate, DateTime.now()),
                    onTap: () {
                      setState(() {
                        _filterMode = DateFilterMode.day;
                        _selectedDate = DateTime.now();
                      });
                      _loadDashboardData();
                    },
                    colorScheme: colorScheme,
                  ),
                  _buildFilterChip(
                    label: '7 ngày',
                    icon: Icons.date_range_rounded,
                    isSelected: _filterMode == DateFilterMode.week,
                    onTap: () {
                      setState(() {
                        _filterMode = DateFilterMode.week;
                        _selectedDate = DateTime.now();
                      });
                      _loadDashboardData();
                    },
                    colorScheme: colorScheme,
                  ),
                  _buildFilterChip(
                    label: 'Tháng này',
                    icon: Icons.calendar_month_rounded,
                    isSelected: _filterMode == DateFilterMode.month &&
                        _selectedDate.month == DateTime.now().month &&
                        _selectedDate.year == DateTime.now().year,
                    onTap: () {
                      setState(() {
                        _filterMode = DateFilterMode.month;
                        _selectedDate = DateTime.now();
                      });
                      _loadDashboardData();
                    },
                    colorScheme: colorScheme,
                  ),
                  _buildFilterChip(
                    label: 'Năm nay',
                    icon: Icons.calendar_today_rounded,
                    isSelected: _filterMode == DateFilterMode.year &&
                        _selectedDate.year == DateTime.now().year,
                    onTap: () {
                      setState(() {
                        _filterMode = DateFilterMode.year;
                        _selectedDate = DateTime.now();
                      });
                      _loadDashboardData();
                    },
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(width: 4),
                  // Divider dot
                  if (!isNarrow)
                    Container(
                      width: 1,
                      height: 28,
                      color: colorScheme.outlineVariant,
                    ),
                  if (!isNarrow) const SizedBox(width: 4),
                  _buildFilterChip(
                    label: 'Chọn ngày',
                    icon: Icons.edit_calendar_rounded,
                    isSelected: _filterMode == DateFilterMode.day &&
                        !_isSameDay(_selectedDate, DateTime.now()),
                    onTap: _pickDay,
                    colorScheme: colorScheme,
                  ),
                  _buildFilterChip(
                    label: 'Chọn tháng',
                    icon: Icons.event_note_rounded,
                    isSelected: _filterMode == DateFilterMode.month &&
                        !(_selectedDate.month == DateTime.now().month &&
                            _selectedDate.year == DateTime.now().year),
                    onTap: _pickMonth,
                    colorScheme: colorScheme,
                  ),
                  _buildFilterChip(
                    label: 'Tùy chỉnh',
                    icon: Icons.tune_rounded,
                    isSelected: _filterMode == DateFilterMode.custom,
                    onTap: _pickCustomRange,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.5),
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
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
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _showRevenue ? 'Biểu đồ Doanh thu' : 'Biểu đồ Ca khám',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getFilterLabel(),
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
            child: _isChartLoading
                ? Center(
                    child:
                        CircularProgressIndicator(color: colorScheme.primary),
                  )
                : _chartData.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bar_chart_rounded,
                                size: 48,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            Text(
                              'Chưa có dữ liệu trong khoảng thời gian này',
                              style: TextStyle(
                                  color: colorScheme.onSurfaceVariant),
                            ),
                          ],
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
          ? (entry['totalamount'] as num).toDouble()
          : (entry['count'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), value));

      final dateStr = entry['date'] as String;
      final date = DateTime.parse(dateStr);
      bottomLabels.add(
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
      );
    }

    final maxY = spots.isEmpty
        ? 10.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final ceilMaxY = maxY <= 0 ? 10.0 : (maxY * 1.3);

    // Determine label interval: show max ~10 labels on X axis
    final labelInterval =
        _chartData.length > 10 ? (_chartData.length / 10).ceil() : 1;

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
                // Show every Nth label to avoid overlapping
                if (idx % labelInterval != 0 &&
                    idx != bottomLabels.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    bottomLabels[idx],
                    style: TextStyle(
                      fontSize: 11,
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
              show: _chartData.length <= 31,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 4,
                color: colorScheme.surface,
                strokeWidth: 2.5,
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
            getTooltipColor: (_) => colorScheme.inverseSurface,
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
