import 'dart:typed_data';

import 'package:flutter/material.dart';

class PhotoWidget extends StatelessWidget {
  const PhotoWidget({super.key, required this.title, required this.photoData});

  final String title;
  final Uint8List photoData;

  @override
  Widget build(BuildContext context) {
    return Container(child: Column(children: [Image.memory(photoData), Text(title)],));
  }
}