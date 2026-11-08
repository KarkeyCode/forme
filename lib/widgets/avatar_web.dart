import 'package:flutter/widgets.dart';

// On web, image_picker returns a blob URL that NetworkImage can load.
ImageProvider avatarImage(String path) => NetworkImage(path);
