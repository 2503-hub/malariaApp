import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../data/scan_history_database.dart';
import '../models/scan_history.dart';

class ScanHistoryRepository {
  final ScanHistoryDatabase _database;

  ScanHistoryRepository({ScanHistoryDatabase? database})
    : _database = database ?? ScanHistoryDatabase.instance;

  Future<void> saveScan(ScanHistory scan) async {
    await _database.insertScan(scan);
  }

  Future<void> updateScan(ScanHistory scan) async {
    await _database.updateScan(scan);
  }

  Future<List<ScanHistory>> getScans({
    String searchQuery = '',
    String filter = 'All',
    ScanAnalysisStatus? analysisStatus,
  }) {
    return _database.getScans(
      searchQuery: searchQuery,
      filter: filter,
      analysisStatus: analysisStatus,
    );
  }

  Future<List<ScanHistory>> getPendingScans() {
    return _database.getScans(analysisStatus: ScanAnalysisStatus.pending);
  }

  Future<void> deleteScan(ScanHistory scan) async {
    final id = scan.id;
    if (id == null) return;

    await _database.deleteScan(id);
    await _deleteImageFile(scan.imagePath, scan.isLocalCopy);
  }

  Future<void> clearScans() async {
    final scans = await _database.getScans();
    await _database.clearScans();

    for (final scan in scans) {
      await _deleteImageFile(scan.imagePath, scan.isLocalCopy);
    }
  }

  Future<void> _deleteImageFile(String path, bool isLocalCopy) async {
    if (!await _shouldDeleteImage(path, isLocalCopy)) return;

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<bool> _shouldDeleteImage(String path, bool isLocalCopy) async {
    if (isLocalCopy) return true;

    final normalizedPath = p.normalize(path);
    final appDocumentsPath = p.normalize(
      p.join((await getApplicationDocumentsDirectory()).path, 'scan_images'),
    );
    final databasePath = p.normalize(
      p.join(await getDatabasesPath(), 'scan_images'),
    );

    return normalizedPath.startsWith(appDocumentsPath) ||
        normalizedPath.startsWith(databasePath);
  }
}
