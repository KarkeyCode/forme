import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? _busy; // which provider is signing in
  bool _emailMode = false;
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(String provider, Future<bool> Function() action) async {
    setState(() => _busy = provider);
    final ok = await action();
    if (!mounted) return;
    setState(() => _busy = null);
    if (ok) {
      context.go('/customize');
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('That didn\'t work. Give it another go.')));
    }
  }

  Future<void> _google() async {
    final email = await _accountPicker(context, provider: 'google');
    if (email == null || !mounted) return;
    _run('google', () => context.read<AppState>().signInWithGoogle(email: email));
  }

  Future<void> _microsoft() async {
    final email = await _accountPicker(context, provider: 'microsoft');
    if (email == null || !mounted) return;
    _run('microsoft', () => context.read<AppState>().signInWithMicrosoft(email: email));
  }

  Future<void> _github() async {
    final handle = await _accountPicker(context, provider: 'github');
    if (handle == null || !mounted) return;
    _run('github', () => context.read<AppState>().signInWithGitHub(email: handle));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final busy = _busy != null;

    return Scaffold(
      body: BlurBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Spacer(),
              Center(child: MaeveLogo(size: 54, color: context.fg)),
              const SizedBox(height: 22),
              Text('Create Your Account',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: context.fg)),
              const SizedBox(height: 6),
              Text('Sign in to save your progress, points and rewards.',
                  style: TextStyle(fontSize: 15, height: 1.3, color: context.fg.withValues(alpha: 0.6))),
              const SizedBox(height: 28),
              if (!_emailMode) ...[
                _AuthButton(
                  label: 'Continue with Google',
                  icon: _googleIcon(),
                  loading: _busy == 'google',
                  onTap: busy ? null : _google,
                ),
                const SizedBox(height: 12),
                _AuthButton(
                  label: 'Continue with Microsoft',
                  icon: const Icon(Icons.window, size: 22, color: Color(0xFF00A4EF)),
                  loading: _busy == 'microsoft',
                  onTap: busy ? null : _microsoft,
                ),
                const SizedBox(height: 12),
                _AuthButton(
                  label: 'Continue with GitHub',
                  icon: const Icon(Icons.code, size: 22, color: Colors.white),
                  dark: true,
                  loading: _busy == 'github',
                  onTap: busy ? null : _github,
                ),
                const SizedBox(height: 12),
                _AuthButton(
                  label: 'Continue with Email',
                  icon: Icon(Icons.mail_outline, size: 22, color: context.fg),
                  onTap: busy ? null : () => setState(() => _emailMode = true),
                ),
              ] else ...[
                _Field(controller: _email, hint: 'Email', icon: Icons.mail_outline, keyboard: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _Field(controller: _password, hint: 'Password', icon: Icons.lock_outline, obscure: true),
                const SizedBox(height: 16),
                PillButton(
                  _busy == 'email' ? 'Signing in…' : 'Continue',
                  onPressed: busy
                      ? () {}
                      : () {
                          final mail = _email.text.trim();
                          if (!mail.contains('@') || _password.text.length < 4) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Enter a valid email and a 4+ char password')));
                            return;
                          }
                          _run('email', () => s.signInWithEmail(mail, _password.text));
                        },
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: busy ? null : () => setState(() => _emailMode = false),
                    child: Text('Back', style: TextStyle(color: context.fg.withValues(alpha: 0.7))),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Center(
                child: Text('Prototype sign in. No real account is created yet.',
                    style: TextStyle(fontSize: 12, color: context.fg.withValues(alpha: 0.4))),
              ),
              const Spacer(),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _googleIcon() =>
      Image.asset('assets/google_g.png', width: 22, height: 22);
}

/// A Google/Apple-style "choose an account" sheet. In the prototype it collects
/// the account email so the sign-in behaves like a real provider picker.
Future<String?> _accountPicker(BuildContext context, {required String provider}) {
  final isGoogle = provider == 'google';
  final isGithub = provider == 'github';
  final brand = switch (provider) {
    'google' => 'Google',
    'github' => 'GitHub',
    _ => 'Microsoft',
  };
  final accent = isGithub ? const Color(0xFF24292F) : const Color(0xFF1A73E8);
  final controller = TextEditingController();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
          left: 24, right: 24, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (isGoogle)
            Image.asset('assets/google_g.png', width: 24, height: 24)
          else if (isGithub)
            const Icon(Icons.code, color: Color(0xFF24292F), size: 26)
          else
            const Icon(Icons.window, color: Color(0xFF00A4EF), size: 26),
          const SizedBox(width: 10),
          Text('Sign in with $brand',
              style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        const Text('to continue to Forme',
            style: TextStyle(color: Colors.black54, fontSize: 13)),
        const SizedBox(height: 20),
        Text(isGithub ? 'Enter your username' : 'Choose an account',
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          autofocus: true,
          keyboardType: isGithub ? TextInputType.text : TextInputType.emailAddress,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            hintText: isGithub ? 'your username' : (isGoogle ? 'you@gmail.com' : 'you@outlook.com'),
            hintStyle: const TextStyle(color: Colors.black38),
            prefixIcon: Icon(isGithub ? Icons.alternate_email : Icons.account_circle_outlined,
                color: Colors.black45),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            onPressed: () {
              final input = controller.text.trim();
              if (isGithub) {
                Navigator.pop(ctx, input.isNotEmpty ? input.replaceAll(' ', '') : 'octocat');
              } else {
                Navigator.pop(ctx, input.contains('@') ? input : 'you@${isGoogle ? 'gmail.com' : 'outlook.com'}');
              }
            },
            child: Text(isGithub ? 'Authorize' : 'Continue',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text('Prototype sign in. Your real $brand account is never contacted.',
              style: const TextStyle(color: Colors.black38, fontSize: 11)),
        ),
      ]),
    ),
  );
}

class _AuthButton extends StatelessWidget {
  const _AuthButton(
      {required this.label, required this.icon, this.onTap, this.dark = false, this.loading = false});
  final String label;
  final Widget icon;
  final VoidCallback? onTap;
  final bool dark;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? Colors.black : context.cardColor;
    final fg = dark ? Colors.white : context.fg;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: context.fg.withValues(alpha: 0.12)),
          ),
        ),
        onPressed: onTap,
        child: loading
            ? SizedBox(
                width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                icon,
                const SizedBox(width: 12),
                Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg)),
              ]),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(
      {required this.controller,
      required this.hint,
      required this.icon,
      this.obscure = false,
      this.keyboard});
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: TextStyle(color: context.fg),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.fg.withValues(alpha: 0.4)),
        prefixIcon: Icon(icon, color: context.fg.withValues(alpha: 0.6)),
        filled: true,
        fillColor: context.cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}
