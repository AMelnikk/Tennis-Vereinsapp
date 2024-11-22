import 'dart:typed_data';
import 'package:flutter/material.dart';

class PhotoWidget extends StatelessWidget {
  const PhotoWidget({super.key, required this.title, required this.photoData});

  final String title;
  final Uint8List photoData;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.memory(
          photoData,
          height: 150,
          width: 150,
        ),
        const SizedBox(
          height: 5,
        ),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }
}
