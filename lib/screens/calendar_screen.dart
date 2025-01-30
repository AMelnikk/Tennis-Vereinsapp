import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:verein_app/models/calendar_event.dart';
import 'package:verein_app/providers/termine_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:verein_app/widgets/verein_appbar.dart';
import 'dart:convert'; // Für utf8-Encodierung

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  static const routename = "/calendar";

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
  }

  Future<void> _loadEvents() async {
    await Provider.of<TermineProvider>(context, listen: false).loadEvents();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Provider.of<TermineProvider>(context).events.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadEvents();
      });
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Arbeitseinsatz':
        return const Color(0xFFEF6C00); // Gedämpftes Orange
      case 'Termin':
        return const Color(0xFF1976D2); // Gedämpftes Blau
      case 'Jugendtermin':
        return const Color(0xFF388E3C); // Gedämpftes Grün
      case 'Ligaspiel':
        return const Color(0xFFFBC02D); // Gedämpftes Gelb
      default:
        return Colors.grey[600]!; // Standard Grau
    }
  }

  // void _showEventDialog(List events) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text("${DateFormat('dd.MM.yyyy').format(_selectedDay)}:"),
  //         content: SingleChildScrollView(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: events
  //                 .map(
  //                   (event) => Container(
  //                     margin: const EdgeInsets.symmetric(vertical: 4),
  //                     padding: const EdgeInsets.all(8),
  //                     decoration: BoxDecoration(
  //                       color: _getCategoryColor(event.kategorie),
  //                       borderRadius: BorderRadius.circular(8),
  //                     ),
  //                     child: Text(
  //                       event.title,
  //                       style: const TextStyle(color: Colors.white),
  //                     ),
  //                   ),
  //                 )
  //                 .toList(),
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text("Schließen"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final calendarProvider = Provider.of<TermineProvider>(context);

    return Scaffold(
      appBar: VereinAppbar(),
      body: SafeArea(
        child: Column(
          children: [
            // Kalender
            Expanded(
              child: Column(
                children: [
                  // Header mit Monatstitel und Navigation
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy', 'de_DE').format(_focusedDay),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left,
                                  color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                              ),
                              onPressed: () {
                                setState(() {
                                  _focusedDay = DateTime(
                                    _focusedDay.year,
                                    _focusedDay.month - 1,
                                  );
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right,
                                  color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                              ),
                              onPressed: () {
                                setState(() {
                                  _focusedDay = DateTime(
                                    _focusedDay.year,
                                    _focusedDay.month + 1,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TableCalendar(
                      locale: 'de_DE', // Deutsche Lokalisierung aktivieren
                      firstDay: DateTime.utc(2024, 1, 1),
                      lastDay: DateTime.utc(2028, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      headerVisible: false,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      daysOfWeekHeight: 40, // Erhöhte Höhe für die Wochentage
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                        weekendStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                        dowTextFormatter: (date, locale) => DateFormat.E(locale)
                            .format(date)
                            .substring(
                                0, 2), // Nur die ersten 2 Buchstaben anzeigen
                      ),
                      calendarStyle: CalendarStyle(
                        // Äußere Umrandung der Zellen
                        tableBorder: TableBorder.all(
                          color: Colors.grey[400]!, // Außenrand
                          width: 1, // Dicke des Randes
                        ),
                        todayDecoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        defaultTextStyle: const TextStyle(fontSize: 10),
                        weekendTextStyle: const TextStyle(fontSize: 10),
                        outsideTextStyle:
                            const TextStyle(fontSize: 10, color: Colors.grey),
                        cellAlignment: Alignment.topRight,
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          final eventsForDay = calendarProvider.events
                              .where((event) =>
                                  event.date.year == day.year &&
                                  event.date.month == day.month &&
                                  event.date.day == day.day)
                              .toList();

                          return GestureDetector(
                            onTap: () {
                              // Nur ein Popup anzeigen, wenn es Termine für den Tag gibt
                              if (eventsForDay.isNotEmpty) {
                                _showEventPopup(eventsForDay);
                              }
                            },
                            child: Container(
                              height: 150, // Zellenhöhe
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(
                                  color: isSameDay(day, _selectedDay)
                                      ? Colors.blueAccent
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),

                              padding: const EdgeInsets.all(4),
                              child: Stack(
                                children: [
                                  // Tag des Monats oben rechts
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 4, right: 4),
                                      child: Text(
                                        '${day.day}',
                                        style: const TextStyle(
                                          fontSize:
                                              8, // Einheitliche Schriftgröße
                                          color:
                                              Colors.black54, // Dezente Farbe
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Inhalte der Zelle
                                  Positioned.fill(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (eventsForDay.isNotEmpty) ...[
                                          // Erster Event
                                          GestureDetector(
                                            onTap: () {
                                              // Öffne direkt den Detailscreen für das erste Event
                                              _showEventDetails(
                                                  context, eventsForDay.first);
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 2,
                                                horizontal: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getCategoryColor(
                                                    eventsForDay
                                                        .first.kategorie),
                                                borderRadius:
                                                    BorderRadius.circular(0),
                                              ),
                                              child: Text(
                                                eventsForDay.first.title,
                                                style: const TextStyle(
                                                  fontSize: 8,
                                                  color: Colors.white,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ),
                                          // Zweiter Event oder "+X mehr"
                                          if (eventsForDay.length > 1) ...[
                                            if (eventsForDay.length == 2)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 2,
                                                  horizontal: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getCategoryColor(
                                                      eventsForDay[1]
                                                          .kategorie),
                                                  borderRadius:
                                                      BorderRadius.circular(0),
                                                ),
                                                child: Text(
                                                  eventsForDay[1].title,
                                                  style: const TextStyle(
                                                    fontSize: 7,
                                                    color: Colors.white,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              )
                                            else
                                              Text(
                                                '+${eventsForDay.length - 1} mehr',
                                                style: const TextStyle(
                                                  fontSize: 7,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                          ],
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                          backgroundColor: Colors.blue[900],
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          // Wechsle zur Monatsansicht
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CalendarScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Monat',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.horizontal(),
                          ),
                          backgroundColor: Colors.blue[900],
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          // Wechsle zur Terminliste
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CalendarScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Liste',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventPopup(List eventsForDay) {
    // Berechnete Position für die Mitte des Bildschirms
    Offset position = Offset(
      (MediaQuery.of(context).size.width - 300) /
          2, // Zentrierung basierend auf Breite
      (MediaQuery.of(context).size.height - 200) /
          2, // Zentrierung basierend auf Höhe
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              backgroundColor:
                  Colors.transparent, // Hintergrund des Dialogs transparent
              body: Stack(
                children: [
                  // Schließen des Dialogs, wenn der Hintergrund angetippt wird
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      color: Colors.black54,
                    ),
                  ),
                  // Verschiebbare Dialogbox
                  Positioned(
                    left: position.dx,
                    top: position.dy,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          position +=
                              details.delta; // Aktualisierung der Position
                        });
                      },
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: 300, // Breite der Box
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Schließen-Button
                              Align(
                                alignment: Alignment.topRight,
                                child: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                              // Datum anzeigen
                              Text(
                                DateFormat('dd. MMMM yyyy')
                                    .format(_selectedDay),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Liste der Events
                              eventsForDay.isEmpty
                                  ? const Center(
                                      child:
                                          Text("Keine Events für diesen Tag."),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: eventsForDay.length,
                                      itemBuilder: (context, index) {
                                        final event = eventsForDay[index];
                                        return GestureDetector(
                                          onTap: () {
                                            _showEventDetails(context, event);
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: _getCategoryColor(
                                                  event.kategorie),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.event,
                                                  color: Colors.white,
                                                ),
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

  void _showEventDetails(BuildContext context, CalendarEvent event) {
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
    return Stack(
      children: [
        Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize
                  .min, // Passt die Größe des Cards an den Inhalt an
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titel des Events
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Datum und Zeit
                Text(
                  DateFormat('dd.MM.yyyy HH:mm').format(event.date),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),

                // Kategorie
                Text(
                  'Kategorie: ${event.kategorie}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),

                // Beschreibung
                Text(
                  event.description,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),

                // Termin exportieren Button
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Termin exportieren Logik
                      _exportEventAsIcs(event);
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text("Termin exportieren"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // X oben rechts
        Positioned(
          right: 8,
          top: 8,
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              // Dialog schließen
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }

  void _exportEventAsIcs(CalendarEvent event) async {
    final icsContent = _generateIcsContent(event);
    final icsFilePath = await _saveIcsFile(event, icsContent);
    await _shareIcsFile(icsFilePath);
  }

  String _generateIcsContent(CalendarEvent event) {
    final startDateTime = _formatDateTimeForIcs(event.date);
    final endDateTime = _formatDateTimeForIcs(
        event.date.add(const Duration(hours: 1))); // Beispiel: 1 Stunde später

    final icsContent = '''
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//YourAppName//Event Exporter//EN
        BEGIN:VEVENT
        UID:event_${event.id}
        SUMMARY:${event.title}
        DTSTART:$startDateTime
        DTEND:$endDateTime
        DESCRIPTION:${event.description}
        STATUS:CONFIRMED
        END:VEVENT
        END:VCALENDAR
        ''';
    return icsContent;
  }

  Future<String> _saveIcsFile(CalendarEvent event, String icsContent) async {
    final directory = await getApplicationDocumentsDirectory();
    final icsFileName = 'event_${event.title}.ics';
    final icsFilePath = '${directory.path}/$icsFileName';

    await File(icsFilePath).writeAsString(icsContent, encoding: utf8);
    return icsFilePath;
  }

  Future<void> _shareIcsFile(String icsFilePath) async {
    try {
      // Überprüfen, ob die Datei existiert
      final file = File(icsFilePath);
      if (await file.exists()) {
        // Datei in ein XFile umwandeln
        final xFile = XFile(icsFilePath);

        // Teilen der Datei
        await Share.shareXFiles(
          [xFile], // Liste mit der Datei
          text: 'Termin exportieren', // Optionaler Text
        );
      } else {
        if(kDebugMode) print('Die Datei existiert nicht: $icsFilePath');
      }
    } catch (e) {
      if(kDebugMode) print('Fehler beim Teilen der Datei: $e');
    }
  }

  String _formatDateTimeForIcs(DateTime dateTime) {
    return DateFormat('yyyyMMdd\'T\'HHmmss\'Z\'').format(dateTime.toUtc());
  }
}
