import 'dart:typed_data';
import 'package:flutter/material.dart';

class PhotoViewScreen extends StatelessWidget {
  final Uint8List imageData;

  const PhotoViewScreen({super.key, required this.imageData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Photo View")),
      body: Center(
        child: Image.memory(imageData),
      ),
    );
  }
}
