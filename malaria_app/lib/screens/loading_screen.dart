import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/detection_result.dart';
import '../models/scan_history.dart';
import '../repositories/scan_history_repository.dart';
import '../services/scan_image_storage.dart';
import 'result_screen.dart';
import '../services/ai_service.dart';

class LoadingScreen extends StatefulWidget {
  final XFile image;

  const LoadingScreen({super.key, required this.image});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final ScanHistoryRepository _historyRepository = ScanHistoryRepository();
  final ScanImageStorage _imageStorage = ScanImageStorage.instance;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    analyze();
  }

  Future<void> analyze() async {
    setState(() {
      errorMessage = null;
    });

    try {
      final DetectionResult result = await AIService.predict(widget.image);
      final storedImage = await _imageStorage.saveImage(widget.image);

      await _historyRepository.saveScan(
        ScanHistory(
          scannedAt: DateTime.now(),
          imagePath: storedImage.path,
          isLocalCopy: storedImage.isLocalCopy,
          prediction: result.prediction,
          confidence: result.confidence,
          detectionMode: result.mode,
        ),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            image: widget.image,
            label: result.prediction,
            confidence: result.confidence,
            detectionMode: result.mode,
            processingTimeMs: result.processingTimeMs,
            detail: result.detail,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analyzing')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (errorMessage == null) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 22),
                const Text(
                  'Analyzing blood smear image...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please wait while the on-device model checks the selected sample.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ] else ...[
                const Icon(
                  Icons.error_outline,
                  size: 54,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You can retry after checking the image or model file on the device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: analyze,
                  child: const Text('Try Again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
