import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../models/detection_result.dart';
import '../models/scan_history.dart';
import '../repositories/scan_history_repository.dart';
import 'ai_service.dart';

class OfflineAnalysisSyncService {
  OfflineAnalysisSyncService._();

  static final OfflineAnalysisSyncService instance =
      OfflineAnalysisSyncService._();

  final ScanHistoryRepository _repository = ScanHistoryRepository();
  bool _syncing = false;

  Future<int> syncPendingAnalyses() async {
    if (_syncing) return 0;

    _syncing = true;
    var syncedCount = 0;

    try {
      final pendingScans = await _repository.getPendingScans();
      for (final scan in pendingScans) {
        final imageFile = File(scan.imagePath);
        if (!await imageFile.exists()) {
          await _repository.updateScan(
            scan.copyWith(
              analysisStatus: ScanAnalysisStatus.failed,
              analysisError: 'Saved image file is missing.',
            ),
          );
          continue;
        }

        try {
          final DetectionResult result = await AIService.predict(
            XFile(scan.imagePath),
          );

          await _repository.updateScan(
            scan.copyWith(
              prediction: result.prediction,
              confidence: result.confidence,
              detectionMode: result.mode,
              analysisStatus: ScanAnalysisStatus.completed,
              analysisError: null,
            ),
          );
          syncedCount++;
        } catch (error) {
          final message = error.toString().replaceFirst('Exception: ', '');
          if (_isConnectivityProblem(message)) {
            break;
          }

          await _repository.updateScan(
            scan.copyWith(
              analysisStatus: ScanAnalysisStatus.failed,
              analysisError: message,
            ),
          );
        }
      }
    } finally {
      _syncing = false;
    }

    return syncedCount;
  }

  bool _isConnectivityProblem(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('unable to reach') ||
        normalized.contains('timed out') ||
        normalized.contains('connection');
  }
}
