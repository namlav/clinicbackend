import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinicbackend/services/supabase_service.dart';

class DoctorManagementScreen extends StatefulWidget {
  const DoctorManagementScreen({super.key});

  @override
  State<DoctorManagementScreen> createState() => _DoctorManagementScreenState();
}

class _DoctorManagementScreenState extends State<DoctorManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _doctors = [];
  Map<int, String> _specialtyNames = {};
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'active', 'inactive'
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
    _setupRealtime();
  }

  void _setupRealtime() {
    _realtimeChannel = SupabaseService.instance.client
        .channel('public:doctor_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'doctors',
          callback: (payload) => _loadDoctors(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'users',
          callback: (payload) => _loadDoctors(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SupabaseService.instance.getDoctorsWithStatus(),
        SupabaseService.instance.getSpecialtyNames(),
      ]);
      if (mounted) {
        setState(() {
          _doctors = results[0] as List<Map<String, dynamic>>;
          _specialtyNames = results[1] as Map<int, String>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách bác sĩ: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  String _getSpecialtyName(int? specialtyId) {
    if (specialtyId == null) return 'N/A';
    return _specialtyNames[specialtyId] ?? 'Khoa $specialtyId';
  }

  Future<void> _toggleDoctorActive(
    int userId,
    bool currentStatus,
    String doctorName,
  ) async {
    final newStatus = !currentStatus;
    final actionText = newStatus ? 'Mở khóa' : 'Khóa';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(
          newStatus ? Icons.lock_open_rounded : Icons.lock_rounded,
          color: newStatus
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
          size: 40,
        ),
        title: Text('$actionText tài khoản'),
        content: Text(
          'Bạn có chắc chắn muốn $actionText tài khoản của bác sĩ "$doctorName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: newStatus
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
            ),
            child: Text(actionText),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await SupabaseService.instance.toggleDoctorActive(userId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  newStatus ? Icons.check_circle : Icons.block,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text('Đã $actionText tài khoản bác sĩ "$doctorName"'),
              ],
            ),
            backgroundColor: newStatus
                ? const Color(0xFF0D9488)
                : Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        _loadDoctors();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật trạng thái: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showDoctorDetails(Map<String, dynamic> doc) {
    final users = doc['users'] as Map<String, dynamic>? ?? {};
    final isActive = users['isactive'] as bool? ?? true;
    final email = users['email'] as String? ?? 'N/A';
    final phone = users['phone'] as String? ?? 'N/A';
    final fullname = doc['fullname'] as String? ?? 'N/A';
    final experience = doc['experienceyears']?.toString() ?? 'N/A';
    final specialty = _getSpecialtyName(doc['specialtyid'] as int?);
    final bio = doc['bio'] as String? ?? 'Chưa có thông tin giới thiệu';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: doc['avatarurl'] != null &&
                      (doc['avatarurl'] as String).isNotEmpty
                  ? NetworkImage(doc['avatarurl'] as String)
                  : null,
              child: doc['avatarurl'] == null ||
                      (doc['avatarurl'] as String).isEmpty
                  ? Icon(Icons.person_rounded,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fullname,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFCCFBF1)
                          : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Đang hoạt động' : 'Đã khóa',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isActive
                            ? const Color(0xFF065F46)
                            : const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(Icons.badge_rounded, 'Mã Bác sĩ',
                    '#${doc['doctorid']}'),
                _buildDetailRow(Icons.perm_identity_rounded, 'Mã User',
                    '#${doc['userid']}'),
                _buildDetailRow(
                    Icons.category_rounded, 'Chuyên khoa', specialty),
                _buildDetailRow(Icons.work_history_rounded, 'Kinh nghiệm',
                    '$experience năm'),
                const Divider(height: 24),
                _buildDetailRow(Icons.email_rounded, 'Email', email),
                _buildDetailRow(Icons.phone_rounded, 'Số điện thoại', phone),
                const Divider(height: 24),
                const Text('Giới thiệu:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(bio,
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant)),
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
        children: [
          Icon(icon,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text('$label:',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredDoctors {
    var list = _doctors;

    if (_statusFilter != 'all') {
      list = list.where((doc) {
        final users = doc['users'] as Map<String, dynamic>? ?? {};
        final isActive = users['isactive'] as bool? ?? true;
        return _statusFilter == 'active' ? isActive : !isActive;
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((doc) {
        final name = (doc['fullname'] as String? ?? '').toLowerCase();
        final users = doc['users'] as Map<String, dynamic>? ?? {};
        final email = (users['email'] as String? ?? '').toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    }

    return list;
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
              'Đang tải danh sách bác sĩ...',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

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
                      'Danh sách Bác sĩ',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_doctors.length} bác sĩ trong hệ thống',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Refresh button
              FilledButton.tonalIcon(
                onPressed: _loadDoctors,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Làm mới'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Search + Filter ───────────────────────────────────
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 360,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm bác sĩ...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    fillColor: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text('Tất cả')),
                  ButtonSegment(
                    value: 'active',
                    label: Text('Đang hoạt động'),
                    icon: Icon(Icons.check_circle_rounded, size: 18),
                  ),
                  ButtonSegment(
                    value: 'inactive',
                    label: Text('Đã khóa'),
                    icon: Icon(Icons.cancel_rounded, size: 18),
                  ),
                ],
                selected: {_statusFilter},
                onSelectionChanged: (set) {
                  setState(() => _statusFilter = set.first);
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStatePropertyAll(
                      Theme.of(context).textTheme.bodySmall),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _filteredDoctors.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_search_rounded,
                              size: 48,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Chưa có bác sĩ nào trong hệ thống'
                                  : 'Không tìm thấy bác sĩ phù hợp',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 16,
                              ),
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
                          colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                        ),
                        dataRowMaxHeight: 72,
                        columnSpacing: 32,
                        horizontalMargin: 24,
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Họ và tên')),
                          DataColumn(label: Text('Chuyên khoa')),
                          DataColumn(label: Text('Kinh nghiệm')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Trạng thái')),
                          DataColumn(label: Text('Hành động')),
                        ],
                        rows: _filteredDoctors.map((doc) {
                          final users =
                              doc['users'] as Map<String, dynamic>? ?? {};
                          final isActive =
                              users['isactive'] as bool? ?? true;
                          final userId = doc['userid'] as int? ?? 0;
                          final fullname =
                              doc['fullname'] as String? ?? 'N/A';
                          final email =
                              users['email'] as String? ?? 'N/A';

                          return DataRow(
                            onSelectChanged: (_) =>
                                _showDoctorDetails(doc),
                            cells: [
                              DataCell(
                                Text(
                                  '#${doc['doctorid']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor:
                                          colorScheme.primaryContainer,
                                      backgroundImage: doc['avatarurl'] !=
                                                  null &&
                                              (doc['avatarurl'] as String)
                                                  .isNotEmpty
                                          ? NetworkImage(
                                              doc['avatarurl'] as String)
                                          : null,
                                      child: doc['avatarurl'] == null ||
                                              (doc['avatarurl'] as String)
                                                  .isEmpty
                                          ? Icon(Icons.person_rounded,
                                              size: 20,
                                              color: colorScheme.primary)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      fullname,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(_getSpecialtyName(
                                    doc['specialtyid'] as int?)),
                              ),
                              DataCell(
                                Text(
                                  doc['experienceyears'] != null
                                      ? '${doc['experienceyears']} năm'
                                      : 'N/A',
                                ),
                              ),
                              DataCell(Text(email)),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xFFCCFBF1)
                                        : const Color(0xFFFEE2E2),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isActive
                                              ? const Color(0xFF0D9488)
                                              : const Color(0xFFEF4444),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isActive
                                            ? 'Hoạt động'
                                            : 'Đã khóa',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: isActive
                                              ? const Color(0xFF065F46)
                                              : const Color(0xFFB91C1C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                isActive
                                    ? OutlinedButton.icon(
                                        onPressed: () =>
                                            _toggleDoctorActive(
                                          userId,
                                          isActive,
                                          fullname,
                                        ),
                                        icon: const Icon(
                                          Icons.lock_rounded,
                                          size: 18,
                                        ),
                                        label: const Text('Khóa'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              colorScheme.error,
                                          side: BorderSide(
                                            color: colorScheme.error
                                                .withValues(alpha: 0.5),
                                          ),
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      )
                                    : FilledButton.icon(
                                        onPressed: () =>
                                            _toggleDoctorActive(
                                          userId,
                                          isActive,
                                          fullname,
                                        ),
                                        icon: const Icon(
                                          Icons.lock_open_rounded,
                                          size: 18,
                                        ),
                                        label: const Text('Mở khóa'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              colorScheme.primary,
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
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
