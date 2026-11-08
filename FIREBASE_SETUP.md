# Firebase Auth setup (Google / Microsoft / GitHub / Email)

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
   - **GitHub** — toggle on, then paste the Client ID + Client secret from a
     GitHub OAuth App (see "GitHub sign-in" at the bottom of this file).
   - **Microsoft** — toggle on, then paste the Application (client) ID + a
     client secret from an Azure AD app registration. Add the Firebase redirect
     URI to the Azure app's "Web" platform.

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
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  Future<AuthUser?> signInWithGoogle({String? email}) async {
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
  Future<AuthUser?> signInWithMicrosoft({String? email}) async {
    // Federated web sign-in via Azure AD. Enable Microsoft in Firebase first.
    final provider = OAuthProvider('microsoft.com');
    // provider.setCustomParameters({'tenant': '<your-tenant-or-common>'});
    final res = kIsWeb
        ? await _auth.signInWithPopup(provider)
        : await _auth.signInWithProvider(provider);
    return _map(res.user, 'microsoft');
  }

  @override
  Future<AuthUser?> signInWithGitHub({String? email}) async {
    // Federated web sign-in. On Android this opens a secure Chrome Custom Tab
    // and handles the GitHub login + callback automatically; on web it uses a
    // popup. `email` (the prototype username) is ignored — GitHub supplies the
    // identity.
    final provider = GithubAuthProvider();
    // provider.addScope('read:user'); // add scopes if you need GitHub data
    final res = kIsWeb
        ? await _auth.signInWithPopup(provider)
        : await _auth.signInWithProvider(provider);
    return _map(res.user, 'github');
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

---

## GitHub sign-in

The app already shows a **Continue with GitHub** button (prototype). To make it
real, GitHub's OAuth sits behind Firebase's `GithubAuthProvider`, so no extra
Flutter package is needed — just `firebase_auth` (already added above).

### 1. Register a GitHub OAuth App

1. GitHub → **Settings → Developer settings → OAuth Apps → New OAuth App**.
2. **Homepage URL**: anything (e.g. your site or `https://forme.app`).
3. **Authorization callback URL**: copy this from Firebase Console →
   **Authentication → Sign-in method → GitHub** (it looks like
   `https://<your-project>.firebaseapp.com/__/auth/handler`).
4. Create the app and note the **Client ID** and generate a **Client secret**.

### 2. Enable GitHub in Firebase

Firebase Console → **Authentication → Sign-in method → GitHub** → toggle on,
paste the **Client ID** and **Client secret**, and save.

### 3. Android specifics

- `signInWithProvider` opens a Chrome Custom Tab, so make sure the GitHub
  provider's callback domain is listed under **Authentication → Settings →
  Authorized domains**.
- If you hit `missing-client-identifier`, re-download
  `android/app/google-services.json` after enabling the provider (and after
  adding your release/debug **SHA-1** fingerprint under Project Settings → Your
  apps). Get the SHA-1 with:

  ```bash
  cd android && ./gradlew signingReport
  ```

### 4. Web specifics

On web the code uses `signInWithPopup` instead of `signInWithProvider`. Add your
domain under **Authentication → Settings → Authorized domains**, and make sure
popups aren't blocked.

The `signInWithGitHub` method is already in the `FirebaseAuthService` example in
step 5 — once the provider is enabled, the existing GitHub button just works.
