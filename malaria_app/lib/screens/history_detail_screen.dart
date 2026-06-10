import 'dart:io';

import 'package:flutter/material.dart';

import '../models/scan_history.dart';

class HistoryDetailScreen extends StatelessWidget {
  final ScanHistory scan;

  const HistoryDetailScreen({super.key, required this.scan});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(scan.prediction);
    final confidence = scan.confidence.clamp(0, 100).toDouble();

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              height: 280,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: _HistoryImage(path: scan.imagePath),
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
                  _DetailRow(label: 'Scan ID', value: '#${scan.id ?? '-'}'),
                  _DetailRow(label: 'Date', value: _formatDate(scan.scannedAt)),
                  _DetailRow(label: 'Image Path', value: scan.imagePath),
                  const SizedBox(height: 12),
                  Text(
                    scan.prediction,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
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
                        '${confidence.toStringAsFixed(1)}%',
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
                      value: confidence / 100,
                      minHeight: 12,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String prediction) {
    return switch (prediction) {
      'Parasitized' => const Color(0xFFDC2626),
      'Uninfected' => const Color(0xFF16A34A),
      _ => const Color(0xFF64748B),
    };
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $hour:$minute';
  }
}

class _HistoryImage extends StatelessWidget {
  final String path;

  const _HistoryImage({required this.path});

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (!file.existsSync()) {
      return const Center(
        child: Icon(Icons.broken_image, size: 56, color: Color(0xFF94A3B8)),
      );
    }

    return Image.file(file, fit: BoxFit.contain, width: double.infinity);
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
