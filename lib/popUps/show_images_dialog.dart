import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/utils/image_helper.dart';
import '../providers/news_provider.dart';

class ImageDialog extends StatefulWidget {
  final List<String> photoBlob;
  final int initialIndex;

  const ImageDialog(
      {super.key, required this.photoBlob, required this.initialIndex});

  @override
  ImageDialogState createState() => ImageDialogState();
}

class ImageDialogState extends State<ImageDialog> with WidgetsBindingObserver {
  int currentIndex = 0;
  double _rotationAngle = 0.0; // Rotation des Bildes

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addObserver(this); // Beobachten der Ausrichtung
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Entfernen des Beobachters
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Gerätedrehung erkennen und Rotation anpassen
    final orientation = MediaQuery.of(context).orientation;
    if (orientation == Orientation.portrait) {
      setState(() {
        _rotationAngle = 0.0; // Hochformat -> keine Rotation
      });
    } else {
      setState(() {
        _rotationAngle = 1.5708; // Querformat -> 90 Grad Rotation
      });
    }
    super.didChangeMetrics();
  }

  @override
  Widget build(BuildContext context) {
    final imageCache =
        Provider.of<NewsProvider>(context, listen: false).imageCache;

    return Dialog(
      backgroundColor: Colors.transparent, // Hintergrund transparent
      insetPadding: EdgeInsets.zero, // Keine Ränder
      child: GestureDetector(
        onPanUpdate: (details) {
          // Prüfen, ob es eine horizontale Bewegung gibt
          if (details.localPosition.dx > 0 && currentIndex > 0) {
            setState(() {
              currentIndex--;
            });
          } else if (details.localPosition.dx < 0 &&
              currentIndex < widget.photoBlob.length - 1) {
            setState(() {
              currentIndex++;
            });
          }
        },
        child: Stack(
          children: [
            // Bildanzeige mit Interaktivität und Rotation
            InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(0), // Kein Rand
              minScale: 0.1,
              maxScale: 4.0,
              child: Transform(
                transform: Matrix4.identity()
                  ..rotateZ(_rotationAngle), // Rotation anwenden
                child: Image.memory(
                  getImage(imageCache, widget.photoBlob[currentIndex]),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Info (1 / 5)
            Positioned(
              top: 2,
              left: 2,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: Text(
                  "${currentIndex + 1} / ${widget.photoBlob.length}",
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ),
            // Schließen Button
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            // Pfeile für Navigation, nur wenn mehr als ein Bild vorhanden ist
            if (widget.photoBlob.length > 1) ...[
              // Links-Pfeil
              Positioned(
                bottom: 5,
                left: 5,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    if (currentIndex > 0) {
                      setState(() {
                        currentIndex--;
                      });
                    }
                  },
                ),
              ),
              // Rechts-Pfeil
              Positioned(
                bottom: 5,
                right: 5,
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Colors.black),
                  onPressed: () {
                    if (currentIndex < widget.photoBlob.length - 1) {
                      setState(() {
                        currentIndex++;
                      });
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void showImageDialog(
    BuildContext context, List<String> photoBlob, int initialIndex) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return ImageDialog(
        photoBlob: photoBlob,
        initialIndex: initialIndex,
      );
    },
  );
}
