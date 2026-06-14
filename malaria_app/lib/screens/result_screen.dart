import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/detection_result.dart';
import '../services/pdf_report_service.dart';
import '../widgets/picked_image_view.dart';

class ResultScreen extends StatefulWidget {
  final XFile image;
  final String label;
  final double confidence;
  final DetectionMode detectionMode;
  final int processingTimeMs;
  final String? detail;
  final bool isPending;
  final String? pendingMessage;

  const ResultScreen({
    super.key,
    required this.image,
    required this.label,
    required this.confidence,
    this.detectionMode = DetectionMode.offline,
    this.processingTimeMs = 0,
    this.detail,
    this.isPending = false,
    this.pendingMessage,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  GeneratedPdfReport? _report;
  bool _isGeneratingReport = false;
  bool _isSharingReport = false;

  Future<void> _generateReport() async {
    setState(() {
      _isGeneratingReport = true;
    });

    try {
      final report = await PdfReportService.instance.generatePredictionReport(
        image: widget.image,
        prediction: widget.label,
        confidence: widget.confidence,
      );

      if (!mounted) return;

      setState(() {
        _report = report;
      });

      _showMessage('PDF report saved locally: ${report.reportId}');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Unable to generate PDF report. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
        });
      }
    }
  }

  Future<void> _downloadReport() async {
    final report = _report;
    if (report == null) return;

    setState(() {
      _isSharingReport = true;
    });

    try {
      final filePath = await PdfReportService.instance.downloadReport(report);
      if (!mounted) return;
      _showMessage('PDF saved to $filePath');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to export the PDF report.');
    } finally {
      if (mounted) {
        setState(() {
          _isSharingReport = false;
        });
      }
    }
  }

  Future<void> _shareReport() async {
    final report = _report;
    if (report == null) return;

    setState(() {
      _isSharingReport = true;
    });

    try {
      await PdfReportService.instance.shareReport(report);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to share the PDF report.');
    } finally {
      if (mounted) {
        setState(() {
          _isSharingReport = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final normalizedLabel = widget.label.trim().toLowerCase();
    final isInfected = normalizedLabel == 'parasitized';
    final isInvalid = normalizedLabel == 'not cell image';
    final isUncertain = normalizedLabel == 'uncertain';
    final isPending = widget.isPending;
    final modeLabel = widget.detectionMode.shortLabel;
    final statusColor = isPending
        ? const Color(0xFFD97706)
        : isInfected
            ? const Color(0xFFDC2626)
            : isInvalid
        ? const Color(0xFF64748B)
        : isUncertain
        ? const Color(0xFFD97706)
        : const Color(0xFF16A34A);
    final confidencePercent = widget.confidence.clamp(0, 100).toDouble();

    return Scaffold(
      appBar: AppBar(title: const Text('Prediction Result')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              height: 260,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: PickedImageView(image: widget.image),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Prediction Result',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ModeBadge(modeLabel: modeLabel, isPending: isPending),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isPending
                            ? Icons.schedule
                            : isInfected
                            ? Icons.warning_amber
                            : isInvalid
                            ? Icons.image_not_supported
                            : isUncertain
                            ? Icons.help_outline
                            : Icons.check_circle,
                        color: statusColor,
                        size: 30,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isPending ? 'Pending Sync' : widget.label,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  if (!isPending) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Confidence',
                          style: TextStyle(
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${confidencePercent.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: confidencePercent / 100,
                        minHeight: 12,
                        backgroundColor: const Color(0xFFE2E8F0),
                        color: statusColor,
                      ),
                    ),
                    if (widget.processingTimeMs > 0) ...[
                      const SizedBox(height: 10),
                      Text(
                        widget.detectionMode == DetectionMode.offline
                            ? 'Processed locally on this device in ${widget.processingTimeMs} ms'
                            : 'Processed remotely in ${widget.processingTimeMs} ms',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    const Text(
                      'Recommendation',
                      style: TextStyle(
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isInfected
                          ? 'Malaria parasites were detected. Please consult a qualified health professional for confirmatory testing and treatment.'
                          : isInvalid
                          ? 'The uploaded image does not appear to be a valid blood cell smear. Please upload a clearer cell image for analysis.'
                          : isUncertain
                          ? 'The model is not confident enough to make a reliable call. Please upload a clearer cell image and try again.'
                          : 'No malaria parasites were detected in this image. Continue routine health monitoring and seek medical care if symptoms persist.',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                    if (widget.detail != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.detail!,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Queued for sync',
                            style: TextStyle(
                              color: Color(0xFF9A3412),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.pendingMessage ??
                                'This scan was saved on the device and will be analyzed automatically when a connection is available.',
                            style: const TextStyle(
                              color: Color(0xFF7C2D12),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (!isPending)
              _ReportActions(
                report: _report,
                isGeneratingReport: _isGeneratingReport,
                isSharingReport: _isSharingReport,
                onGenerate: _generateReport,
                onDownload: _downloadReport,
                onShare: _shareReport,
              ),
          ],
        ),
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  final String modeLabel;
  final bool isPending;

  const _ModeBadge({
    required this.modeLabel,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isPending
        ? const Color(0xFFFFFBEB)
        : const Color(0xFFE0F2FE);
    final foregroundColor = isPending
        ? const Color(0xFF92400E)
        : const Color(0xFF075985);
    final icon = isPending ? Icons.schedule : Icons.smartphone;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foregroundColor),
            const SizedBox(width: 6),
            Text(
              isPending ? 'Queued locally' : '$modeLabel detection',
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportActions extends StatelessWidget {
  final GeneratedPdfReport? report;
  final bool isGeneratingReport;
  final bool isSharingReport;
  final VoidCallback onGenerate;
  final VoidCallback onDownload;
  final VoidCallback onShare;

  const _ReportActions({
    required this.report,
    required this.isGeneratingReport,
    required this.isSharingReport,
    required this.onGenerate,
    required this.onDownload,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final isBusy = isGeneratingReport || isSharingReport;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Medical Report',
            style: TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            report == null
                ? 'Generate a professional PDF report for this analysis.'
                : 'Report saved locally as ${report!.reportId}.',
            style: const TextStyle(color: Color(0xFF64748B), height: 1.35),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: isBusy ? null : onGenerate,
            icon: isGeneratingReport
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: Text(
              report == null ? 'Generate PDF Report' : 'Regenerate PDF Report',
            ),
          ),
          if (report != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : onDownload,
                    icon: const Icon(Icons.download),
                    label: const Text('Download PDF'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : onShare,
                    icon: const Icon(Icons.share),
                    label: const Text('Share PDF'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
