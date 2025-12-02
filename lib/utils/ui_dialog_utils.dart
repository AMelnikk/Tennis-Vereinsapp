import 'package:flutter/material.dart';

// Definierte Stile für Konsistenz
const TextStyle _titleStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.bold,
  color: Colors.blueAccent, // Konsistente Farbe
);

const TextStyle _subtitleStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: Colors.blueAccent, // Konsistente Farbe
);

const TextStyle _textStyle = TextStyle(
  fontSize: 14,
  color: Colors.black87, // Konsistente Farbe
);

final buttonStyle = ElevatedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
  backgroundColor: Colors.blue[900],
  foregroundColor: Colors.white,
);

/// Erzeugt konsistent formatierten Text für den Hauptinhalt des Dialogs.
Widget buildDialogBodyText(String text) {
  return Padding(
    // Konsistentes Padding für den Dialog-Text
    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
    child: Text(
      text,
      style: _textStyle,
    ),
  );
}

/// Erzeugt die Titelzeile eines Dialogs (Titel + Schließen-Button).
/// Die Farbe und Größe des Titels sind fest definiert.
Widget buildDialogTitleBar(BuildContext dialogContext, String title) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Text(
          title,
          style: _titleStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      // Schließen-Button
      IconButton(
        icon: const Icon(Icons.close, color: Colors.black54),
        onPressed: () => Navigator.of(dialogContext).pop(),
      ),
    ],
  );
}

/// Erzeugt die Untertitelzeile eines Dialogs (optionaler Tag/Kategorie + Datum).
/// Die Farbe und Größe des Untertitels sind fest definiert.
Widget buildDialogSubtitleBar({
  required String textLeft,
  required String textRight,
}) {
  return Padding(
    padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Kategorie/Tag (nur anzeigen, wenn nicht leer)
        if (textLeft.isNotEmpty)
          Text(
            textLeft,
            style: _subtitleStyle,
          ),

        // Datum
        if (textRight.isNotEmpty)
          Text(
            textRight,
            style: _subtitleStyle,
          ),
      ],
    ),
  );
}

Widget buildButton(String text, VoidCallback onPressed, {Icon? icon}) {
  if (icon != null) {
    // Wenn ein Icon übergeben wird, verwenden wir ElevatedButton.icon
    return ElevatedButton.icon(
      style: buttonStyle,
      icon: icon,
      label: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      onPressed: onPressed,
    );
  } else {
    // Ansonsten den Standard ElevatedButton verwenden
    return ElevatedButton(
      style: buttonStyle,
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

// Helper für den Ladehinweis (wird über das gesamte Fenster gelegt)
OverlayEntry showLoadingOverlay(BuildContext context) {
  final overlay = OverlayEntry(
    builder: (context) => Container(
      color: Colors.black54, // Dunkler Hintergrund
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Text(
                'Lade Anmeldungen...',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Overlay.of(context).insert(overlay);
  return overlay;
}

// Die Bestätigungs-Snackbar bleibt unverändert
void showConfirmation(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ),
  );
}

// NEUE Fehler-Snackbar
void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}

void showWarning(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Achtung: $message'),
      backgroundColor: Colors.yellow,
    ),
  );
}
