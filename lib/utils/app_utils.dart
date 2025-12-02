// ignore_for_file: unnecessary_brace_in_string_interps, unused_element

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

Widget buildTextFormField(
  String label, {
  required TextEditingController? controller,
  FormFieldValidator<String>? validator,
  bool readOnly = false,
  InputDecoration? decoration,
  // 🎯 Hinzugefügt für Kompatibilität mit Dialog-Aufrufen
  Icon? icon,
  TextInputType keyboardType = TextInputType.text,
  // Padding-Parameter aus Ihrer Vorgabe
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(vertical: 8.0),
  // Zusätzlich: Für Mehrzeiligkeit (z.B. Beschreibung)
  int maxLines = 1,
}) {
  // 1. Hintergrundfarbe basierend auf readOnly-Status bestimmen
  final Color baseFillColor = readOnly ? Colors.grey.shade200 : Colors.white;

  // 2. Das Basis-Decoration-Objekt erstellen
  final baseDecoration = InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 12),
    filled: true,
    fillColor: baseFillColor,
    border: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.black26),
    ),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
    ),
    icon: icon, // Icon hinzugefügt
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
  );

  // 3. Übergebenes Decoration-Objekt mit dem Basis-Objekt zusammenführen.
  final finalDecoration = (decoration != null)
      ? decoration.copyWith(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12),
          filled: true,
          fillColor: baseFillColor,
          icon: icon ?? decoration.icon, // Icon wird berücksichtigt
        )
      : baseDecoration;

  // 🎯 Das TextFormField in ein Padding-Widget einschließen
  return Padding(
    padding: padding, // Verwende den Übergabeparameter
    child: TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: finalDecoration,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
          color: readOnly ? Colors.black87 : Colors.black,
          fontWeight: readOnly ? FontWeight.w600 : FontWeight.normal),
    ),
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
    initialValue: value.isNotEmpty
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

// Helfer, um ein ReadOnly-Feld für die Details zu erstellen
Widget buildDetailField(String label, String value, {int maxLines = 1}) {
  // Verwendet die oben definierte buildTextFormField
  return buildTextFormField(
    label,
    controller: TextEditingController(text: value),
    readOnly: true,
    maxLines: maxLines,
    padding: const EdgeInsets.only(bottom: 8.0),
  );
}

// NEUE HILFSFUNKTION: Zeigt einen Ladehinweis, während die User-Daten geladen werden
OverlayEntry _showLoadingOverlay(BuildContext context) {
  final OverlayEntry entry = OverlayEntry(
    builder: (context) => Container(
      // Wir können Colors.black54 nicht verwenden, da es nicht im Kontext dieses Codes existiert
      // Wir nehmen eine einfache semitransparente Farbe
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    ),
  );
  Overlay.of(context).insert(entry);
  return entry;
}
