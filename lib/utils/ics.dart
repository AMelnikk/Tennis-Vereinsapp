import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:verein_app/models/calendar_event.dart';

void exportEventAsIcs(
    ScaffoldMessengerState messenger, CalendarEvent event) async {
  final icsContent = _generateIcsContent(event);
  final icsFilePath = await _saveIcsFile(event, icsContent);

  if (icsFilePath != null) {
    await _shareIcsFile(messenger, icsFilePath);
  } else {
    messenger.showSnackBar(
      const SnackBar(content: Text("Fehler beim Erstellen der ICS-Datei.")),
    );
  }
}

String _generateIcsContent(CalendarEvent event) {
  final startDateTime = _formatDateTimeForIcs(event.date);
  final endDateTime =
      _formatDateTimeForIcs(event.date.add(const Duration(hours: 1)));

  return '''
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//TeG Altmuehlgrund//NONSGML v1.0//DE
METHOD:PUBLISH
BEGIN:VEVENT
UID:${event.id}@teg-altmuehlgrund.de
LOCATION:Tennisplatz
SUMMARY:${event.title}
DESCRIPTION:${event.description}
CLASS:PUBLIC
DTSTART:$startDateTime
DTEND:$endDateTime
DTSTAMP:$startDateTime
END:VEVENT
END:VCALENDAR
'''
      .trim();
}

Future<String?> _saveIcsFile(CalendarEvent event, String icsContent) async {
  try {
    final directory =
        await getApplicationDocumentsDirectory(); // Stabilerer Speicherort
    final sanitizedTitle = event.title.replaceAll(RegExp(r'[^\w\s]'), '_');
    final icsFilePath = '${directory.path}/$sanitizedTitle.ics';
    final file = File(icsFilePath);
    await file.writeAsString(icsContent, encoding: utf8);
    return icsFilePath;
  } catch (e) {
    return null;
  }
}

Future<void> _shareIcsFile(
    ScaffoldMessengerState messenger, String icsFilePath) async {
  try {
    final file = File(icsFilePath);
    if (await file.exists()) {
      //await Share.shareXFiles(
      //  [XFile(icsFilePath, mimeType: 'text/calendar')],
      //  text: 'Termin exportieren',
      //);
    } else {
      messenger.showSnackBar(
        SnackBar(
            content: Text("Fehler: Datei nicht gefunden! Pfad: $icsFilePath")),
      );
    }
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text("Fehler beim Teilen der Datei: $e")),
    );
  }
}

String _formatDateTimeForIcs(DateTime dateTime) {
  return DateFormat("yyyyMMdd'T'HHmmss'Z'").format(dateTime.toUtc());
}
