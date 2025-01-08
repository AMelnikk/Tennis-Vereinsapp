import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_image_converter/flutter_image_converter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/Photo.dart';
import 'package:http/http.dart' as http;

class PhotoProvider with ChangeNotifier {
  PhotoProvider(this.token);

  String? token;
  Image? image;

  List<Photo> loadedData = [];

  Future<void> pickImage() async {
    XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) {
      image = Image.file(File(file.path));
    }
    notifyListeners();
  }

  Future<Uint8List?> getImageData(Image? image) async {
    Uint8List? imageData = await image?.uint8List;
    return imageData;
  }

  // Future<void> delete() async {
  //   final url = Uri.parse(
  //       "https://db-teg-default-rtdb.firebaseio.com/Fotogalerie/-OFg-OEhRjRqqwSF08Q6.json?auth=$token");
  //   final responce = await http.delete(url);
  //   print(responce.statusCode);
  //   print(responce.body);
  // }

  Future<int> postImage() async {
    Uint8List? imageData = await getImageData(image);
    final url = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/Fotogalerie.json?auth=$token");
    try {
      if (imageData != null) {
        // final base64Image = base64Encode(imageData.cast<int>().toList());
        final image = await FlutterImageCompress.compressWithList(
          imageData,
          minHeight: 1080,
          minWidth: 1080,
          quality: 80,
          format: CompressFormat.webp,
        );
        final base64Image = base64Encode(image.cast<int>().toList());
        final previousBase64Image = base64Encode(imageData.cast<int>().toList());
        print(previousBase64Image.length);
        print(base64Image.length);

        print("\n${imageData.length}");
        print(image.length);
        final response = await http.post(
          url,
          body: json.encode(
            {"imageData": base64Image},
          ),
        );
        loadedData = [];
        notifyListeners();
        return response.statusCode;
      } else {
        throw const HttpException("Kein Foto gewählt");
      }
    } catch (error) {
      return 400;
    }
  }

  Future<void> getData() async {
    final cachePhotos = loadedData;
    try {
      loadedData = [];
      var responce = await http.get(
        Uri.parse(
            "https://db-teg-default-rtdb.firebaseio.com/Fotogalerie.json/"),
      );
      var photoData =
          await (json.decode(responce.body)) as Map<String, dynamic>;
      photoData.forEach(
        (photoId, photoData) => loadedData.add(
          Photo(
            photoId: photoId,
            imageData: base64Decode(
              photoData["imageData"],
            ),
          ),
        ),
      );
      notifyListeners();
    } catch (e) {
      loadedData = cachePhotos;
      if (kDebugMode) {
        print(e);
      }
    }
  }
}
