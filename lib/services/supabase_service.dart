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
}
