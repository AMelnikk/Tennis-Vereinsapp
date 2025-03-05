import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/calendar_event.dart';
import '../popUps/calender_show_event_details_popup.dart';
import '../utils/app_colors.dart';

void showEventPopup(BuildContext context, List<CalendarEvent> eventsForDay,
    DateTime selectedDay) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          // Initiale Position für Zentrierung
          Offset position = Offset(
            (MediaQuery.of(dialogContext).size.width - 300) / 2,
            (MediaQuery.of(dialogContext).size.height - 200) / 2,
          );

          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // Hintergrund zum Schließen des Popups
                GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  child: Container(color: Colors.black54),
                ),
                // Verschiebbares Popup
                Positioned(
                  left: position.dx,
                  top: position.dy,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        position += details.delta; // Position aktualisieren
                      });
                    },
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: 300,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // "X"-Button oben rechts
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.black),
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(
                                    height: 8), // Platz für den "X"-Button
                                // Datum anzeigen
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8.0, right: 32),
                                  child: Text(
                                    DateFormat('dd. MMMM yyyy')
                                        .format(selectedDay),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Event-Liste
                                if (eventsForDay.isEmpty)
                                  const Center(
                                    child: Text("Keine Events für diesen Tag."),
                                  )
                                else
                                  SizedBox(
                                    height:
                                        500, // Begrenzte Höhe für Scrollbarkeit
                                    child: ListView.builder(
                                      itemCount: eventsForDay.length,
                                      itemBuilder: (context, index) {
                                        final event = eventsForDay[index];
                                        return GestureDetector(
                                          onTap: () {
                                            showCalendarEventDetails(
                                                dialogContext, event);
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: getCategoryColor(
                                                  event.category),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.event,
                                                    color: Colors.white),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    event.title,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
