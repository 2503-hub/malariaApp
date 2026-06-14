import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/batch_prediction.dart';
import '../models/detection_result.dart';
import '../models/scan_history.dart';
import '../repositories/scan_history_repository.dart';
import '../services/ai_service.dart';
import '../services/scan_image_storage.dart';
import '../widgets/picked_image_view.dart';

class BatchAnalysisScreen extends StatefulWidget {
  const BatchAnalysisScreen({super.key});

  @override
  State<BatchAnalysisScreen> createState() => _BatchAnalysisScreenState();
}

class _BatchAnalysisScreenState extends State<BatchAnalysisScreen> {
  final ImagePicker _picker = ImagePicker();
  final ScanHistoryRepository _historyRepository = ScanHistoryRepository();
  final ScanImageStorage _imageStorage = ScanImageStorage.instance;
  final List<XFile> _selectedImages = [];

  BatchPredictionResponse? _batchResponse;
  bool _isUploading = false;
  String? _errorMessage;
  bool _isErrorMessage = true;

  Future<void> _pickImages() async {
    final pickedImages = await _picker.pickMultiImage();
    if (!mounted || pickedImages.isEmpty) return;

    setState(() {
      _selectedImages
        ..clear()
        ..addAll(pickedImages);
      _batchResponse = null;
      _errorMessage = null;
      _isErrorMessage = true;
    });
  }

  Future<void> _analyzeBatch() async {
    if (_selectedImages.isEmpty || _isUploading) return;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _isErrorMessage = true;
      _batchResponse = null;
    });

    try {
      final response = await AIService.predictBatch(_selectedImages);
      await _saveBatchHistory(response);
      if (!mounted) return;

      setState(() {
        _batchResponse = response;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        final message = error.toString().replaceFirst('Exception: ', '');
        _errorMessage = message.isEmpty
            ? 'Unable to complete batch analysis on the device.'
            : message;
        _isErrorMessage = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _saveBatchHistory(BatchPredictionResponse response) async {
    final imagesByName = {
      for (final image in _selectedImages) image.name: image,
    };

    for (var index = 0; index < response.results.length; index++) {
      final result = response.results[index];
      final fallbackImage = index < _selectedImages.length
          ? _selectedImages[index]
          : null;
      final image = imagesByName[result.imageName] ?? fallbackImage;
      final storedImage = image == null
          ? null
          : await _imageStorage.saveImage(image);

      await _historyRepository.saveScan(
        ScanHistory(
          scannedAt: DateTime.now(),
          imagePath: storedImage?.path ?? result.imageName,
          isLocalCopy: storedImage?.isLocalCopy ?? false,
          prediction: result.prediction,
          confidence: result.confidence,
          detectionMode: DetectionMode.offline,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _batchResponse = null;
      _errorMessage = null;
    });
  }

  void _clearImages() {
    setState(() {
      _selectedImages.clear();
      _batchResponse = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final response = _batchResponse;

    return Scaffold(
      appBar: AppBar(title: const Text('Batch Analysis')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickImages,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Select Images'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  onPressed: _selectedImages.isEmpty || _isUploading
                      ? null
                      : _clearImages,
                  icon: const Icon(Icons.delete_sweep),
                  tooltip: 'Clear selected images',
                ),
              ],
            ),
            const SizedBox(height: 18),
            _PreviewSection(
              images: _selectedImages,
              onRemove: _isUploading ? null : _removeImage,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _selectedImages.isEmpty || _isUploading
                  ? null
                  : _analyzeBatch,
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.analytics),
              label: Text(_isUploading ? 'Analyzing...' : 'Analyze Batch'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _StatusMessage(message: _errorMessage!, isError: _isErrorMessage),
            ],
            if (response != null) ...[
              const SizedBox(height: 22),
              _ResultsTable(results: response.results),
              const SizedBox(height: 18),
              _SummaryPanel(summary: response.summary),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewSection extends StatelessWidget {
  final List<XFile> images;
  final ValueChanged<int>? onRemove;

  const _PreviewSection({required this.images, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.collections, size: 48, color: Color(0xFF94A3B8)),
              SizedBox(height: 10),
              Text(
                'No images selected',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${images.length} selected',
          style: const TextStyle(
            color: Color(0xFF334155),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: images.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, index) {
            return _PreviewTile(
              image: images[index],
              onRemove: onRemove == null ? null : () => onRemove!(index),
            );
          },
        ),
      ],
    );
  }
}

class _PreviewTile extends StatelessWidget {
  final XFile image;
  final VoidCallback? onRemove;

  const _PreviewTile({required this.image, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: PickedImageView(image: image)),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton.filled(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 16),
              tooltip: 'Remove image',
              constraints: const BoxConstraints.tightFor(width: 30, height: 30),
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xCC0F172A),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              color: const Color(0xCC0F172A),
              child: Text(
                image.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsTable extends StatelessWidget {
  final List<BatchPrediction> results;

  const _ResultsTable({required this.results});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: const TextStyle(
            color: Color(0xFF334155),
            fontWeight: FontWeight.w800,
          ),
          columns: const [
            DataColumn(label: Text('Image Name')),
            DataColumn(label: Text('Prediction')),
            DataColumn(label: Text('Confidence')),
          ],
          rows: results.map((result) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 180,
                    child: Text(
                      result.imageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(_PredictionChip(prediction: result.prediction)),
                DataCell(Text('${result.confidence.toStringAsFixed(1)}%')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _PredictionChip extends StatelessWidget {
  final String prediction;

  const _PredictionChip({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final color = switch (prediction) {
      'Parasitized' => const Color(0xFFDC2626),
      'Uninfected' => const Color(0xFF16A34A),
      'Uncertain' => const Color(0xFFD97706),
      _ => const Color(0xFF64748B),
    };

    return Text(
      prediction,
      style: TextStyle(color: color, fontWeight: FontWeight.w800),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  final BatchSummary summary;

  const _SummaryPanel({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Total Images', value: '${summary.totalImages}'),
          _SummaryRow(
            label: 'Parasitized Count',
            value: '${summary.parasitizedCount}',
          ),
          _SummaryRow(
            label: 'Uninfected Count',
            value: '${summary.uninfectedCount}',
          ),
          _SummaryRow(
            label: 'Invalid Images Count',
            value: '${summary.invalidImagesCount}',
          ),
          _SummaryRow(
            label: 'Infection Percentage',
            value: '${summary.infectionPercentage.toStringAsFixed(1)}%',
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  final String message;
  final bool isError;

  const _StatusMessage({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isError
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFFFFBEB);
    final borderColor = isError
        ? const Color(0xFFFECACA)
        : const Color(0xFFFDE68A);
    final iconColor = isError
        ? const Color(0xFFDC2626)
        : const Color(0xFFD97706);
    final textColor = isError
        ? const Color(0xFF7F1D1D)
        : const Color(0xFF92400E);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.schedule,
            color: iconColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
