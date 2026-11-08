import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import 'avatar_io.dart' if (dart.library.html) 'avatar_web.dart';

/// Resolves a saved local photo path to an [ImageProvider] that works on both
/// Android (file path) and web (blob URL). Returns null when no photo is set.
ImageProvider? avatarProvider(String path) =>
    path.isEmpty ? null : avatarImage(path);

/// Opens the device gallery and returns the chosen image's path (a blob URL on
/// web), or null if the user cancelled.
Future<String?> pickGalleryImage() async {
  final x = await ImagePicker()
      .pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
  return x?.path;
}
