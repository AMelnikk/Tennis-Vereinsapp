import 'package:flutter/foundation.dart';

/// Repräsentiert eine einzelne Chat-Nachricht im Firestore.
/// Wird vom TeamChatProvider verwendet, um die Daten aus Firestore zu mappen.
class ChatMessage with Diagnosticable {
  /// Eindeutige ID des Firestore-Dokuments
  final String id;

  /// Die UID des Benutzers, der die Nachricht gesendet hat
  final String userId;

  /// Der eigentliche Textinhalt der Nachricht
  final String text;

  /// Zeitstempel des Sendens (aus Firestore)
  final DateTime timestamp;

  final String userName;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.timestamp,
  });

  /// Gibt eine String-Repräsentation für Debugging aus
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('id', id));
    properties.add(StringProperty('userId', userId));
    properties.add(StringProperty('userName', userName));
    properties
        .add(StringProperty('text', text, showName: true, defaultValue: ''));
    properties.add(DiagnosticsProperty<DateTime>('timestamp', timestamp));
  }
}
