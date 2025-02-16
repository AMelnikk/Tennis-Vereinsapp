class CalendarEvent {
  final int id;
  final String title;
  final DateTime date;
  final String von;
  final String bis;

  final String category;
  final String
      description; // Hier könnte die Beschreibung des Ereignisses stehen
  final String query;
  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.von,
    required this.bis,
    required this.category,
    required this.description,
    required this.query,
  });
}
