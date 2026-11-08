import 'dart:io';
import 'dart:typed_data';

/// Writes the cropped PNG to a temp file and returns its path (Android/iOS).
Future<String> saveCroppedBytes(Uint8List bytes) async {
  final f = File('${Directory.systemTemp.path}/forme_avatar_${DateTime.now().millisecondsSinceEpoch}.png');
  await f.writeAsBytes(bytes, flush: true);
  return f.path;
}
