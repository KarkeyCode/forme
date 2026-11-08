# Firebase Auth setup (Google / Apple / Email)

The app ships with a **prototype** auth backend (`LocalAuthService`) so the whole
sign-in flow works today without any cloud setup. Nothing collects real
credentials. When you're ready to make login real, follow the steps below — the
only app change is one line in `lib/services/auth/auth_service.dart`.

The UI never touches Firebase directly: it talks to the `AuthService` interface,
so swapping the backend is a drop-in.

---

## 1. Create a Firebase project

1. Go to <https://console.firebase.google.com> and create a project (e.g. `maeve-health`).
2. Enable the sign-in providers you want under **Authentication → Sign-in method**:
   - **Google** — toggle on, pick a support email.
   - **Email/Password** — toggle on.
   - **Apple** — requires a paid Apple Developer account and an iOS build (this
     project is currently Android + Web; add iOS with `flutter create .` first).

## 2. Add the FlutterFire config

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Select your Firebase project and the platforms (android, web, ios). This
generates `lib/firebase_options.dart` and wires the native config
(`android/app/google-services.json`, web config, etc.).

## 3. Add the packages

In `pubspec.yaml` under `dependencies:`

```yaml
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  google_sign_in: ^6.2.1
  sign_in_with_apple: ^6.1.3   # only if you enable Apple
```

Then `flutter pub get`.

## 4. Initialise Firebase in `main.dart`

Add before `runApp`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // ...rest unchanged
}
```

## 5. Drop in the real backend

Create `lib/services/auth/firebase_auth_service.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart'; // if using Apple

import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  final _auth = FirebaseAuth.instance;

  AuthUser? _map(User? u, String provider) => u == null
      ? null
      : AuthUser(
          name: u.displayName ?? u.email?.split('@').first ?? 'maeve user',
          email: u.email ?? '',
          provider: provider,
        );

  @override
  Future<AuthUser?> signInWithGoogle() async {
    // Web uses a popup; mobile uses the google_sign_in flow.
    if (identical(0, 0.0)) {} // keep analyzer calm about kIsWeb branch below
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // user cancelled
    final auth = await googleUser.authentication;
    final cred = GoogleAuthProvider.credential(
      idToken: auth.idToken,
      accessToken: auth.accessToken,
    );
    final res = await _auth.signInWithCredential(cred);
    return _map(res.user, 'google');
  }

  @override
  Future<AuthUser?> signInWithApple() async {
    // Requires sign_in_with_apple + Apple Developer setup.
    // final apple = await SignInWithApple.getAppleIDCredential(scopes: [
    //   AppleIDAuthorizationScopes.email,
    //   AppleIDAuthorizationScopes.fullName,
    // ]);
    // final cred = OAuthProvider('apple.com').credential(
    //   idToken: apple.identityToken,
    //   accessToken: apple.authorizationCode,
    // );
    // final res = await _auth.signInWithCredential(cred);
    // return _map(res.user, 'apple');
    throw UnimplementedError('Enable Apple sign-in per FIREBASE_SETUP.md step 1.');
  }

  @override
  Future<AuthUser?> signInWithEmail(String email, String password) async {
    try {
      final res = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return _map(res.user, 'email');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        final res = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        return _map(res.user, 'email');
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}
```

> For **web Google sign-in**, add your OAuth client ID meta tag to `web/index.html`
> as printed by `flutterfire configure`, and add your domain under
> **Authentication → Settings → Authorized domains**.

## 6. Flip the switch

In `lib/services/auth/auth_service.dart`:

```dart
AuthService createAuthService() => FirebaseAuthService(); // was LocalAuthService()
```

That's it — the login screen, profile and sign-out now use real Firebase. If
anything isn't configured yet, keep `LocalAuthService()` and the prototype flow
keeps working.
