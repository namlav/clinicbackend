import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton service class for all Supabase API interactions.
/// Provides a centralized access point to the Supabase client
/// and authentication helpers.
class SupabaseService {
  // Private constructor
  SupabaseService._();

  /// Singleton instance
  static final SupabaseService instance = SupabaseService._();

  /// Quick accessor for the Supabase client
  SupabaseClient get client => Supabase.instance.client;

  /// Quick accessor for auth
  GoTrueClient get auth => client.auth;

  /// Current authenticated user (nullable)
  User? get currentUser => auth.currentUser;

  /// Check if a user is currently logged in
  bool get isLoggedIn => currentUser != null;

  // ─── Auth Methods ───────────────────────────────────────────────

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await auth.signInWithPassword(email: email, password: password);
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await auth.signOut();
  }

  /// After sign-in, verify the user has the 'admin' role
  Future<String?> getUserRole(String authId) async {
    final response = await client
        .from('users')
        .select('role')
        .eq('authid', authId)
        .maybeSingle();

    if (response == null) return null;
    return response['role'] as String?;
  }

  // ─── Dashboard Methods ──────────────────────────────────────────

  /// Count appointments for today
  Future<int> getTodayAppointmentsCount() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final response = await client
        .from('appointments')
        .select('appointmentid')
        .eq('appointmentdate', today);
    return (response as List).length;
  }

  /// Count appointments within a date range
  Future<int> getAppointmentsCountByRange(
    String startDate,
    String endDate,
  ) async {
    final response = await client
        .from('appointments')
        .select('appointmentid')
        .gte('appointmentdate', startDate)
        .lte('appointmentdate', endDate);
    return (response as List).length;
  }

  /// Sum revenue from successful payments (all time)
  Future<double> getTotalRevenue() async {
    final response = await client
        .from('payments')
        .select('totalamount')
        .eq('status', 'Success');
    double total = 0;
    for (final row in response as List) {
      total += (row['totalamount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  /// Sum revenue from successful payments within a date range
  Future<double> getRevenueByRange(String startDate, String endDate) async {
    final response = await client
        .from('payments')
        .select('''
          totalamount,
          appointments (appointmentdate)
        ''')
        .eq('status', 'Success')
        .gte('appointments.appointmentdate', startDate)
        .lte('appointments.appointmentdate', endDate);
    double total = 0;
    for (final row in response as List) {
      final appointment = row['appointments'] as Map<String, dynamic>?;
      if (appointment == null) continue;
      total += (row['totalamount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  /// Count active doctors
  Future<int> getActiveDoctorsCount() async {
    final response = await client
        .from('doctors')
        .select('*, users!inner(isactive)')
        .eq('users.isactive', true);
    return (response as List).length;
  }

  /// Get appointment counts grouped by date within a range
  Future<List<Map<String, dynamic>>> getAppointmentsByRange(
    String startDate,
    String endDate,
  ) async {
    final response = await client
        .from('appointments')
        .select('appointmentdate')
        .gte('appointmentdate', startDate)
        .lte('appointmentdate', endDate);

    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);
    final Map<String, int> countMap = {};
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      countMap[d.toIso8601String().split('T')[0]] = 0;
    }
    for (final row in response as List) {
      final date = row['appointmentdate'] as String;
      countMap[date] = (countMap[date] ?? 0) + 1;
    }

    final result =
        countMap.entries.map((e) => {'date': e.key, 'count': e.value}).toList()
          ..sort(
            (a, b) => (a['date'] as String).compareTo(b['date'] as String),
          );
    return result;
  }

  /// Get revenue grouped by date within a range
  Future<List<Map<String, dynamic>>> getRevenueByRangeGrouped(
    String startDate,
    String endDate,
  ) async {
    final response = await client
        .from('payments')
        .select('''
          paymentid,
          totalamount,
          status,
          appointments (
            appointmentid,
            appointmentdate,
            starttime,
            users (fullname),
            doctors (fullname),
            services (servicename, price)
          )
        ''')
        .eq('status', 'Success')
        .gte('appointments.appointmentdate', startDate)
        .lte('appointments.appointmentdate', endDate);

    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);
    final Map<String, double> revenueMap = {};
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      revenueMap[d.toIso8601String().split('T')[0]] = 0;
    }
    for (final row in response as List) {
      final appointment = row['appointments'] as Map<String, dynamic>?;
      if (appointment == null) continue;
      final date = appointment['appointmentdate'] as String;
      revenueMap[date] =
          (revenueMap[date] ?? 0) +
          ((row['totalamount'] as num?)?.toDouble() ?? 0);
    }

    final result =
        revenueMap.entries
            .map((e) => {'date': e.key, 'totalamount': e.value})
            .toList()
          ..sort(
            (a, b) => (a['date'] as String).compareTo(b['date'] as String),
          );
    return result;
  }

  /// Convenience: last 7 days appointments
  Future<List<Map<String, dynamic>>> getAppointmentsLast7Days() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 6));
    return getAppointmentsByRange(
      start.toIso8601String().split('T')[0],
      now.toIso8601String().split('T')[0],
    );
  }

  /// Convenience: last 7 days revenue
  Future<List<Map<String, dynamic>>> getRevenueLast7Days() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 6));
    return getRevenueByRangeGrouped(
      start.toIso8601String().split('T')[0],
      now.toIso8601String().split('T')[0],
    );
  }

  // ─── Doctor Methods ─────────────────────────────────────────────

  /// Fetch all doctors with their user status
  Future<List<Map<String, dynamic>>> getDoctorsWithStatus() async {
    final response = await client
        .from('doctors')
        .select('*, users(isactive, email, phone)');
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Fetch specialty names from specialties table
  Future<Map<int, String>> getSpecialtyNames() async {
    final response = await client
        .from('specialties')
        .select('specialtyid, specialtyname');
    final Map<int, String> map = {};
    for (final row in response as List) {
      final id = row['specialtyid'] as int?;
      final name = row['specialtyname'] as String?;
      if (id != null) {
        map[id] = name ?? 'Khoa $id';
      }
    }
    return map;
  }

  /// Get completed appointments count for a specific user
  Future<int> getCompletedAppointmentsCount(int userId) async {
    final response = await client
        .from('appointments')
        .select('appointmentid')
        .eq('userid', userId)
        .eq('status', 'Completed');
    return (response as List).length;
  }

  /// Toggle isactive status on users table for a given userid
  Future<void> toggleDoctorActive(int userId, bool isActive) async {
    final result = await client
        .from('users')
        .update({'isactive': isActive})
        .eq('userid', userId)
        .select();
    if ((result as List).isEmpty) {
      throw Exception(
        'Cập nhật trạng thái thất bại. Vui lòng kiểm tra quyền truy cập DB (RLS).',
      );
    }
  }

  // ─── Service Methods ────────────────────────────────────────────

  /// Fetch all services
  Future<List<Map<String, dynamic>>> getServices() async {
    final response = await client
        .from('services')
        .select('*, specialties(specialtyname)')
        .order('serviceid', ascending: true);
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Add a new service
  Future<void> addService({
    required String servicename,
    required double price,
    int? specialtyid,
    String? description,
  }) async {
    final result = await client.from('services').insert({
      'servicename': servicename,
      'price': price,
      'specialtyid': specialtyid,
      'description': description ?? '',
      'isactive': true,
    }).select();
    if ((result as List).isEmpty) {
      throw Exception(
        'Thêm dịch vụ thất bại. Vui lòng kiểm tra quyền truy cập DB (RLS).',
      );
    }
  }

  /// Update a service
  Future<void> updateService({
    required int serviceid,
    String? servicename,
    double? price,
    bool? isActive,
    String? description,
  }) async {
    final Map<String, dynamic> updates = {};
    if (servicename != null) updates['servicename'] = servicename;
    if (price != null) updates['price'] = price;
    if (isActive != null) updates['isactive'] = isActive;
    if (description != null) updates['description'] = description;

    if (updates.isNotEmpty) {
      final result = await client
          .from('services')
          .update(updates)
          .eq('serviceid', serviceid)
          .select();
      if ((result as List).isEmpty) {
        throw Exception(
          'Cập nhật dịch vụ thất bại. Vui lòng kiểm tra quyền truy cập DB (RLS).',
        );
      }
    }
  }

  // ─── User Methods (Phase 5) ─────────────────────────────────────

  /// Fetch all users with role 'doctor' or 'patient'
  Future<List<Map<String, dynamic>>> getUsersForManagement() async {
    final response = await client
        .from('users')
        .select('*')
        .or('role.eq.doctor,role.eq.patient')
        .order('userid', ascending: true);
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Toggle isactive on users table
  Future<void> toggleUserActive(int userId, bool isActive) async {
    final result = await client
        .from('users')
        .update({'isactive': isActive})
        .eq('userid', userId)
        .select();
    if ((result as List).isEmpty) {
      throw Exception(
        'Cập nhật trạng thái thất bại. Vui lòng kiểm tra quyền truy cập DB (RLS).',
      );
    }
  }

  // ─── Payment Methods (Phase 6) ──────────────────────────────────

  /// Fetch all successful payments with related appointment details
  Future<List<Map<String, dynamic>>> getPaymentsForManagement() async {
    final response = await client
        .from('payments')
        .select('''
          paymentid,
          totalamount,
          status,
          appointments (
            appointmentid,
            appointmentdate,
            starttime,
            users (fullname),
            doctors (fullname),
            services (servicename, price)
          )
        ''')
        .eq('status', 'Success')
        .order('paymentid', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }
}
