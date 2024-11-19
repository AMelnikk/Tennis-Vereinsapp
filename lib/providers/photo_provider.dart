import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../models/Photo.dart';
import 'package:http/http.dart' as http;

class PhotoProvider with ChangeNotifier {
  Future<List<Photo>> getData() async {
    final List<Photo> loadedData = [];
    // try {
    var responce = await http.get(
      Uri.parse("https://db-teg-default-rtdb.firebaseio.com/Fotogalerie.json/"),
    );
    var photoData = await (json.decode(responce.body)) as Map<String, dynamic>;
    photoData.forEach((photoId, photoData) => loadedData.add(
          Photo(
            photoId: photoId,
            title: photoData["title"],
            imageData: Uint8List.fromList((photoData["imageData"].cast<int>().toList()))
          ),
        ),);
    print(responce.statusCode);
    // }
    // catch (e) {
    //   print("An error occured");
    // }
    notifyListeners();
    return loadedData;
  }
}
