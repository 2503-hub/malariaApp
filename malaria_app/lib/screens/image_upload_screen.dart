import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'preview_screen.dart';
import '../widgets/picked_image_view.dart';

class ImageUploadScreen extends StatefulWidget {
  final ImageSource? initialSource;

  const ImageUploadScreen({super.key, this.initialSource});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    final source = widget.initialSource;
    if (source != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage(source));
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (!mounted || pickedFile == null) return;

    setState(() {
      _selectedImage = pickedFile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Upload')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              height: 290,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: _selectedImage == null
                  ? const _EmptyPreview()
                  : PickedImageView(image: _selectedImage!),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Upload from Gallery'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Picture'),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _selectedImage == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PreviewScreen(image: _selectedImage!),
                        ),
                      );
                    },
              icon: const Icon(Icons.analytics),
              label: const Text('Continue to Analysis'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_search, size: 58, color: Color(0xFF94A3B8)),
        SizedBox(height: 12),
        Text(
          'No image selected',
          style: TextStyle(
            color: Color(0xFF334155),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 6),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            'Choose a blood smear image from your gallery or camera.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }
}
