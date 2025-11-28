import 'package:verein_app/utils/app_utils.dart';

class News {
  String id;
  String title;
  String body;
  String date;
  String author;
  String category;
  List<String> photoBlob;
  int lastUpdate; // Bleibt ein int für Firebase-Kompatibilität

  News({
    required this.id,
    this.title = '',
    this.body = '',
    this.date = '',
    this.author = '',
    this.category = 'Allgemein',
    this.photoBlob = const [],
    required this.lastUpdate,
  });

  factory News.fromJson(Map<String, dynamic> json, String id) {
    return News(
      id: id,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      date: json['date'] ?? '',
      category: json['category'] ?? 'Allgemein',
      author: json['author'] ?? '',
      photoBlob: parsePhotoBlob(json['photoBlob']),
      lastUpdate: json['lastUpdate'] is int
          ? json['lastUpdate']
          : DateTime.now()
              .millisecondsSinceEpoch, // Stellt sicher, dass ein int verwendet wird
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "body": body,
      "date": date,
      "author": author,
      "category": category,
      "photoBlob": photoBlob,
      "lastUpdate": lastUpdate, // Wird als int gespeichert
    };
  }
}
