import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class GeneratedPdfReport {
  final String reportId;
  final String filePath;
  final DateTime generatedAt;

  const GeneratedPdfReport({
    required this.reportId,
    required this.filePath,
    required this.generatedAt,
  });
}

class PdfReportService {
  PdfReportService._();

  static final PdfReportService instance = PdfReportService._();

  Future<GeneratedPdfReport> generatePredictionReport({
    required XFile image,
    required String prediction,
    required double confidence,
  }) async {
    await _requestStoragePermissionIfNeeded();

    final generatedAt = DateTime.now();
    final reportId = _createReportId(generatedAt);
    final imageBytes = await image.readAsBytes();
    final pdfBytes = await _buildReportPdf(
      reportId: reportId,
      generatedAt: generatedAt,
      imageBytes: imageBytes,
      prediction: prediction,
      confidence: confidence,
    );

    final reportsDirectory = await _reportsDirectory();
    final file = File(p.join(reportsDirectory.path, '$reportId.pdf'));
    await file.writeAsBytes(pdfBytes, flush: true);

    return GeneratedPdfReport(
      reportId: reportId,
      filePath: file.path,
      generatedAt: generatedAt,
    );
  }

  Future<void> shareReport(GeneratedPdfReport report) async {
    await Share.shareXFiles(
      [XFile(report.filePath, mimeType: 'application/pdf')],
      subject: 'Malaria Detection Report ${report.reportId}',
      text: 'Malaria Detection AI report ${report.reportId}',
    );
  }

  Future<String> downloadReport(GeneratedPdfReport report) async {
    await _requestStoragePermissionIfNeeded();

    final source = File(report.filePath);
    final targetDirectory = await _downloadsDirectory();
    final target = File(p.join(targetDirectory.path, p.basename(report.filePath)));
    await source.copy(target.path);
    return target.path;
  }

  Future<Directory> _reportsDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final reportsDirectory = Directory(
      p.join(documentsDirectory.path, 'malaria_reports'),
    );

    if (!await reportsDirectory.exists()) {
      await reportsDirectory.create(recursive: true);
    }

    return reportsDirectory;
  }

  Future<Directory> _downloadsDirectory() async {
    if (Platform.isAndroid) {
      final publicDownloads = Directory('/storage/emulated/0/Download');
      if (await publicDownloads.exists()) {
        try {
          final probe = File(
            p.join(
              publicDownloads.path,
              '.malaria_report_write_test',
            ),
          );
          await probe.writeAsString('ok');
          await probe.delete();
          return publicDownloads;
        } catch (_) {
          // Fall back to app-local storage on Android versions with scoped storage.
        }
      }
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final downloadsDirectory = Directory(
      p.join(documentsDirectory.path, 'downloaded_reports'),
    );

    if (!await downloadsDirectory.exists()) {
      await downloadsDirectory.create(recursive: true);
    }

    return downloadsDirectory;
  }

  Future<void> _requestStoragePermissionIfNeeded() async {
    if (!Platform.isAndroid) return;

    final status = await Permission.storage.status;
    if (status.isDenied) {
      await Permission.storage.request();
    }
  }

  Future<Uint8List> _buildReportPdf({
    required String reportId,
    required DateTime generatedAt,
    required Uint8List imageBytes,
    required String prediction,
    required double confidence,
  }) async {
    final document = pw.Document(
      title: 'Malaria Detection Report',
      author: 'Malaria Detection AI',
      subject: 'AI-assisted malaria blood smear prediction',
    );
    final image = pw.MemoryImage(imageBytes);
    final statusColor = _statusColor(prediction);
    final confidencePercent = confidence.clamp(0, 100).toDouble();

    document.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          margin: pw.EdgeInsets.all(32),
        ),
        build: (context) {
          return [
            _header(reportId, generatedAt),
            pw.SizedBox(height: 18),
            _sectionTitle('Analysis Summary'),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: _boxDecoration(),
              child: pw.Text(
                _summaryFor(prediction, confidencePercent),
                style: const pw.TextStyle(
                  fontSize: 11,
                  lineSpacing: 3,
                  color: PdfColor.fromInt(0xFF334155),
                ),
              ),
            ),
            pw.SizedBox(height: 16),
            _sectionTitle('AI Prediction Section'),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 5,
                  child: pw.Container(
                    height: 220,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: _boxDecoration(),
                    child: pw.Image(image, fit: pw.BoxFit.contain),
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  flex: 4,
                  child: _predictionCard(
                    prediction: prediction,
                    confidencePercent: confidencePercent,
                    statusColor: statusColor,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            _sectionTitle('Clinical Note'),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: _boxDecoration(fill: const PdfColor.fromInt(0xFFF8FAFC)),
              child: pw.Text(
                'This report is generated by an AI-assisted screening tool and is not a final medical diagnosis. Confirm suspected malaria with microscopy, rapid diagnostic testing, and guidance from a qualified healthcare professional.',
                style: const pw.TextStyle(
                  fontSize: 10,
                  lineSpacing: 3,
                  color: PdfColor.fromInt(0xFF475569),
                ),
              ),
            ),
          ];
        },
      ),
    );

    return document.save();
  }

  pw.Widget _header(String reportId, DateTime generatedAt) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFF087F7A),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Malaria Detection AI',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Medical Image Analysis Report',
                style: const pw.TextStyle(
                  color: PdfColor.fromInt(0xFFE6FFFB),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _headerMeta('Report ID', reportId),
              pw.SizedBox(height: 6),
              _headerMeta('Date & Time', _formatDateTime(generatedAt)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _headerMeta(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            color: PdfColor.fromInt(0xFFBFF3EF),
            fontSize: 8,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: const PdfColor.fromInt(0xFF0F172A),
        ),
      ),
    );
  }

  pw.Widget _predictionCard({
    required String prediction,
    required double confidencePercent,
    required PdfColor statusColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _labelValue('Prediction Result', prediction, valueColor: statusColor),
          pw.SizedBox(height: 18),
          _labelValue(
            'Confidence Score',
            '${confidencePercent.toStringAsFixed(1)}%',
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            height: 8,
            width: 150,
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFE2E8F0),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Container(
              width: 150 * max(0.02, confidencePercent / 100),
              decoration: pw.BoxDecoration(
                color: statusColor,
                borderRadius: pw.BorderRadius.circular(8),
              ),
            ),
          ),
          pw.SizedBox(height: 18),
          _labelValue('Image Type', 'Blood smear cell image'),
          pw.SizedBox(height: 18),
          _labelValue('Analysis Method', 'TensorFlow/Keras CNN classifier'),
        ],
      ),
    );
  }

  pw.Widget _labelValue(
    String label,
    String value, {
    PdfColor valueColor = const PdfColor.fromInt(0xFF0F172A),
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            color: PdfColor.fromInt(0xFF64748B),
            fontSize: 9,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.BoxDecoration _boxDecoration({
    PdfColor fill = PdfColors.white,
  }) {
    return pw.BoxDecoration(
      color: fill,
      border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
      borderRadius: pw.BorderRadius.circular(8),
    );
  }

  PdfColor _statusColor(String prediction) {
    return switch (prediction.trim().toLowerCase()) {
      'parasitized' => const PdfColor.fromInt(0xFFDC2626),
      'not cell image' => const PdfColor.fromInt(0xFF64748B),
      _ => const PdfColor.fromInt(0xFF16A34A),
    };
  }

  String _summaryFor(String prediction, double confidencePercent) {
    final normalized = prediction.trim().toLowerCase();
    final confidence = confidencePercent.toStringAsFixed(1);

    if (normalized == 'parasitized') {
      return 'The AI model classified the uploaded blood smear image as Parasitized with a confidence score of $confidence%. The visual pattern may be consistent with malaria-infected red blood cells and should be confirmed by a qualified health professional.';
    }

    if (normalized == 'not cell image') {
      return 'The AI model classified the upload as Not Cell Image with a confidence score of $confidence%. The image may not be suitable for blood smear analysis. A clear microscope image of red blood cells should be used for screening.';
    }

    return 'The AI model classified the uploaded blood smear image as Uninfected with a confidence score of $confidence%. This result does not replace clinical assessment, especially if fever or malaria symptoms are present.';
  }

  String _createReportId(DateTime generatedAt) {
    final date = generatedAt.toUtc();
    final stamp =
        '${date.year}${_two(date.month)}${_two(date.day)}${_two(date.hour)}${_two(date.minute)}${_two(date.second)}';
    final suffix = Random().nextInt(9000) + 1000;
    return 'MAL-$stamp-$suffix';
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-${_two(local.month)}-${_two(local.day)} ${_two(local.hour)}:${_two(local.minute)}';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
