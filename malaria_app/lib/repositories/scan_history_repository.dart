import 'dart:io';

import '../data/scan_history_database.dart';
import '../models/scan_history.dart';

class ScanHistoryRepository {
  final ScanHistoryDatabase _database;

  ScanHistoryRepository({
    ScanHistoryDatabase? database,
  }) : _database = database ?? ScanHistoryDatabase.instance;

  Future<void> saveScan(ScanHistory scan) async {
    await _database.insertScan(scan);
  }

  Future<List<ScanHistory>> getScans({
    String searchQuery = '',
    String filter = 'All',
  }) {
    return _database.getScans(searchQuery: searchQuery, filter: filter);
  }

  Future<void> deleteScan(ScanHistory scan) async {
    final id = scan.id;
    if (id == null) return;

    await _database.deleteScan(id);
    await _deleteImageFile(scan.imagePath);
  }

  Future<void> clearScans() async {
    final scans = await _database.getScans();
    await _database.clearScans();

    for (final scan in scans) {
      await _deleteImageFile(scan.imagePath);
    }
  }

  Future<void> _deleteImageFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
