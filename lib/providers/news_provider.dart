import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_converter/flutter_image_converter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/news.dart';

enum Tag { spieltreff, keinSpieltreff }

class NewsProvider with ChangeNotifier {
  // Map<String, dynamic>? loadedNews;
  List<News> loadedNews = [];

  NewsProvider(this.token);

  String? token;
  Image? image;
  var newsTag = Tag.keinSpieltreff;
  final title = TextEditingController();
  final body = TextEditingController();

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

  Future<int> postNews() async {
    String? tag;
    if (newsTag == Tag.keinSpieltreff) {
      tag = "kein Spieltreff";
    } else if (newsTag == Tag.spieltreff) {
      tag = "Spieltreff";
    }
    String date = DateFormat("dd.MM.yyyy").format(
      DateTime.now(),
    );
    Uint8List? imageData = await getImageData(image);
    String base64Image = "null";
    final url = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/News.json?auth=$token");
    try {
      if (imageData != null) {
        base64Image = base64Encode(imageData.cast<int>().toList());
      }
      final response = await http.post(
        url,
        body: json.encode(
          {
            "imageData": base64Image,
            "title": title.text,
            "body": body.text,
            "tag": tag,
            "date": date,
          },
        ),
      );
      image = null;
      title.text = "";
      body.text = "";
      notifyListeners();
      return response.statusCode;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> getData() async {
    final cacheNews = loadedNews;
    var responce = await http.get(
      Uri.parse("https://db-teg-default-rtdb.firebaseio.com/News.json"),
    );
    try {
      loadedNews = [];
      Map<String, dynamic> dbData = json.decode(responce.body);
      dbData.forEach(
        (key, value) {
          loadedNews.add(
            News(
              title: value["title"] as String,
              body: value["body"] as String,
              date: value["date"] as String,
              tag: value["tag"] as String,
              imageData:
                  value["imageData"] == "null" ? null : value["imageData"],
            ),
          );
        },
      );
      notifyListeners();
    } catch (error) {
      loadedNews = cacheNews;
    }
  }
}
