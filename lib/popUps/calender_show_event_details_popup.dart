import 'package:flutter/material.dart';
import '../models/calendar_event.dart';
import '../utils/ics.dart';

void showEventDetails(BuildContext context, CalendarEvent event) {
  showDialog(
    context: context,
    barrierDismissible:
        false, // Dialog kann nur durch Schließen-Button geschlossen werden
    builder: (BuildContext context) {
      return Draggable(
        feedback: Material(
          type: MaterialType.transparency,
          child: _buildEventDetailsCard(context, event),
        ),
        childWhenDragging: const SizedBox.shrink(),
        child: Center(
          child: _buildEventDetailsCard(context, event),
        ),
      );
    },
  );
}

Widget _buildEventDetailsCard(BuildContext context, CalendarEvent event) {
  final messenger = ScaffoldMessenger.of(context); // Messenger holen
  return Dialog(
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero), // Eckiger Rahmen
    child: Container(
      width: 300, // Weniger breit
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titel und Schließen-Button in einer Zeile
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                event.category,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () {
                  Navigator.of(context).pop(); // Schließt den Dialog
                },
              ),
            ],
          ),

          // Blaue Trennlinie
          Container(
            height: 2,
            color: Colors.blueAccent,
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),

          // Kategorie + Teams
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 16, color: Colors.black),
              children: [
                const TextSpan(text: "Beschreibung:\n"),
                TextSpan(text: "${event.title}\n"),
                TextSpan(text: event.description),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Termin-Export Button in Blau
          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              onPressed: () => exportEventAsIcs(messenger, event),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // Eckiger Button
                ),
              ),
              child: const Text("Termin exportieren"),
            ),
          ),
        ],
      ),
    ),
  );
}
