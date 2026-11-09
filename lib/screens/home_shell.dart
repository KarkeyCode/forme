import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/haptics.dart';
import '../theme.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with TickerProviderStateMixin {
  late final _menu =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
  // Drives the slide-in when moving between tabs.
  late final _slide =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 300), value: 1);
  int _lastIndex = 0;
  double _dir = 1;

  bool get _open => _menu.status == AnimationStatus.completed || _menu.status == AnimationStatus.forward;

  void _toggle() {
    Haptics.select();
    _open ? _menu.reverse() : _menu.forward();
  }

  void _go(int i) {
    Haptics.light();
    _menu.reverse();
    widget.shell.goBranch(i, initialLocation: i == widget.shell.currentIndex);
  }

  // Swipe left/right on the page body to move between adjacent tabs.
  void _onSwipe(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    final idx = widget.shell.currentIndex;
    if (v < -280 && idx < 3) {
      Haptics.select();
      _go(idx + 1);
    } else if (v > 280 && idx > 0) {
      Haptics.select();
      _go(idx - 1);
    }
  }

  @override
  void dispose() {
    _menu.dispose();
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navBg = context.isDark ? const Color(0xFF1B1B1B) : Colors.white;
    final idx = widget.shell.currentIndex;
    // Trigger a slide-in whenever the active tab changes.
    if (idx != _lastIndex) {
      _dir = idx > _lastIndex ? 1 : -1;
      _lastIndex = idx;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _slide.forward(from: 0);
      });
    }
    // Scale the bar to the device width so it feels right on small and large phones.
    final ns = (MediaQuery.sizeOf(context).width / 390).clamp(0.9, 1.14);
    Widget tab(int i, IconData icon, String label) => Expanded(
          child: InkResponse(
            onTap: () => _go(i),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 24 * ns, color: idx == i ? context.fg : MaeveColors.muted),
              SizedBox(height: 2 * ns),
              Text(label,
                  style: TextStyle(
                      fontSize: 11 * ns,
                      fontWeight: idx == i ? FontWeight.w600 : FontWeight.w400,
                      color: idx == i ? context.fg : MaeveColors.muted)),
            ]),
          ),
        );

    return Scaffold(
      body: Stack(children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: _onSwipe,
          child: AnimatedBuilder(
            animation: _slide,
            builder: (_, child) {
              final t = Curves.easeOutCubic.transform(_slide.value);
              return Opacity(
                opacity: 0.35 + 0.65 * t,
                child: Transform.translate(offset: Offset((1 - t) * _dir * 46, 0), child: child),
              );
            },
            child: widget.shell,
          ),
        ),
        // dim + close when the radial menu is open
        AnimatedBuilder(
          animation: _menu,
          builder: (_, __) => _menu.value == 0
              ? const SizedBox()
              : GestureDetector(
                  onTap: _toggle,
                  child: Container(color: Colors.black.withValues(alpha: 0.18 * _menu.value)),
                ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _RadialMenu(
            anim: _menu,
            onDiet: () => _go(1),
            onWorkout: () => _go(2),
            onOverview: () {
              Haptics.light();
              _menu.reverse();
              context.push('/overview');
            },
          ),
        ),
      ]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: context.fg.withValues(alpha: 0.12), width: 1)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.06), blurRadius: 12, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64 * ns,
            child: Row(children: [
              tab(0, Icons.home_outlined, 'Home'),
              tab(1, Icons.eco_outlined, 'Diet'),
              Expanded(
                child: Transform.translate(
                  offset: Offset(0, -18 * ns),
                  child: Center(
                    child: GestureDetector(
                      onTap: _toggle,
                      child: Container(
                        width: 52 * ns,
                        height: 52 * ns,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.fg,
                          boxShadow: [BoxShadow(color: context.fg.withValues(alpha: 0.3), blurRadius: 12, spreadRadius: 1)],
                        ),
                        child: AnimatedBuilder(
                          animation: _menu,
                          builder: (_, __) => Transform.rotate(
                            angle: _menu.value * math.pi / 4,
                            child: Icon(Icons.add, size: 30 * ns, color: navBg),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              tab(2, Icons.fitness_center, 'Workout'),
              tab(3, Icons.account_circle_outlined, 'Profile'),
            ]),
          ),
        ),
      ),
    );
  }
}

class _RadialMenu extends StatelessWidget {
  const _RadialMenu({required this.anim, required this.onDiet, required this.onWorkout, required this.onOverview});
  final Animation<double> anim;
  final VoidCallback onDiet, onWorkout, onOverview;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.restaurant_menu, onDiet, 'Diet'),
      (Icons.fitness_center, onWorkout, 'Workout'),
      (Icons.monitor_heart_outlined, onOverview, 'Health'),
    ];
    final bg = context.isDark ? const Color(0xFF262626) : Colors.white;
    return SizedBox(
      height: 180,
      child: AnimatedBuilder(
        animation: anim,
        builder: (context, _) {
          final v = Curves.easeOutBack.transform(anim.value.clamp(0, 1));
          if (anim.value == 0) return const SizedBox();
          return Stack(alignment: Alignment.bottomCenter, children: [
            for (var i = 0; i < items.length; i++)
              Builder(builder: (context) {
                final angle = math.pi * (0.82 - i * 0.32); // left -> right fan
                const r = 94.0;
                final dx = math.cos(angle) * r * v;
                final dy = math.sin(angle) * r * v;
                return Positioned(
                  bottom: 6 + dy,
                  left: MediaQuery.of(context).size.width / 2 - 32 + dx,
                  child: Opacity(
                    opacity: anim.value,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Material(
                        color: bg,
                        shape: CircleBorder(side: BorderSide(color: context.fg.withValues(alpha: 0.12), width: 1)),
                        elevation: 4,
                        shadowColor: Colors.black.withValues(alpha: 0.3),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: items[i].$2,
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Icon(items[i].$1, color: context.fg, size: 24, semanticLabel: items[i].$3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(items[i].$3,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: context.fg)),
                    ]),
                  ),
                );
              }),
          ]);
        },
      ),
    );
  }
}
