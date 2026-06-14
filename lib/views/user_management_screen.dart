import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinicbackend/services/supabase_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  String _searchQuery = '';
  String _roleFilter = 'all'; // 'all', 'doctor', 'patient'

  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _setupRealtime();
  }

  void _setupRealtime() {
    _realtimeChannel = SupabaseService.instance.client
        .channel('public:user_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'users',
          callback: (payload) => _loadUsers(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getUsersForManagement();
      if (mounted) {
        setState(() {
          _users = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách người dùng: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _toggleUserActive(
    int userId,
    bool currentStatus,
    String fullname,
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
          'Bạn có chắc chắn muốn $actionText tài khoản của "$fullname"?',
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
      await SupabaseService.instance.toggleUserActive(userId, newStatus);
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
                Text('Đã $actionText tài khoản "$fullname"'),
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
        _loadUsers();
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

  List<Map<String, dynamic>> get _filteredUsers {
    var list = _users;

    // Role filter
    if (_roleFilter != 'all') {
      list = list.where((u) => u['role'] == _roleFilter).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((u) {
        final name = (u['fullname'] as String? ?? '').toLowerCase();
        final email = (u['email'] as String? ?? '').toLowerCase();
        final phone = (u['phone'] as String? ?? '').toLowerCase();
        return name.contains(query) ||
            email.contains(query) ||
            phone.contains(query);
      }).toList();
    }

    return list;
  }

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'doctor':
        return 'Bác sĩ';
      case 'patient':
        return 'Bệnh nhân';
      default:
        return role ?? 'N/A';
    }
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'doctor':
        return const Color(0xFF7C3AED);
      case 'patient':
        return const Color(0xFF2563EB);
      default:
        return Colors.grey;
    }
  }

  Color _getRoleBgColor(String? role) {
    switch (role) {
      case 'doctor':
        return const Color(0xFFEDE9FE);
      case 'patient':
        return const Color(0xFFDBEAFE);
      default:
        return Colors.grey.shade100;
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
              'Đang tải danh sách người dùng...',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    // Count by role
    final doctorCount =
        _users.where((u) => u['role'] == 'doctor').length;
    final patientCount =
        _users.where((u) => u['role'] == 'patient').length;

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
                      'Quản lý Người dùng',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_users.length} người dùng ($doctorCount bác sĩ, $patientCount bệnh nhân)',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Làm mới'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Search + Role Filter ────────────────────────────
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
                    hintText: 'Tìm kiếm theo tên, email, SĐT...',
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
              // Role filter chips
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'all',
                    label: Text('Tất cả (${_users.length})'),
                  ),
                  ButtonSegment(
                    value: 'doctor',
                    label: Text('Bác sĩ ($doctorCount)'),
                    icon: const Icon(Icons.medical_services_rounded, size: 18),
                  ),
                  ButtonSegment(
                    value: 'patient',
                    label: Text('Bệnh nhân ($patientCount)'),
                    icon: const Icon(Icons.person_rounded, size: 18),
                  ),
                ],
                selected: {_roleFilter},
                onSelectionChanged: (set) {
                  setState(() => _roleFilter = set.first);
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
              child: _filteredUsers.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 48,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty && _roleFilter == 'all'
                                  ? 'Chưa có người dùng nào trong hệ thống'
                                  : 'Không tìm thấy người dùng phù hợp',
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
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Số điện thoại')),
                          DataColumn(label: Text('Vai trò')),
                          DataColumn(label: Text('Trạng thái')),
                          DataColumn(label: Text('Hành động')),
                        ],
                        rows: _filteredUsers.map((user) {
                          final isActive =
                              user['isactive'] as bool? ?? true;
                          final userId = user['userid'] as int? ?? 0;
                          final fullname =
                              user['fullname'] as String? ?? 'N/A';
                          final email = user['email'] as String? ?? 'N/A';
                          final phone = user['phone'] as String? ?? '—';
                          final role = user['role'] as String?;

                          return DataRow(
                            cells: [
                              // ID
                              DataCell(
                                Text(
                                  '#$userId',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              // Name + Avatar
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: _getRoleBgColor(role),
                                      child: Icon(
                                        role == 'doctor'
                                            ? Icons.medical_services_rounded
                                            : Icons.person_rounded,
                                        size: 20,
                                        color: _getRoleColor(role),
                                      ),
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
                              // Email
                              DataCell(Text(email)),
                              // Phone
                              DataCell(Text(phone)),
                              // Role badge
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRoleBgColor(role),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        role == 'doctor'
                                            ? Icons.medical_services_rounded
                                            : Icons.person_rounded,
                                        size: 14,
                                        color: _getRoleColor(role),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _getRoleLabel(role),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: _getRoleColor(role),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Status badge
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
                                        isActive ? 'Hoạt động' : 'Đã khóa',
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
                              // Action
                              DataCell(
                                isActive
                                    ? OutlinedButton.icon(
                                        onPressed: () => _toggleUserActive(
                                          userId,
                                          isActive,
                                          fullname,
                                        ),
                                        icon: const Icon(Icons.lock_rounded,
                                            size: 18),
                                        label: const Text('Khóa'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: colorScheme.error,
                                          side: BorderSide(
                                            color: colorScheme.error
                                                .withValues(alpha: 0.5),
                                          ),
                                          padding: const EdgeInsets.symmetric(
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
                                        onPressed: () => _toggleUserActive(
                                          userId,
                                          isActive,
                                          fullname,
                                        ),
                                        icon: const Icon(
                                            Icons.lock_open_rounded,
                                            size: 18),
                                        label: const Text('Mở khóa'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: colorScheme.primary,
                                          padding: const EdgeInsets.symmetric(
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
