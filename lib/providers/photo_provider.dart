import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_converter/flutter_image_converter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/Photo.dart';
import 'package:http/http.dart' as http;

class PhotoProvider with ChangeNotifier {
  PhotoProvider(this.token);

  String? token;

  Image? image;
  final title = TextEditingController();

  Future<void> pickImage() async {
    XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) {
      image = Image.file(File(file.path));
    }
    notifyListeners();
  }

  Future<Uint8List?> getImageData(Image? image) async {
    Uint8List? imageData = await image?.uint8List;
    print(imageData);
    return imageData;
  }

  // Future<void> delete()async {
  //   final url = Uri.parse(
  //       "https://db-teg-default-rtdb.firebaseio.com/Fotogalerie/-OCxHGaDBUvVfXFiPTO5.json?auth=$token");
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
        final base64Image = base64Encode(imageData.cast<int>().toList());
        final response = await http.post(
          url,
          body: json.encode(
            {"title": title.text, "imageData": base64Image},
          ),
        );
        notifyListeners();
        return response.statusCode;
      } else {
        throw const HttpException("Kein Foto gewählt");
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<List<Photo>> getData() async {
    final List<Photo> loadedData = [];
    try {
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
              title: photoData["title"],
              imageData: base64Decode(photoData["imageData"])
              // imageData: Uint8List.fromList(
              //   (photoData["imageData"].cast<int>().toList()),
              // ),
              ),
        ),
      );
      print(responce.statusCode);
    } catch (e) {
      print("An error occured");
    }
    notifyListeners();
    return loadedData;
  }

//
  // Future<Uint8List> getBytesFromPhoto() async {
  //   return (await rootBundle.load("assets/images/Vereinslogo.png"))
  //       .buffer
  //       .asUint8List();
  // }

  // Future<void> postDbimage(
  //     //Uint8List imageData,
  //     String title,
  //     String token) async {
  //   final Uint8List imageData = await getBytesFromPhoto();

  //   var responce = await http.post(
  //     Uri.parse(
  //         "https://db-teg-default-rtdb.firebaseio.com/Fotogalerie.json?auth=$token"),
  //     body: json.encode(
  //       {"title": title, "imageData": imageData},
  //     ),
  //   );
  //   print(responce.statusCode);
  // }
}
