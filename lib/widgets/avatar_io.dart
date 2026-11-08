import 'dart:io';

import 'package:flutter/widgets.dart';

ImageProvider avatarImage(String path) => FileImage(File(path));
