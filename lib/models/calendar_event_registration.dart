import 'dart:convert';

class EventRegistration {
  // Primärschlüssel (optional, wird oft vom Backend generiert)
  final String registrationId;

  // Fremdschlüssel: ID des Termins, auf den sich die Anmeldung bezieht
  final int terminId;

  // Wichtig: ID oder Name des angemeldeten Benutzers
  final String userId;

  // Status der Teilnahme (JA oder NEIN)
  final bool status;

  // Nur relevant bei Status.JA
  final int? peopleCount;
  final String? itemsBrought;

  // Wann wurde die Anmeldung erstellt/geändert
  final DateTime timestamp;

  EventRegistration({
    required this.registrationId,
    required this.terminId,
    required this.userId,
    required this.status,
    this.peopleCount,
    this.itemsBrought,
    required this.timestamp,
  });

  // --- Konvertierung zur Datenbank-Map ---

  Map<String, dynamic> toMap() {
    return {
      'registrationId': registrationId,
      'terminId': terminId,
      'userId': userId,
      'status': status, // Speichert 'JA' oder 'NEIN' als String
      'peopleCount': peopleCount,
      'itemsBrought': itemsBrought,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  String toJson() => json.encode(toMap());

  // --- Konvertierung von der Datenbank-Map ---

  factory EventRegistration.fromMap(Map<String, dynamic> map) {
    // Wandelt den String-Status aus der DB zurück in das Enum

    return EventRegistration(
      registrationId: map['registrationId'] as String,
      terminId: map['terminId'] as int,
      userId: map['userId'] as String,
      status: map['status'],
      peopleCount: map['peopleCount'] as int?,
      itemsBrought: map['itemsBrought'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  factory EventRegistration.fromJson(String source) =>
      EventRegistration.fromMap(json.decode(source));
}
