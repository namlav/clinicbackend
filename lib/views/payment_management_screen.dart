import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinicbackend/services/supabase_service.dart';

class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  State<PaymentManagementScreen> createState() => _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _payments = [];
  
  // Filters & Sorting
  String _searchQuery = '';
  String _sortBy = 'date_desc'; // date_desc, date_asc, amount_desc, amount_asc
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _loadPayments();
    _setupRealtime();
  }

  void _setupRealtime() {
    _realtimeChannel = SupabaseService.instance.client
        .channel('public:payment_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'payments',
          callback: (payload) => _loadPayments(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getPaymentsForManagement();
      if (mounted) {
        setState(() {
          _payments = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách hóa đơn: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _filterStartDate != null && _filterEndDate != null
          ? DateTimeRange(start: _filterStartDate!, end: _filterEndDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _filterStartDate = picked.start;
        _filterEndDate = picked.end;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _filterStartDate = null;
      _filterEndDate = null;
    });
  }

  List<Map<String, dynamic>> get _filteredAndSortedPayments {
    var list = List<Map<String, dynamic>>.from(_payments);

    // Apply Search (Doctor Name, Patient Name, Service)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((p) {
        final appointment = p['appointments'] as Map<String, dynamic>?;
        if (appointment == null) return false;
        final patientName = (appointment['users']?['fullname'] as String? ?? '').toLowerCase();
        final doctorName = (appointment['doctors']?['fullname'] as String? ?? '').toLowerCase();
        final serviceName = (appointment['services']?['servicename'] as String? ?? '').toLowerCase();
        
        return patientName.contains(query) || doctorName.contains(query) || serviceName.contains(query);
      }).toList();
    }

    // Apply Date Range Filter
    if (_filterStartDate != null && _filterEndDate != null) {
      list = list.where((p) {
        final appointment = p['appointments'] as Map<String, dynamic>?;
        if (appointment == null) return false;
        final dateStr = appointment['appointmentdate'] as String?;
        if (dateStr == null) return false;
        final date = DateTime.tryParse(dateStr);
        if (date == null) return false;
        
        final checkDate = DateTime(date.year, date.month, date.day);
        final start = DateTime(_filterStartDate!.year, _filterStartDate!.month, _filterStartDate!.day);
        final end = DateTime(_filterEndDate!.year, _filterEndDate!.month, _filterEndDate!.day);
        
        return !checkDate.isBefore(start) && !checkDate.isAfter(end);
      }).toList();
    }

    // Apply Sorting
    list.sort((a, b) {
      final appA = a['appointments'] as Map<String, dynamic>?;
      final appB = b['appointments'] as Map<String, dynamic>?;
      final dateAStr = appA?['appointmentdate'] as String? ?? '';
      final dateBStr = appB?['appointmentdate'] as String? ?? '';
      final amountA = (a['totalamount'] as num?)?.toDouble() ?? 0.0;
      final amountB = (b['totalamount'] as num?)?.toDouble() ?? 0.0;

      switch (_sortBy) {
        case 'date_desc':
          return dateBStr.compareTo(dateAStr);
        case 'date_asc':
          return dateAStr.compareTo(dateBStr);
        case 'amount_desc':
          return amountB.compareTo(amountA);
        case 'amount_asc':
          return amountA.compareTo(amountB);
        default:
          return 0;
      }
    });

    return list;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)} đ';
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '—';
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  // ─── Dialog Chi Tiết Hóa Đơn ─────────────────────────────────────
  void _showPaymentDetails(Map<String, dynamic> payment) {
    final paymentId = payment['paymentid'] as int?;
    final amount = (payment['totalamount'] as num?)?.toDouble() ?? 0.0;
    final status = payment['status'] as String? ?? 'Pending';
    
    final appointment = payment['appointments'] as Map<String, dynamic>?;
    final patientName = appointment?['users']?['fullname'] as String? ?? 'N/A';
    final doctorName = appointment?['doctors']?['fullname'] as String? ?? 'N/A';
    final serviceName = appointment?['services']?['servicename'] as String? ?? 'N/A';
    final servicePrice = (appointment?['services']?['price'] as num?)?.toDouble() ?? 0.0;
    final date = _formatDate(appointment?['appointmentdate'] as String?);
    final time = appointment?['starttime'] as String? ?? 'N/A';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFCCFBF1),
              child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0D9488)),
            ),
            const SizedBox(width: 14),
            Text('Chi tiết Hóa đơn #$paymentId'),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(Icons.person_rounded, 'Bệnh nhân', patientName),
                _buildDetailRow(Icons.medical_services_rounded, 'Bác sĩ', doctorName),
                _buildDetailRow(Icons.event_rounded, 'Ngày khám', date),
                _buildDetailRow(Icons.schedule_rounded, 'Giờ khám', time),
                const Divider(height: 30),
                _buildDetailRow(Icons.healing_rounded, 'Dịch vụ', serviceName),
                _buildDetailRow(Icons.payments_outlined, 'Giá dịch vụ', _formatCurrency(servicePrice)),
                const Divider(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng thanh toán:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      _formatCurrency(amount),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Trạng thái:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'Success' ? const Color(0xFFCCFBF1) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: status == 'Success' ? const Color(0xFF0D9488) : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text('$label:', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

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
              'Đang tải danh sách hóa đơn...',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final filteredData = _filteredAndSortedPayments;
    final totalRevenue = filteredData.fold<double>(
        0, (sum, item) => sum + ((item['totalamount'] as num?)?.toDouble() ?? 0.0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quản lý Hóa đơn',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hiển thị ${filteredData.length} hóa đơn thành công - Tổng thu: ${_formatCurrency(totalRevenue)}',
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _loadPayments,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Làm mới'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Tools (Search, Filter, Sort) ────────────────────
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo bệnh nhân, bác sĩ, dịch vụ...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                ),
              ),
              // Date Filter
              InputChip(
                avatar: const Icon(Icons.calendar_month_rounded, size: 18),
                label: Text(_filterStartDate != null
                    ? '${DateFormat('dd/MM/yyyy').format(_filterStartDate!)} - ${DateFormat('dd/MM/yyyy').format(_filterEndDate!)}'
                    : 'Lọc theo ngày'),
                onSelected: (_) => _selectDateRange(),
                onDeleted: _filterStartDate != null ? _clearDateFilter : null,
                showCheckmark: false,
              ),
              // Sort Options
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    icon: const Icon(Icons.sort_rounded),
                    style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                    onChanged: (v) {
                      if (v != null) setState(() => _sortBy = v);
                    },
                    items: const [
                      DropdownMenuItem(value: 'date_desc', child: Text('Mới nhất')),
                      DropdownMenuItem(value: 'date_asc', child: Text('Cũ nhất')),
                      DropdownMenuItem(value: 'amount_desc', child: Text('Giá cao nhất')),
                      DropdownMenuItem(value: 'amount_asc', child: Text('Giá thấp nhất')),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Data Table ──────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: filteredData.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                            const SizedBox(height: 16),
                            Text(
                              'Không có hóa đơn nào phù hợp',
                              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        showCheckboxColumn: false,
                        headingRowColor: WidgetStatePropertyAll(
                            colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
                        dataRowMaxHeight: 72,
                        columnSpacing: 32,
                        horizontalMargin: 24,
                        columns: const [
                          DataColumn(label: Text('Mã HĐ')),
                          DataColumn(label: Text('Ngày')),
                          DataColumn(label: Text('Bệnh nhân')),
                          DataColumn(label: Text('Bác sĩ')),
                          DataColumn(label: Text('Dịch vụ')),
                          DataColumn(label: Text('Tổng tiền', textAlign: TextAlign.right)),
                          DataColumn(label: Text('Hành động')),
                        ],
                        rows: filteredData.map((p) {
                          final paymentId = p['paymentid'] as int?;
                          final amount = (p['totalamount'] as num?)?.toDouble() ?? 0.0;
                          
                          final appointment = p['appointments'] as Map<String, dynamic>?;
                          final patientName = appointment?['users']?['fullname'] as String? ?? 'N/A';
                          final doctorName = appointment?['doctors']?['fullname'] as String? ?? 'N/A';
                          final serviceName = appointment?['services']?['servicename'] as String? ?? 'N/A';
                          final date = _formatDate(appointment?['appointmentdate'] as String?);

                          return DataRow(
                            onSelectChanged: (_) => _showPaymentDetails(p),
                            cells: [
                              DataCell(Text('#$paymentId', style: const TextStyle(fontWeight: FontWeight.w500))),
                              DataCell(Text(date)),
                              DataCell(Text(patientName, style: const TextStyle(fontWeight: FontWeight.w500))),
                              DataCell(Text(doctorName)),
                              DataCell(Text(serviceName)),
                              DataCell(Text(_formatCurrency(amount), style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0D9488)))),
                              DataCell(
                                OutlinedButton.icon(
                                  onPressed: () => _showPaymentDetails(p),
                                  icon: const Icon(Icons.visibility_rounded, size: 18),
                                  label: const Text('Chi tiết'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colorScheme.primary,
                                    side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
