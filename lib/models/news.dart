class News {
  News(
      {required this.title,
      required this.body,
      required this.date,
      required this.tag,
      this.imageData});

  String title;
  String body;
  String date;
  String? imageData;
  String tag;
}
