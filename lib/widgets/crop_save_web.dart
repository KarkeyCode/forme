import 'dart:convert';
import 'dart:typed_data';

/// On web there's no filesystem, so return a data URL that NetworkImage can load.
Future<String> saveCroppedBytes(Uint8List bytes) async =>
    'data:image/png;base64,${base64Encode(bytes)}';
