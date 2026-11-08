import 'package:shared_preferences/shared_preferences.dart';

/// A signed-in user, provider-agnostic so the UI never depends on Firebase.
class AuthUser {
  const AuthUser({required this.name, required this.email, required this.provider});
  final String name;
  final String email;
  final String provider; // 'google' | 'email' | 'github' | 'microsoft'
}

/// Auth backend contract. The app talks only to this interface, so swapping
/// the prototype for real Firebase (see FIREBASE_SETUP.md) is a one-line
/// change in [createAuthService].
abstract class AuthService {
  /// [email] is the account chosen in the picker. Real Firebase ignores it
  /// (Google/Apple supply the identity); the prototype uses it to build the
  /// signed-in user.
  Future<AuthUser?> signInWithGoogle({String? email});
  Future<AuthUser?> signInWithMicrosoft({String? email});
  /// [email] carries the chosen GitHub username (or email) in the prototype.
  Future<AuthUser?> signInWithGitHub({String? email});
  Future<AuthUser?> signInWithEmail(String email, String password);
  Future<void> signOut();
}

/// Pick the backend. Flip this to `FirebaseAuthService()` once Firebase is
/// configured (instructions in FIREBASE_SETUP.md).
AuthService createAuthService() => LocalAuthService();

/// Prototype auth: no network, no real identity. It simulates a sign-in so the
/// whole onboarding flow is clickable and testable today, and persists the
/// "session" locally. Real credentials are never collected.
class LocalAuthService implements AuthService {
  Future<AuthUser> _simulate(String provider, {String? email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final mail = email ??
        switch (provider) {
          'microsoft' => 'you@outlook.com',
          'github' => 'octocat',
          _ => 'you@gmail.com',
        };
    final name = _nameFromEmail(mail);
    final user = AuthUser(name: name, email: mail, provider: provider);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_email', mail);
    await prefs.setString('auth_provider', provider);
    return user;
  }

  String _nameFromEmail(String email) {
    final handle = email.split('@').first.replaceAll(RegExp(r'[._]'), ' ');
    return handle.isEmpty
        ? 'maeve user'
        : handle.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }

  @override
  Future<AuthUser?> signInWithGoogle({String? email}) => _simulate('google', email: email);

  @override
  Future<AuthUser?> signInWithMicrosoft({String? email}) => _simulate('microsoft', email: email);

  @override
  Future<AuthUser?> signInWithGitHub({String? email}) => _simulate('github', email: email);

  @override
  Future<AuthUser?> signInWithEmail(String email, String password) =>
      _simulate('email', email: email);

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_email');
    await prefs.remove('auth_provider');
  }
}
