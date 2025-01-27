class CalendarEvent {
  final int id;
  final String title;
  final DateTime date;
  final String kategorie;
  final String
      description; // Hier könnte die Beschreibung des Ereignisses stehen
  final String abfrage;
  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.kategorie,
    required this.description,
    required this.abfrage,
  });
}
