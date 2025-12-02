import 'package:verein_app/models/calendar_event_registration.dart';

class CalendarEvent {
  final int id;
  final String title;
  final String ort;
  final DateTime date;
  final String von;
  final String bis;

  final String category;
  final String
      description; // Hier könnte die Beschreibung des Ereignisses stehen
  final String query;
  List<EventRegistration> allRegistrations;
  int registrationCount;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.ort,
    required this.date,
    required this.von,
    required this.bis,
    required this.category,
    required this.description,
    required this.query,
    this.registrationCount = 0,
    this.allRegistrations = const [],
  });

  factory CalendarEvent.fromMap(Map<String, dynamic> data) {
    // Robuste Datums-Konvertierung
    DateTime parsedDate =
        DateTime.tryParse(data['date'] ?? '') ?? DateTime.now();

    return CalendarEvent(
      id: data['id'],
      date: parsedDate,
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      // Wichtig: 'details' aus der Map wird zu 'description' im Objekt
      description: data['details'] ?? '',
      von: data['von'] ?? '',
      bis: data['bis'] ?? '',
      ort: data['ort'] ?? '',
      query: data['query'] ?? '',
    );
  }
}
