import 'package:flutter/foundation.dart';

import '../models/scan_history.dart';
import '../repositories/scan_history_repository.dart';

class ScanHistoryController extends ChangeNotifier {
  final ScanHistoryRepository _repository;

  ScanHistoryController({
    ScanHistoryRepository? repository,
  }) : _repository = repository ?? ScanHistoryRepository();

  final List<ScanHistory> _scans = [];
  String _searchQuery = '';
  String _filter = 'All';
  bool _isLoading = false;
  String? _errorMessage;

  List<ScanHistory> get scans => List.unmodifiable(_scans);
  String get searchQuery => _searchQuery;
  String get filter => _filter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadScans() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loadedScans = await _repository.getScans(
        searchQuery: _searchQuery,
        filter: _filter,
      );
      _scans
        ..clear()
        ..addAll(loadedScans);
    } catch (_) {
      _errorMessage = 'Unable to load scan history.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSearch(String query) async {
    _searchQuery = query;
    await loadScans();
  }

  Future<void> updateFilter(String filter) async {
    _filter = filter;
    await loadScans();
  }

  Future<void> deleteScan(ScanHistory scan) async {
    await _repository.deleteScan(scan);
    await loadScans();
  }

  Future<void> clearAll() async {
    await _repository.clearScans();
    await loadScans();
  }
}
