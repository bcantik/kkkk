import 'package:supabase_flutter/supabase_flutter.dart';

enum AppRole { admin, staff, viewer, guest }

class AuthService {
  final _client = Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async => _client.auth.signOut();

  /// Fetches the logged-in user's role from `profiles`. Returns guest if
  /// not logged in — used to gate the staff-only UI (Booking Jadual, Calendar edit, etc.)
  Future<AppRole> currentRole() async {
    final user = currentUser;
    if (user == null) return AppRole.guest;
    final row = await _client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();
    switch (row?['role']) {
      case 'admin':
        return AppRole.admin;
      case 'staff':
        return AppRole.staff;
      case 'viewer':
        return AppRole.viewer;
      default:
        return AppRole.guest;
    }
  }
}
