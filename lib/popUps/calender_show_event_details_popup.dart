import 'package:flutter/material.dart';
import '../models/calendar_event.dart';
import '../utils/ics.dart';

void showEventDetails(BuildContext context, CalendarEvent event) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titel + Schließen-Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    event.category, // Falls `category` falsch ist
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              // Blaue Trennlinie
              Container(
                height: 2,
                color: Colors.blueAccent,
                margin: const EdgeInsets.symmetric(vertical: 8),
              ),

              // Scrollbare Beschreibung
              SizedBox(
                height: 150, // Max. Höhe für lange Inhalte
                child: SingleChildScrollView(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                        const TextSpan(
                            text: "Beschreibung:\n",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: "${event.title}\n"),
                        TextSpan(text: "${event.description}\n"),
                        TextSpan(text: "${event.von} - ${event.bis}\n"),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Export-Button
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () =>
                      exportEventAsIcs(ScaffoldMessenger.of(context), event),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                  ),
                  child: const Text("Termin exportieren"),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
