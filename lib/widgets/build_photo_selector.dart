import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:verein_app/utils/image_helper.dart';

class PhotoSelector extends StatefulWidget {
  final Function(List<String>) onImagesSelected;
  final List<String> initialPhotoList;

  const PhotoSelector({
    super.key,
    required this.onImagesSelected,
    this.initialPhotoList = const [],
  });

  @override
  State<PhotoSelector> createState() => _PhotoSelectorState();
}

class _PhotoSelectorState extends State<PhotoSelector> {
  late List<String> _photoBlobs;
  int? _draggingIndex;

  @override
  void initState() {
    super.initState();
    _photoBlobs = List.from(widget.initialPhotoList);
  }

  void _updateImages() {
    widget.onImagesSelected(List.from(_photoBlobs));
  }

  void _onReorder(int fromIndex, int toIndex) {
    setState(() {
      final item = _photoBlobs.removeAt(fromIndex);
      _photoBlobs.insert(toIndex, item);
    });
    _updateImages();
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
              _photoBlobs = {..._photoBlobs, ...selectedImages}.toList();
            });
            _updateImages();
          },
          child: const Text('Fotos auswählen'),
        ),
        const SizedBox(height: 10),
        if (_photoBlobs.isEmpty)
          const Text('Keine Bilder ausgewählt.',
              style: TextStyle(color: Colors.grey)),
        if (_photoBlobs.isNotEmpty) ...[
          TextButton.icon(
            icon: const Icon(Icons.clear),
            label: const Text('Alle entfernen'),
            onPressed: () {
              setState(() {
                _photoBlobs.clear();
              });
              _updateImages();
            },
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_photoBlobs.length, (index) {
              return Draggable<int>(
                data: index,
                dragAnchorStrategy: pointerDragAnchorStrategy,
                onDragStarted: () {
                  setState(() {
                    _draggingIndex = index;
                  });
                },
                onDraggableCanceled: (_, __) {
                  setState(() {
                    _draggingIndex = null;
                  });
                },
                onDragCompleted: () {
                  setState(() {
                    _draggingIndex = null;
                  });
                },
                feedback: _buildImage(index, dragging: true),
                child: DragTarget<int>(
                  onWillAccept: (fromIndex) => fromIndex != index,
                  onAccept: (fromIndex) => _onReorder(fromIndex, index),
                  builder: (context, candidateData, rejectedData) {
                    return _buildImage(index);
                  },
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildImage(int index, {bool dragging = false}) {
    final imageData = _photoBlobs[index];

    return Opacity(
      opacity: dragging ? 0.7 : 1.0,
      child: Stack(
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
                  _photoBlobs.removeAt(index);
                });
                _updateImages();
              },
            ),
          ),
        ],
      ),
    );
  }
}
