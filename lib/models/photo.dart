import 'dart:typed_data';

class Photo {

  Photo({required this.photoId, required this.imageData});

  final String photoId;
  final Uint8List imageData;

}