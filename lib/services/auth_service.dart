import 'package:supabase_flutter/supabase_flutter.dart';

enum AppRole { admin, staff, viewer, guest }

class AuthService {
  final _client = Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Future<void> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) return;

    final profile = {
      'id': user.id,
      'email': user.email,
      'full_name': user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? 'Staff User',
      'role': 'staff',
    };

    await _client.from('profiles').upsert(profile, onConflict: 'id');
  }

  Future<void> signOut() async => _client.auth.signOut();

  /// Fetches the logged-in user's role from `profiles`. Returns guest if
  /// not logged in — used to gate the staff-only UI (Booking Jadual, Calendar edit, etc.)
  Future<AppRole> currentRole() async {
    final user = currentUser;
    if (user == null) return AppRole.guest;

    var row = await _client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) {
      await _client.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'full_name': user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? 'Staff User',
        'role': 'staff',
      }, onConflict: 'id');
      row = {'role': 'staff'};
    }

    switch (row['role']) {
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
