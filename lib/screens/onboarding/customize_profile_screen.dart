import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Capitalises the first letter of each word as the user types — used for the
/// name fields so profile text reads with capitalised first letters.
class _TitleCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldV, TextEditingValue newV) {
    final text = newV.text
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
    return newV.copyWith(
        text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

class CustomizeProfileScreen extends StatefulWidget {
  const CustomizeProfileScreen({super.key});
  @override
  State<CustomizeProfileScreen> createState() => _CustomizeProfileScreenState();
}

class _CustomizeProfileScreenState extends State<CustomizeProfileScreen> {
  final _nickname = TextEditingController();
  final _legalName = TextEditingController();
  final _username = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = context.read<AppState>().profile;
    _nickname.text = p.nickname.isNotEmpty ? p.nickname : p.name;
    _legalName.text = p.legalName.isNotEmpty ? p.legalName : p.name;
    if (p.username.isNotEmpty) _username.text = p.username;
  }

  @override
  void dispose() {
    _nickname.dispose();
    _legalName.dispose();
    _username.dispose();
    super.dispose();
  }

  void _continue() {
    final p = context.read<AppState>().profile;
    p
      ..nickname = _nickname.text.trim()
      ..legalName = _legalName.text.trim()
      ..username = _username.text.trim().replaceAll(' ', '');
    context.read<AppState>().saveProfile(p);
    context.go('/sync');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<AppState>().profile;

    return Scaffold(
      body: BlurBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Customize Your Profile',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: context.fg)),
              const SizedBox(height: 6),
              Text('This is how you\'ll appear in Maeve. You can change it anytime.',
                  style: TextStyle(fontSize: 14, height: 1.3, color: context.fg.withValues(alpha: 0.6))),
              const SizedBox(height: 22),
              Center(
                child: Column(children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: context.fg,
                    child: MaeveLogo(size: 30, color: context.isDark ? Colors.black : Colors.white),
                  ),
                  const SizedBox(height: 8),
                  if (p.email.isNotEmpty)
                    Text(p.email, style: TextStyle(fontSize: 13, color: context.fg.withValues(alpha: 0.55))),
                ]),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: ListView(children: [
                  _label(context, 'Nickname'),
                  _field(_nickname, 'What should we call you?', Icons.badge_outlined, title: true),
                  const SizedBox(height: 16),
                  _label(context, 'Legal Name'),
                  _field(_legalName, 'Your full name', Icons.person_outline, title: true),
                  const SizedBox(height: 16),
                  _label(context, 'Username'),
                  _field(_username, 'maeve_user', Icons.alternate_email,
                      formatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))]),
                  const SizedBox(height: 8),
                  Text('Your username is unique and how friends find you.',
                      style: TextStyle(fontSize: 12, color: context.fg.withValues(alpha: 0.45))),
                ]),
              ),
              PillButton('Continue', onPressed: _continue),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.fg.withValues(alpha: 0.7))),
      );

  Widget _field(TextEditingController c, String hint, IconData icon,
          {bool title = false, List<TextInputFormatter>? formatters}) =>
      TextField(
        controller: c,
        textCapitalization: title ? TextCapitalization.words : TextCapitalization.none,
        inputFormatters: title ? [_TitleCaseFormatter()] : formatters,
        style: TextStyle(color: context.fg, fontSize: 16, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: context.fg.withValues(alpha: 0.4), fontWeight: FontWeight.w400),
          prefixIcon: Icon(icon, color: context.fg.withValues(alpha: 0.6)),
          filled: true,
          fillColor: context.cardColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      );
}
