import 'dart:typed_data';
import 'package:flutter/material.dart';

class PhotoWidget extends StatelessWidget {
  const PhotoWidget({super.key, required this.photoData});

  final Uint8List photoData;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.width,
      child: Image.memory(
        photoData,
        fit: BoxFit.cover,
      ),
    );
  }
}
