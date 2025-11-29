import 'package:flutter/material.dart';
import '../models/calendar_event.dart';
import '../utils/ics.dart';

/// Zeigt ein modales Dialogfenster mit allen Details eines Kalenderereignisses an.
void showCalendarEventDetails(BuildContext context, CalendarEvent event) {
  // Funktion zum Erstellen eines formatierten Textfeldes
  Widget buildDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  showDialog(
    context: context,
    barrierDismissible: true, // Ermöglicht das Schließen durch Tippen außerhalb
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 340,
          constraints: const BoxConstraints(maxHeight: 500),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Titel und Schließen-Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      event.title, // Haupttitel des Events
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              // Kategorie/Tag
              if (event.category.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
                  child: Text(
                    event.category,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),

              const Divider(height: 1, thickness: 1, color: Colors.black12),
              const SizedBox(height: 12),

              // 2. Scrollbarer Detailbereich (Zeit & Beschreibung)
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Zeitangaben
                      buildDetailRow("Zeitraum", "${event.von} - ${event.bis}"),

                      // Beschreibung (als langen Textblock)
                      if (event.description.isNotEmpty)
                        buildDetailRow("Details", event.description),

                      // Optional: Ort (Hier wird der Ort ausgegeben, wenn er nicht leer ist)
                      if (event.ort.isNotEmpty)
                        buildDetailRow("Ort", event.ort),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Export-Button
              Align(
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Schließt den Dialog und führt dann den Export durch
                    Navigator.of(context).pop();
                    exportEventAsIcs(ScaffoldMessenger.of(context), event);
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 20),
                  label: const Text("Termin exportieren"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
