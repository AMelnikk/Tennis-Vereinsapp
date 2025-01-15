import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_converter/flutter_image_converter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/news.dart';

enum Tag { spieltreff, keinSpieltreff }

class NewsProvider with ChangeNotifier {
  // Map<String, dynamic>? loadedNews;
  List<News> loadedNews = [];

  NewsProvider(this._token);

  final String? _token;
  Image? image;
  var newsTag = Tag.keinSpieltreff;
  final title = TextEditingController();
  final body = TextEditingController();
  String? _lastId;
  bool hasMore = true;

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
        "https://db-teg-default-rtdb.firebaseio.com/News.json?auth=$_token");
    try {
      if (imageData != null) {
        final image = await FlutterImageCompress.compressWithList(
          imageData,
          minHeight: 1080,
          minWidth: 1080,
          quality: 80,
          format: CompressFormat.webp,
        );
        base64Image = base64Encode(image.cast<int>().toList());
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

  Future<void> deleteNews(String id) async {
    if(kDebugMode) print(id);
    final url = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/News/$id.json?auth=$_token");
    final responce = await http.delete(url);
    loadedNews.removeWhere((item) => item.id == id);
    if (kDebugMode) print(responce.statusCode);
    notifyListeners();
  }

  Future<void> getData() async {
    final cacheNews = loadedNews;
    if (!hasMore) {
      return;
    }
    try {
      String queryParams = _lastId == null
          ? 'orderBy="%24key"&limitToLast=5'
          : 'orderBy="%24key"&endAt="$_lastId"&limitToLast=6';
      var responce = await http.get(
        Uri.parse(
            'https://db-teg-default-rtdb.firebaseio.com/News.json?$queryParams'),
      );
      List<News> loadedData = [];
      Map<String, dynamic> dbData = await json.decode(responce.body);
      dbData.forEach(
        (id, value) {
          loadedData.add(
            News(
              id: id,
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
      if (_lastId != null) {
        loadedData.removeAt(loadedData.length - 1);
      }
      hasMore = dbData.length == 5;
      _lastId = loadedData.isNotEmpty ? loadedData.first.id : null;
      loadedNews.insertAll(0, loadedData);
      notifyListeners();
    } catch (error) {
      loadedNews = cacheNews;
    }
  }
}
