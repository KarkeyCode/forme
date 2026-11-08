import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme.dart';

class ProScreen extends StatefulWidget {
  const ProScreen({super.key});
  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  bool _yearly = true;
  bool _trial = true;

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    Widget tile(IconData icon, Color c, String text) => Expanded(
          child: Container(
            height: 96,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: c, size: 20),
              const Spacer(),
              Text(text, style: const TextStyle(color: white, fontSize: 12, height: 1.2)),
            ]),
          ),
        );

    Widget plan(bool yearly, String label, String price) {
      final sel = _yearly == yearly;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _yearly = yearly),
          child: Stack(clipBehavior: Clip.none, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 64,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? MaeveColors.proGreen.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sel ? const Color(0xFF3FBF8A) : Colors.white12, width: 1.4),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: price,
                      style: const TextStyle(color: white, fontSize: 20, fontWeight: FontWeight.w700)),
                  const TextSpan(text: ' AUD/mo', style: TextStyle(color: Colors.white60, fontSize: 11)),
                ])),
              ]),
            ),
            if (yearly)
              Positioned(
                right: 6,
                top: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(10)),
                  child: const Text('save 51%',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: MaeveColors.ink)),
                ),
              ),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.4, -0.2),
            radius: 1.0,
            colors: [Color(0xFF2A1F3A), Color(0xFF0E0E0E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('maeve health',
                    style: TextStyle(color: white, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                  child: const Text('PRO',
                      style: TextStyle(color: white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close, color: white),
                  style: IconButton.styleFrom(backgroundColor: Colors.white12),
                ),
              ]),
              const SizedBox(height: 24),
              const Text('commit to your',
                  style: TextStyle(color: Colors.white54, fontSize: 30, fontWeight: FontWeight.w700, height: 1.1)),
              const Text('best self.',
                  style: TextStyle(color: white, fontSize: 30, fontWeight: FontWeight.w700, height: 1.1)),
              const SizedBox(height: 24),
              Row(children: [
                tile(Icons.show_chart, const Color(0xFF3FBF8A), 'full history &\ninsights'),
                const SizedBox(width: 10),
                tile(Icons.auto_awesome, const Color(0xFFB57BEA), 'unlimited ai diet\nguidance'),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                tile(Icons.dashboard_customize_outlined, const Color(0xFF3FBF8A),
                    'customisable app\ninterface and icons'),
                const SizedBox(width: 10),
                tile(Icons.notifications_active_outlined, const Color(0xFFB57BEA), 'custom reminders'),
              ]),
              const SizedBox(height: 22),
              Row(children: [
                plan(false, 'monthly', '\$5.98'),
                const SizedBox(width: 10),
                plan(true, 'yearly', '\$2.92'),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                const Text('Activate Free Trial', style: TextStyle(color: white, fontSize: 14)),
                const Spacer(),
                Switch(
                  value: _trial,
                  activeTrackColor: const Color(0xFF3FBF8A),
                  onChanged: (v) => setState(() => _trial = v),
                ),
              ]),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: white, foregroundColor: MaeveColors.ink, shape: const StadiumBorder()),
                  onPressed: () {
                    context.read<AppState>().setPro(true);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Welcome to maeve PRO (demo — no payment taken)')));
                    context.pop();
                  },
                  child: Text(_trial ? 'Start Free Trial' : 'Join Now',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Remind me Later', style: TextStyle(color: Colors.white60)),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text("Don't Show Again", style: TextStyle(color: MaeveColors.red)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
