import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme.dart';
import '../../widgets/common.dart';

/// Swipeable onboarding intro. Four informational pages the user can swipe
/// between (brand → what Forme is → how it works → your data is safe), then
/// "Get Started" hands off to the real sign-in flow.
class OnboardingCarousel extends StatefulWidget {
  const OnboardingCarousel({super.key});
  @override
  State<OnboardingCarousel> createState() => _OnboardingCarouselState();
}

class _OnboardingCarouselState extends State<OnboardingCarousel> {
  final _pc = PageController();
  int _page = 0;
  static const _last = 3;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_page >= _last) {
      context.go('/login');
    } else {
      _pc.nextPage(duration: const Duration(milliseconds: 360), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlurBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Skip (hidden on the last page)
              SizedBox(
                height: 44,
                child: AnimatedOpacity(
                  opacity: _page == _last ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: TextButton(
                        onPressed: _page == _last ? null : () => context.go('/login'),
                        child: Text('Skip',
                            style: TextStyle(fontSize: 15, color: context.fg.withValues(alpha: 0.6))),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pc,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: const [
                    _BrandPage(),
                    _CompanionPage(),
                    _HowPage(),
                    _SecurityPage(),
                  ],
                ),
              ),
              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i <= _last; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? context.fg : context.fg.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
                child: PillButton(_page == _last ? 'Get Started' : 'Next', onPressed: _next),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared page scaffold: art on top, heading + body below.
class _Page extends StatelessWidget {
  const _Page({required this.art, required this.title, required this.body});
  final Widget art;
  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Center(child: art)),
          Text(title,
              style: TextStyle(fontSize: 30, height: 1.1, fontWeight: FontWeight.w700, color: context.fg)),
          const SizedBox(height: 12),
          DefaultTextStyle(
            style: TextStyle(fontSize: 17, height: 1.4, color: context.fg.withValues(alpha: 0.65)),
            child: body,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _BrandPage extends StatelessWidget {
  const _BrandPage();
  @override
  Widget build(BuildContext context) {
    return _Page(
      art: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: context.fg,
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(color: context.fg.withValues(alpha: 0.25), blurRadius: 40, spreadRadius: 2),
              ],
            ),
            child: Center(
              child: MaeveLogo(size: 58, color: context.isDark ? Colors.black : Colors.white),
            ),
          ),
          const SizedBox(height: 26),
          Text('FORME',
              style: TextStyle(
                  fontSize: 46, letterSpacing: 6, fontWeight: FontWeight.w800, color: context.fg)),
        ],
      ),
      title: 'Welcome To Forme',
      body: const Text('Your health, in shape. Swipe to see what Forme can do for you.'),
    );
  }
}

class _CompanionPage extends StatelessWidget {
  const _CompanionPage();
  @override
  Widget build(BuildContext context) {
    Widget feature(IconData icon, String label) => Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.fg.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.fg.withValues(alpha: 0.1)),
              ),
              child: Icon(icon, color: context.fg, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, color: context.fg.withValues(alpha: 0.7))),
          ],
        );

    return _Page(
      art: Wrap(
        spacing: 22,
        runSpacing: 22,
        alignment: WrapAlignment.center,
        children: [
          feature(Icons.directions_walk, 'Track'),
          feature(Icons.restaurant_menu, 'Eat'),
          feature(Icons.fitness_center, 'Train'),
          feature(Icons.card_giftcard, 'Earn'),
        ],
      ),
      title: 'Your New\nHealth Companion',
      body: const Text('Track your day, plan your meals and follow workouts built around your goals. Stay consistent and earn rewards while you are at it.'),
    );
  }
}

class _HowPage extends StatelessWidget {
  const _HowPage();
  @override
  Widget build(BuildContext context) {
    return const _Page(
      art: _PhoneMock(),
      title: 'How It Works',
      body: Text('Forme quietly reads your health data and turns it into a clear picture of your day. No spreadsheets, no fuss.'),
    );
  }
}

class _SecurityPage extends StatelessWidget {
  const _SecurityPage();
  @override
  Widget build(BuildContext context) {
    Widget point(IconData icon, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.fg.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: context.fg, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.fg)),
                const SizedBox(height: 2),
                Text(body, style: TextStyle(fontSize: 12.5, height: 1.3, color: context.fg.withValues(alpha: 0.6))),
              ]),
            ),
          ]),
        );

    return _Page(
      art: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: context.fg.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Icon(Icons.verified_user_outlined, color: context.fg, size: 48),
      ),
      title: 'Your Data Is Safe',
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Your health is personal, and we treat it that way. Here is how we keep it safe.'),
        const SizedBox(height: 16),
        point(Icons.lock_outline, 'End-To-End Encryption',
            'Encrypted on the way and while it sits on your device, so only you can read it.'),
        point(Icons.block, 'Never Sold, Never Shared',
            'We never sell or share your personal data with anyone. Ever.'),
        point(Icons.phonelink_lock_outlined, 'You Stay In Control',
            'Your data stays on your device and private account. Delete it anytime.'),
      ]),
    );
  }
}

/// A theme-cohesive phone mockup that sits cleanly on the blurred backdrop —
/// a dark frame with a miniature Forme dashboard on its screen.
class _PhoneMock extends StatelessWidget {
  const _PhoneMock();

  @override
  Widget build(BuildContext context) {
    final screenBg = context.isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF4F4F6);
    final cardBg = context.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;
    final ink = context.fg;

    Widget bar(double h, double w, Color c) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
        );

    return Transform.rotate(
      angle: -0.05,
      child: Container(
        width: 184,
        height: 300,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E10),
          borderRadius: BorderRadius.circular(38),
          border: Border.all(color: const Color(0xFF2A2A2E), width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 36, offset: const Offset(0, 18)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            color: screenBg,
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // notch pill
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                        color: ink.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(3)),
                  ),
                ),
                const SizedBox(height: 14),
                Text('FORME',
                    style: TextStyle(
                        fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.w800, color: ink)),
                const SizedBox(height: 12),
                // step ring card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    SizedBox(
                      width: 46,
                      height: 46,
                      child: CircularProgressIndicator(
                        value: 0.68,
                        strokeWidth: 6,
                        backgroundColor: ink.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(ink.withValues(alpha: 0.85)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('8,204',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
                      Text('steps today',
                          style: TextStyle(fontSize: 10, color: ink.withValues(alpha: 0.5))),
                    ]),
                  ]),
                ),
                const SizedBox(height: 10),
                // mini bar chart card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      bar(20, 10, ink.withValues(alpha: 0.25)),
                      bar(34, 10, ink.withValues(alpha: 0.4)),
                      bar(26, 10, ink.withValues(alpha: 0.3)),
                      bar(44, 10, ink.withValues(alpha: 0.7)),
                      bar(30, 10, ink.withValues(alpha: 0.4)),
                      bar(48, 10, ink.withValues(alpha: 0.8)),
                      bar(38, 10, ink.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
                const Spacer(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  Icon(Icons.home_rounded, size: 18, color: ink),
                  Icon(Icons.eco_outlined, size: 18, color: ink.withValues(alpha: 0.4)),
                  Icon(Icons.fitness_center, size: 18, color: ink.withValues(alpha: 0.4)),
                  Icon(Icons.person_outline, size: 18, color: ink.withValues(alpha: 0.4)),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
