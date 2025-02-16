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
}) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      labelStyle:
          const TextStyle(fontSize: 14), // Kleinere Schrift für das Label
    ),
    validator: validator,
  );
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
          const TextStyle(fontSize: 14), // Kleinere Schrift für das Label
      contentPadding: const EdgeInsets.symmetric(
          vertical: 0, horizontal: 0), // Weniger Padding
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
              fontSize: 14), // Kleinere Schrift für Dropdown-Text
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
  );
}
