import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:verein_app/utils/image_helper.dart';

class PhotoSelector extends StatefulWidget {
  final Function(List<String>) onImagesSelected;
  final List<String> initialPhotoList; // Liste der initialen Bilder

  const PhotoSelector({
    super.key,
    required this.onImagesSelected,
    this.initialPhotoList = const [], // Standardwert ist eine leere Liste
  });

  @override
  PhotoSelectorState createState() => PhotoSelectorState();
}

class PhotoSelectorState extends State<PhotoSelector> {
  late List<String> _photoBlobs;

  @override
  void initState() {
    super.initState();
    _photoBlobs =
        widget.initialPhotoList; // Initialisiere mit der übergebenen Liste
  }

  @override
  Widget build(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: () async {
            List<String> selectedImages = await pickImages(messenger);
            setState(() {
              _photoBlobs = selectedImages;
            });
            widget.onImagesSelected(selectedImages);
          },
          child: const Text('Fotos auswählen'),
        ),
        const SizedBox(height: 10),
        if (_photoBlobs.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _photoBlobs.map((imageData) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      base64Decode(imageData),
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _photoBlobs.remove(imageData);
                        });
                        widget.onImagesSelected(_photoBlobs);
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }
}
