import 'package:flutter/material.dart';
import 'package:clinicbackend/services/supabase_service.dart';

class DoctorManagementScreen extends StatefulWidget {
  const DoctorManagementScreen({super.key});

  @override
  State<DoctorManagementScreen> createState() => _DoctorManagementScreenState();
}

class _DoctorManagementScreenState extends State<DoctorManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _doctors = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getDoctorsWithStatus();
      if (mounted) {
        setState(() {
          _doctors = data;
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _toggleDoctorActive(
      int userId, bool currentStatus, String doctorName) async {
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _loadDoctors(); // Reload data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật trạng thái: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredDoctors {
    if (_searchQuery.isEmpty) return _doctors;
    final query = _searchQuery.toLowerCase();
    return _doctors.where((doc) {
      final name = (doc['fullname'] as String? ?? '').toLowerCase();
      final email =
          ((doc['users'] as Map?)?['email'] as String? ?? '').toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
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
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
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

          // ─── Search Bar ──────────────────────────────────────
          SizedBox(
            width: 400,
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bác sĩ...',
                prefixIcon: const Icon(Icons.search_rounded),
                fillColor:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
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
                            Icon(Icons.person_search_rounded,
                                size: 48,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.4)),
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
                              users['is_active'] as bool? ?? true;
                          final userId = doc['userid'] as int? ?? 0;
                          final fullname =
                              doc['fullname'] as String? ?? 'N/A';
                          final email =
                              users['email'] as String? ?? 'N/A';

                          return DataRow(
                            cells: [
                              DataCell(Text(
                                '#${doc['doctorid']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              )),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: colorScheme.primaryContainer,
                                      backgroundImage:
                                          doc['avatarurl'] != null &&
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
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text(
                                doc['specialtyid'] != null
                                    ? 'Khoa ${doc['specialtyid']}'
                                    : 'N/A',
                              )),
                              DataCell(Text(
                                doc['experienceyears'] != null
                                    ? '${doc['experienceyears']} năm'
                                    : 'N/A',
                              )),
                              DataCell(Text(email)),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xFFCCFBF1)
                                        : const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(20),
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
                                                userId, isActive, fullname),
                                        icon: const Icon(
                                            Icons.lock_rounded,
                                            size: 18),
                                        label: const Text('Khóa'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: colorScheme.error,
                                          side: BorderSide(
                                              color: colorScheme.error
                                                  .withValues(alpha: 0.5)),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      )
                                    : FilledButton.icon(
                                        onPressed: () =>
                                            _toggleDoctorActive(
                                                userId, isActive, fullname),
                                        icon: const Icon(
                                            Icons.lock_open_rounded,
                                            size: 18),
                                        label: const Text('Mở khóa'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: colorScheme.primary,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
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
