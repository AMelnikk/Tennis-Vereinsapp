class TeGNotification {
  String id;
  String type;
  String title;
  String year;
  String body;
  int timestamp;

  TeGNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.year,
    int? timestamp,
  }) : timestamp = timestamp ??
            DateTime.now()
                .millisecondsSinceEpoch; // Default to current time if no timestamp is provided

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "type": type,
      "title": title,
      "body": body,
      "year": year,
      "timestamp": timestamp,
    };
  }

  factory TeGNotification.fromMap(Map<String, dynamic> map) {
    return TeGNotification(
      id: map['id'] ?? "",
      type: map['type'] ?? "Unbekannter Typ",
      title: map['title'] ?? "Keine Nachricht verfügbar",
      body: map['body'] ?? "",
      year: map['year'] ?? "",
      timestamp: map['timestamp'] is int
          ? map['timestamp']
          : DateTime.now().millisecondsSinceEpoch,
    );
  }
}
