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
      context.go('/sync');
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not sign in — try again')));
    }
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
              Text('create your account',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: context.fg)),
              const SizedBox(height: 6),
              Text('sign in to save your progress, points and rewards.',
                  style: TextStyle(fontSize: 15, height: 1.3, color: context.fg.withValues(alpha: 0.6))),
              const SizedBox(height: 28),
              if (!_emailMode) ...[
                _AuthButton(
                  label: 'Continue with Google',
                  icon: _googleIcon(),
                  loading: _busy == 'google',
                  onTap: busy ? null : () => _run('google', s.signInWithGoogle),
                ),
                const SizedBox(height: 12),
                _AuthButton(
                  label: 'Continue with Apple',
                  icon: const Icon(Icons.apple, size: 22, color: Colors.white),
                  dark: true,
                  loading: _busy == 'apple',
                  onTap: busy ? null : () => _run('apple', s.signInWithApple),
                ),
                const SizedBox(height: 12),
                _AuthButton(
                  label: 'Continue with Email',
                  icon: Icon(Icons.mail_outline, size: 22, color: context.fg),
                  onTap: busy ? null : () => setState(() => _emailMode = true),
                ),
              ] else ...[
                _Field(controller: _email, hint: 'email', icon: Icons.mail_outline, keyboard: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _Field(controller: _password, hint: 'password', icon: Icons.lock_outline, obscure: true),
                const SizedBox(height: 16),
                PillButton(
                  _busy == 'email' ? 'signing in…' : 'continue',
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
                    child: Text('back', style: TextStyle(color: context.fg.withValues(alpha: 0.7))),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Center(
                child: Text('prototype — no real account is created yet',
                    style: TextStyle(fontSize: 12, color: context.fg.withValues(alpha: 0.4))),
              ),
              const Spacer(),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _googleIcon() => Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        child: const Text('G',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF4285F4))),
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
