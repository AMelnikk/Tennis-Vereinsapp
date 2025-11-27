import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_image_converter/flutter_image_converter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:verein_app/models/photo.dart';
import 'package:http/http.dart' as http;

class PhotoProvider with ChangeNotifier {
  PhotoProvider(this._token);

  final String? _token;
  Image? image;
  bool isHttpProceeding = false;
  String? lastId;
  bool hasMore = true;
  var photoDateController = TextEditingController();
  bool isDebug = false;

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
        "https://db-teg-default-rtdb.firebaseio.com/Fotogalerie.json?auth=$_token");
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
      if (kDebugMode) print(error);
      return 400;
    }
  }

  Future<void> getData() async {
    if (!hasMore) return;
    final cachePhotos = loadedData;
    try {
      isHttpProceeding = true;
      List<Photo> loadedNews = [];

      String queryParams = lastId == null
          ? 'orderBy="%24key"&limitToLast=5'
          : 'orderBy="%24key"&endAt="$lastId"&limitToLast=6';

      var responce = await http.get(
        Uri.parse(
            "https://db-teg-default-rtdb.firebaseio.com/Fotogalerie.json?$queryParams"),
      );

      var photoData =
          await (json.decode(responce.body)) as Map<String, dynamic>;

      photoData.forEach(
        (photoId, photoData) => loadedNews.add(
          Photo(
            photoId: photoId,
            imageData: base64Decode(
              photoData["imageData"],
            ),
          ),
        ),
      );
      if (lastId != null) {
        loadedNews.removeAt(loadedNews.length - 1);
        if (loadedNews.isEmpty) {
          hasMore = false;
        } else {
          hasMore = loadedNews.length == 5;
          lastId = loadedNews.isNotEmpty ? loadedNews.first.photoId : null;
          for (int i = loadedNews.length - 1; i >= 0; i--) {
            loadedData.insert(0, loadedNews[i]);
          }
        }
      } else {
        hasMore = loadedNews.length == 5;
        lastId = loadedNews.isNotEmpty ? loadedNews.first.photoId : null;
        for (int i = loadedNews.length - 1; i >= 0; i--) {
          loadedData.insert(0, loadedNews[i]);
        }
      }
      isHttpProceeding = false;
      notifyListeners();
    } catch (e) {
      loadedData = cachePhotos;
      if (kDebugMode) {
        print(e);
      }
      if (e.toString().contains("RangeError")) hasMore = false;
    }
  }
}
