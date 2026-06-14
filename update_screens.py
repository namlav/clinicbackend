import re

# dashboard_screen.dart
with open('e:/MobileApp/project/clinicbackend/lib/views/dashboard_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(
    r'(void initState\(\) \{\s+super\.initState\(\);\s+_loadDashboardData\(\);\s+\})',
    '''RealtimeChannel? _realtimeChannel;

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
  }''',
    content
)
content = re.sub(
    r'(import \'package:clinicbackend/services/supabase_service\.dart\';)',
    '''import 'package:supabase_flutter/supabase_flutter.dart';\nimport 'package:clinicbackend/services/supabase_service.dart';''',
    content
)

with open('e:/MobileApp/project/clinicbackend/lib/views/dashboard_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# service_management_screen.dart
with open('e:/MobileApp/project/clinicbackend/lib/views/service_management_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(
    r'(void initState\(\) \{\s+super\.initState\(\);\s+_loadServices\(\);\s+\})',
    '''RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _loadServices();
    _setupRealtime();
  }

  void _setupRealtime() {
    _realtimeChannel = SupabaseService.instance.client
        .channel('public:service_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'services',
          callback: (payload) => _loadServices(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }''',
    content
)
content = re.sub(
    r'(import \'package:clinicbackend/services/supabase_service\.dart\';)',
    '''import 'package:supabase_flutter/supabase_flutter.dart';\nimport 'package:clinicbackend/services/supabase_service.dart';''',
    content
)

with open('e:/MobileApp/project/clinicbackend/lib/views/service_management_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# user_management_screen.dart
with open('e:/MobileApp/project/clinicbackend/lib/views/user_management_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(
    r'(void initState\(\) \{\s+super\.initState\(\);\s+_loadUsers\(\);\s+\})',
    '''RealtimeChannel? _realtimeChannel;

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
  }''',
    content
)
content = re.sub(
    r'(import \'package:clinicbackend/services/supabase_service\.dart\';)',
    '''import 'package:supabase_flutter/supabase_flutter.dart';\nimport 'package:clinicbackend/services/supabase_service.dart';''',
    content
)

with open('e:/MobileApp/project/clinicbackend/lib/views/user_management_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# doctor_management_screen.dart
with open('e:/MobileApp/project/clinicbackend/lib/views/doctor_management_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(
    r'(import \'package:clinicbackend/services/supabase_service\.dart\';)',
    '''import 'package:supabase_flutter/supabase_flutter.dart';\nimport 'package:clinicbackend/services/supabase_service.dart';''',
    content
)
content = re.sub(
    r'(void initState\(\) \{\s+super\.initState\(\);\s+_loadDoctors\(\);\s+\})',
    '''RealtimeChannel? _realtimeChannel;

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
  }''',
    content
)

content = re.sub(
    r"String _searchQuery = '';",
    '''String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'active', 'inactive'

  void _showDoctorDetails(Map<String, dynamic> doc) {
    final users = doc['users'] as Map<String, dynamic>? ?? {};
    final isActive = users['isactive'] as bool? ?? true;
    final email = users['email'] as String? ?? 'N/A';
    final phone = users['phone'] as String? ?? 'N/A';
    final fullname = doc['fullname'] as String? ?? 'N/A';
    final experience = doc['experienceyears']?.toString() ?? 'N/A';
    final specialty = doc['specialtyid'] != null ? 'Khoa ${doc['specialtyid']}' : 'N/A';
    final bio = doc['bio'] as String? ?? 'Chưa có thông tin giới thiệu';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: doc['avatarurl'] != null && (doc['avatarurl'] as String).isNotEmpty
                  ? NetworkImage(doc['avatarurl'] as String)
                  : null,
              child: doc['avatarurl'] == null || (doc['avatarurl'] as String).isEmpty
                  ? Icon(Icons.person_rounded, color: Theme.of(context).colorScheme.primary)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fullname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFCCFBF1) : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Đang hoạt động' : 'Đã khóa',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isActive ? const Color(0xFF065F46) : const Color(0xFFB91C1C),
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
                _buildDetailRow(context, Icons.badge_rounded, 'Mã Bác sĩ', '#${doc['doctorid']}'),
                _buildDetailRow(context, Icons.category_rounded, 'Chuyên khoa', specialty),
                _buildDetailRow(context, Icons.work_history_rounded, 'Kinh nghiệm', '$experience năm'),
                const Divider(height: 24),
                _buildDetailRow(context, Icons.email_rounded, 'Email', email),
                _buildDetailRow(context, Icons.phone_rounded, 'Số điện thoại', phone),
                const Divider(height: 24),
                const Text('Giới thiệu:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(bio, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(label + ':', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }''',
    content
)

content = re.sub(
    r'List<Map<String, dynamic>> get _filteredDoctors \{[\s\S]*?return _doctors\.where\(\(doc\) \{[\s\S]*?\}\)\.toList\(\);\s+\}',
    '''List<Map<String, dynamic>> get _filteredDoctors {
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
  }''',
    content
)

content = re.sub(
    r'SizedBox\(\s*width: 400,\s*child: TextField\(',
    '''Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 360,
                child: TextField(''',
    content
)

content = re.sub(
    r'(\s*border: OutlineInputBorder\([\s\S]*?\),\s*\),\s*\),\s*),(\s*)const SizedBox\(height: 20\),',
    r'\1,\2              SegmentedButton<String>(\2                segments: const [\2                  ButtonSegment(value: \'all\', label: Text(\'Tất cả\')),\2                  ButtonSegment(value: \'active\', label: Text(\'Đang hoạt động\'), icon: Icon(Icons.check_circle_rounded, size: 18)),\2                  ButtonSegment(value: \'inactive\', label: Text(\'Đã khóa\'), icon: Icon(Icons.cancel_rounded, size: 18)),\2                ],\2                selected: {_statusFilter},\2                onSelectionChanged: (set) => setState(() => _statusFilter = set.first),\2                style: ButtonStyle(\2                  visualDensity: VisualDensity.compact,\2                  textStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.bodySmall),\2                ),\2              ),\2            ],\2          ),\2          const SizedBox(height: 20),',
    content
)

content = re.sub(
    r'(DataTable\(\s*headingRowColor: WidgetStatePropertyAll\()',
    r'DataTable(\n                        showCheckboxColumn: false,\n                        headingRowColor: WidgetStatePropertyAll(',
    content
)

content = re.sub(
    r'(return DataRow\()',
    r'return DataRow(\n                            onSelectChanged: (_) => _showDoctorDetails(doc),',
    content
)

with open('e:/MobileApp/project/clinicbackend/lib/views/doctor_management_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done python script")
