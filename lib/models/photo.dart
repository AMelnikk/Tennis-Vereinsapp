import 'dart:typed_data';

class Photo {

  Photo({required this.photoId, required this.title, required this.imageData});

  final String photoId;
  final String title;
  final Uint8List imageData;

}