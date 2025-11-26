import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void appError(ScaffoldMessengerState messenger, String errorText) {
  messenger.showSnackBar(
    SnackBar(content: Text(errorText)),
  );
  if (kDebugMode) {
    print(errorText);
  }
}

List<String> parsePhotoBlob(dynamic blobData) {
  if (blobData == null) {
    return [];
  } else if (blobData is List) {
    // Wenn es bereits eine Liste ist (neues Format), casten
    return blobData.cast<String>();
  } else if (blobData is String && blobData.isNotEmpty) {
    // Wenn es ein einzelner String ist (altes Format), in Liste packen
    return [blobData];
  }
  return [];
}

Widget buildButton(String text, VoidCallback onPressed) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      backgroundColor: Colors.blue[900],
      foregroundColor: Colors.white,
    ),
    onPressed: onPressed,
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
  );
}

Widget buildTextFormField(
  String label, {
  required TextEditingController? controller,
  FormFieldValidator<String>? validator,
  // ✅ 1. NEU: Parameter readOnly hinzufügen (mit Standardwert false)
  bool readOnly = false,
  // ✅ 2. NEU: Parameter decoration hinzufügen, um die grüne Hinterlegung zu ermöglichen
  InputDecoration? decoration,
}) {
  // Das Standard-Decoration-Objekt erstellen, falls keines übergeben wurde
  final defaultDecoration = InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 10), // Kleinere Schrift für das Label
  );

  return TextFormField(
    controller: controller,
    // ✅ 3. readOnly an das TextFormField-Widget übergeben
    readOnly: readOnly,
    // ✅ 4. Übergebenes Decoration-Objekt verwenden, sonst das Standard-Objekt
    decoration: (decoration != null)
        ? decoration.copyWith(
            labelText: label, labelStyle: const TextStyle(fontSize: 12))
        : defaultDecoration,
    validator: validator,
  );
}

Widget buildTextFieldScrollable(
  String label, {
  required TextEditingController? controller,
  FormFieldValidator<String>? validator,
}) {
  return TextFormField(
    controller: controller,
    minLines: 8, // Startet mit 8 Zeilen
    maxLines: null, // Erlaubt Scrollen, wenn mehr Text eingegeben wird
    keyboardType: TextInputType.multiline,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14),
      border: OutlineInputBorder(),
    ),
    validator: validator,
  );
}

// Konvertiert eine Liste von Base64-Strings in eine Liste von Uint8List
List<Uint8List> decodePdfBlobs(dynamic jsonBlobs) {
  if (jsonBlobs == null) return [];

  // Annahme: Die Datenbank speichert eine Liste von Strings (Base64 kodiert)
  if (jsonBlobs is List) {
    return jsonBlobs
        .map((base64String) {
          if (base64String is String) {
            try {
              return base64Decode(base64String);
            } catch (e) {
              // Fehlerbehandlung falls der String nicht korrekt kodiert ist
              debugPrintThrottled('Fehler beim Dekodieren eines PDF-Blobs: $e');
              return Uint8List(0); // Leeren Byte-Array zurückgeben
            }
          }
          return Uint8List(0);
        })
        .where((bytes) => bytes.isNotEmpty)
        .toList();
  }
  return [];
}

// Konvertiert eine Liste von Uint8List in eine Liste von Base64-Strings
List<String> encodePdfBlobs(List<Uint8List> blobs) {
  // Wandelt jeden Uint8List-Eintrag in einen Base64-String um
  return blobs.map((bytes) => base64Encode(bytes)).toList();
}

Widget buildDropdownField({
  required String label,
  required String value,
  required List<String> items,
  required ValueChanged<String?> onChanged,
}) {
  return DropdownButtonFormField<String>(
    decoration: InputDecoration(
      labelText: label,
      labelStyle:
          const TextStyle(fontSize: 12), // Kleinere Schrift für das Label
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16, // Erhöhtes vertikales Padding für mehr Höhe
        horizontal: 16, // Horizontaler Raum bleibt gleich
      ),
      isDense: false, // Weniger kompaktes Layout, sodass es höher wird
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5), // Abgerundete Ecken
      ),
    ),
    value: value.isNotEmpty
        ? value
        : null, // Sicherstellen, dass null nicht zu Fehlern führt
    items: items.map<DropdownMenuItem<String>>((item) {
      return DropdownMenuItem<String>(
        value: item,
        child: Text(
          item,
          style: const TextStyle(
            fontSize: 12, // Größere Schrift für mehr Raum
          ),
          overflow:
              TextOverflow.ellipsis, // Verhindert Overflow bei langen Texten
        ),
      );
    }).toList(),
    onChanged: onChanged,
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Bitte eine Auswahl treffen';
      }
      return null;
    },
    isExpanded:
        true, // Stellt sicher, dass das Dropdown die gesamte Breite einnimmt
  );
}
