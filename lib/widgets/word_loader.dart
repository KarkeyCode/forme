import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';

/// A "loading <word>" loader where the word scrolls vertically through a list
/// (steps, bpm, water levels, workouts, diet). Colours follow the current
/// theme rather than a fixed accent, so it reads well in light and dark.
class WordLoader extends StatefulWidget {
  const WordLoader({
    super.key,
    this.label = 'loading',
    this.words = const ['steps', 'bpm', 'water levels', 'workouts', 'diet'],
    this.fontSize = 24,
  });

  final String label;
  final List<String> words;
  final double fontSize;

  @override
  State<WordLoader> createState() => _WordLoaderState();
}

class _WordLoaderState extends State<WordLoader> {
  int _n = 0; // cumulative index (keeps motion going one direction)
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      if (mounted) setState(() => _n++);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.fontSize * 1.5;
    final muted = context.fg.withValues(alpha: 0.55);
    // Enough copies that the one-directional scroll never runs out mid-view.
    final loops = _n ~/ widget.words.length + 3;
    final items = [for (var i = 0; i < loops; i++) ...widget.words];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: context.isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF3F3F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.fg.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.label,
              style: TextStyle(
                  fontSize: widget.fontSize, fontWeight: FontWeight.w500, color: muted)),
          const SizedBox(width: 10),
          SizedBox(
            height: line,
            child: ShaderMask(
              shaderCallback: (r) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.isDark ? const Color(0xFF141414) : Colors.white,
                  Colors.transparent,
                  Colors.transparent,
                  context.isDark ? const Color(0xFF141414) : Colors.white,
                ],
                stops: const [0.0, 0.28, 0.72, 1.0],
              ).createShader(r),
              blendMode: BlendMode.dstOut,
              child: ClipRect(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeInOut,
                  transform: Matrix4.translationValues(0, -_n * line, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final w in items)
                        SizedBox(
                          height: line,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(w,
                                style: TextStyle(
                                    fontSize: widget.fontSize,
                                    fontWeight: FontWeight.w600,
                                    color: context.fg)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
