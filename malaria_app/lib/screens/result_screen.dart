import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/picked_image_view.dart';

class ResultScreen extends StatelessWidget {
  final XFile image;
  final String label;
  final double confidence;

  const ResultScreen({
    super.key,
    required this.image,
    required this.label,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedLabel = label.trim().toLowerCase();
    final isInfected = normalizedLabel == 'parasitized';
    final statusColor = isInfected
        ? const Color(0xFFDC2626)
        : const Color(0xFF16A34A);
    final confidencePercent = confidence.clamp(0, 100).toDouble();

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
              child: PickedImageView(image: image),
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
                  Row(
                    children: [
                      Icon(
                        isInfected ? Icons.warning_amber : Icons.check_circle,
                        color: statusColor,
                        size: 30,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
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
                        : 'No malaria parasites were detected in this image. Continue routine health monitoring and seek medical care if symptoms persist.',
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 15,
                      height: 1.45,
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
}
