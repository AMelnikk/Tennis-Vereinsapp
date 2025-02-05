class News {
  String id;
  String title;
  String body;
  String date;
  List<String> photoBlob; // Liste von Bild-URLs
  String author;
  String category;

  News({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    required this.author,
    required this.category,
    required this.photoBlob,
  });

  factory News.fromJson(Map<String, dynamic> json, String id) {
    return News(
      id: id,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      date: json['date'] ?? '',
      category: json['category'] ?? '',
      author: json['author'] ?? '',
      photoBlob: (json['photoBlob'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'date': date,
      'photoBlob': photoBlob,
      'category': category,
      'author': author,
    };
  }
}
