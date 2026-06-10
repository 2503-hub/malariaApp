import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class ScanImageStorage {
  ScanImageStorage._();

  static final ScanImageStorage instance = ScanImageStorage._();

  Future<String> saveImage(XFile image) async {
    try {
      final databasePath = await getDatabasesPath();
      final scansDirectory = Directory(p.join(databasePath, 'scan_images'));
      if (!scansDirectory.existsSync()) {
        scansDirectory.createSync(recursive: true);
      }

      final extension = p.extension(image.path).isEmpty
          ? p.extension(image.name)
          : p.extension(image.path);
      final safeExtension = extension.isEmpty ? '.jpg' : extension;
      final fileName =
          '${DateTime.now().microsecondsSinceEpoch}_${_safeName(image.name)}$safeExtension';
      final savedPath = p.join(scansDirectory.path, fileName);

      await File(image.path).copy(savedPath);
      return savedPath;
    } catch (_) {
      return image.path;
    }
  }

  String _safeName(String name) {
    final baseName = p.basenameWithoutExtension(name).trim();
    if (baseName.isEmpty) return 'scan';
    return baseName.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  }
}
