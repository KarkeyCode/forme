import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;

import '../theme.dart';
import '../widgets/avatar.dart';
import '../widgets/crop_save.dart';

/// Pan + pinch to crop and scale a picked photo into a square avatar.
/// Returns the saved path (file path on mobile, data URL on web), or null.
class AvatarCropScreen extends StatefulWidget {
  const AvatarCropScreen({super.key, required this.sourcePath});
  final String sourcePath;

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  final _boundaryKey = GlobalKey();
  final _controller = TransformationController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final boundary =
          _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        if (mounted) Navigator.pop(context);
        return;
      }
      final path = await saveCroppedBytes(bytes.buffer.asUint8List());
      if (mounted) Navigator.pop(context, path);
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = avatarProvider(widget.sourcePath);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _saving ? null : () => Navigator.pop(context),
              ),
              const Text('Adjust Photo',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            ]),
          ),
          Expanded(
            child: Center(
              child: LayoutBuilder(builder: (context, c) {
                final size = c.maxWidth < c.maxHeight ? c.maxWidth * 0.84 : c.maxHeight * 0.7;
                return ClipOval(
                  child: SizedBox(
                    width: size,
                    height: size,
                    // The captured square. InteractiveViewer gives pan + pinch.
                    child: RepaintBoundary(
                      key: _boundaryKey,
                      child: Container(
                        color: Colors.black,
                        child: InteractiveViewer(
                          transformationController: _controller,
                          minScale: 0.5,
                          maxScale: 5,
                          boundaryMargin: const EdgeInsets.all(double.infinity),
                          clipBehavior: Clip.hardEdge,
                          child: provider == null
                              ? const SizedBox()
                              : Image(image: provider, fit: BoxFit.cover, width: size, height: size),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              const Text('Drag to move · pinch or scroll to zoom',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _saving ? null : () => _controller.value = Matrix4.identity(),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: MaeveColors.ink,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4))
                        : const Text('Use Photo', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Opens the crop screen for [sourcePath] and returns the cropped image path.
Future<String?> cropAvatar(BuildContext context, String sourcePath) {
  return Navigator.of(context).push<String>(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => AvatarCropScreen(sourcePath: sourcePath),
  ));
}
