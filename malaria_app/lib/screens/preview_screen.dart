import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'loading_screen.dart';
import '../widgets/picked_image_view.dart';

class PreviewScreen extends StatelessWidget {
  final XFile image;

  const PreviewScreen({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview Image')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: PickedImageView(image: image),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LoadingScreen(image: image),
                    ),
                  );
                },
                icon: const Icon(Icons.biotech),
                label: const Text('Analyze Image'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
