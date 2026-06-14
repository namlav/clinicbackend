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
  /// Returns the user's role string, or null if not found
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

  /// Sum revenue from successful payments
  Future<double> getTotalRevenue() async {
    final response = await client
        .from('payments')
        .select('amount')
        .eq('status', 'Success');
    double total = 0;
    for (final row in response as List) {
      total += (row['amount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  /// Count active doctors (users with role = 'doctor' and is_active = true)
  Future<int> getActiveDoctorsCount() async {
    final response = await client
        .from('doctors')
        .select('doctorid');
    return (response as List).length;
  }

  /// Get appointment counts for the last 7 days
  /// Returns a list of {date, count} maps sorted by date ascending
  Future<List<Map<String, dynamic>>> getAppointmentsLast7Days() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    final startDate = sevenDaysAgo.toIso8601String().split('T')[0];
    final endDate = now.toIso8601String().split('T')[0];

    final response = await client
        .from('appointments')
        .select('appointmentdate')
        .gte('appointmentdate', startDate)
        .lte('appointmentdate', endDate);

    // Group by date
    final Map<String, int> countMap = {};
    for (int i = 0; i <= 6; i++) {
      final date =
          sevenDaysAgo.add(Duration(days: i)).toIso8601String().split('T')[0];
      countMap[date] = 0;
    }
    for (final row in response as List) {
      final date = row['appointmentdate'] as String;
      countMap[date] = (countMap[date] ?? 0) + 1;
    }

    final result = countMap.entries
        .map((e) => {'date': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) =>
          (a['date'] as String).compareTo(b['date'] as String));
    return result;
  }

  /// Get revenue for the last 7 days
  /// Returns a list of {date, amount} maps sorted by date ascending
  Future<List<Map<String, dynamic>>> getRevenueLast7Days() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    final startDate = sevenDaysAgo.toIso8601String().split('T')[0];
    final endDate = now.toIso8601String().split('T')[0];

    // Join payments with appointments to get the date
    final response = await client
        .from('payments')
        .select('amount, appointments!inner(appointmentdate)')
        .eq('status', 'Success')
        .gte('appointments.appointmentdate', startDate)
        .lte('appointments.appointmentdate', endDate);

    // Group by date
    final Map<String, double> revenueMap = {};
    for (int i = 0; i <= 6; i++) {
      final date =
          sevenDaysAgo.add(Duration(days: i)).toIso8601String().split('T')[0];
      revenueMap[date] = 0;
    }
    for (final row in response as List) {
      final appointment = row['appointments'] as Map<String, dynamic>;
      final date = appointment['appointmentdate'] as String;
      revenueMap[date] =
          (revenueMap[date] ?? 0) + ((row['amount'] as num?)?.toDouble() ?? 0);
    }

    final result = revenueMap.entries
        .map((e) => {'date': e.key, 'amount': e.value})
        .toList()
      ..sort((a, b) =>
          (a['date'] as String).compareTo(b['date'] as String));
    return result;
  }

  // ─── Doctor Methods ─────────────────────────────────────────────

  /// Fetch all doctors with their user status (is_active)
  /// Returns joined data from doctors + users tables
  Future<List<Map<String, dynamic>>> getDoctorsWithStatus() async {
    final response = await client
        .from('doctors')
        .select('*, users!inner(is_active, email, phone)');
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Toggle is_active status on users table for a given userid
  Future<void> toggleDoctorActive(int userId, bool isActive) async {
    await client
        .from('users')
        .update({'is_active': isActive})
        .eq('userid', userId);
  }

  // ─── Service Methods ────────────────────────────────────────────

  /// Fetch all services
  Future<List<Map<String, dynamic>>> getServices() async {
    final response = await client
        .from('services')
        .select('*')
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
    await client.from('services').insert({
      'servicename': servicename,
      'price': price,
      'specialtyid': specialtyid,
      'description': description ?? '',
      'is_active': true,
    });
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
    if (isActive != null) updates['is_active'] = isActive;
    if (description != null) updates['description'] = description;

    if (updates.isNotEmpty) {
      await client
          .from('services')
          .update(updates)
          .eq('serviceid', serviceid);
    }
  }
}
