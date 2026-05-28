import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PickedImageView extends StatelessWidget {
  final XFile image;

  const PickedImageView({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: image.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Unable to load image."));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return Image.memory(
          snapshot.data!,
          fit: BoxFit.contain,
          width: double.infinity,
        );
      },
    );
  }
}
