import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:verein_app/models/calendar_event.dart';

void exportEventAsIcs(CalendarEvent event) async {
  final icsContent = _generateIcsContent(event);
  final icsFilePath = await _saveIcsFile(event, icsContent);
  if (icsFilePath != null) {
    await _shareIcsFile(icsFilePath);
  }
}

String _generateIcsContent(CalendarEvent event) {
  final startDateTime = _formatDateTimeForIcs(event.date);
  final endDateTime =
      _formatDateTimeForIcs(event.date.add(const Duration(hours: 1)));

  return '''
BEGIN:VCALENDAR
VERSION:2.0
PRODID:TeG Altmuehlgrund
METHODE:PUBLISH
BEGIN:VEVENT
UID:event_${event.id}
LOCATION:Tennisplatz
SUMMARY:${event.title}
DESCRIPTION:${event.description}
CLASS:PUBLIC
DTSTART;TZID=UTC:$startDateTime
DTEND;TZID=UTC:$endDateTime
DTSTAMP:$startDateTime
END:VEVENT
END:VCALENDAR
'''
      .trimLeft(); // Entfernt unnötige Leerzeichen
}

Future<String?> _saveIcsFile(CalendarEvent event, String icsContent) async {
  try {
    final directory = await getTemporaryDirectory(); // Besser für das Teilen
    final sanitizedTitle = event.title
        .replaceAll(RegExp(r'[^\w\s]'), '_'); // Sonderzeichen ersetzen
    final icsFilePath = '${directory.path}/event_$sanitizedTitle.ics';
    final file = File(icsFilePath);
    await file.writeAsString(icsContent, encoding: utf8);

    return icsFilePath;
  } catch (e) {
    return null;
  }
}

Future<void> _shareIcsFile(String icsFilePath) async {
  try {
    final file = File(icsFilePath);
    if (await file.exists()) {
      print("Teile Datei: $icsFilePath");
      await Share.shareXFiles([XFile(icsFilePath)], text: 'Termin exportieren');
    } else {
      print("Fehler: Datei existiert nicht! Pfad: $icsFilePath");
    }
  } catch (e) {
    print("Fehler beim Teilen der Datei: $e");
  }
}

String _formatDateTimeForIcs(DateTime dateTime) {
  return DateFormat("yyyyMMdd'T'HHmmss'Z'")
      .format(dateTime.toUtc()); // Korrekte UTC-Zeit
}
