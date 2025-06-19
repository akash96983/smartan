import 'dart:io';
import 'package:flutter/material.dart';

class ImageThumbnail extends StatelessWidget {
  final String imagePath;
  final double size;
  const ImageThumbnail({super.key, required this.imagePath, this.size = 56});

  @override
  Widget build(BuildContext context) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else {
      return Image.file(
        File(imagePath),
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }
  }
}
