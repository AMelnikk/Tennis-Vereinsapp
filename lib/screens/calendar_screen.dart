import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/calendar_event.dart';
import '../providers/team_result_provider.dart';
import '../providers/termine_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/verein_appbar.dart';
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
  List<CalendarEvent> calendarEvents = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    int jahr = _focusedDay.year;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final termineProvider =
            Provider.of<TermineProvider>(context, listen: false);
        final ligaSpieleProvider =
            Provider.of<LigaSpieleProvider>(context, listen: false);

        await termineProvider.loadEvents(jahr);
        await ligaSpieleProvider.loadLigaSpiele(jahr);

        // Alle Events zusammenführen
        setState(() {
          calendarEvents = [
            ...termineProvider.events,
            ...ligaSpieleProvider.getLigaSpieleAsEvents(jahr),
          ];
        });
      } catch (e) {
        debugPrint("Fehler beim Laden der Events: $e");
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Arbeitseinsatz':
        return const Color(0xFFEF6C00); // Gedämpftes Orange
      case 'Termin':
        return const Color.fromARGB(255, 210, 25, 25); // Rot
      case 'Jugendtermin':
        return const Color(0xFF388E3C); // Gedämpftes Grün
      case 'Ligaspiel':
        return const Color.fromARGB(255, 29, 32, 185); // Gedämpftes Gelb
      default:
        return Colors.grey[600]!; // Standard Grau
    }
  }

  @override
  Widget build(BuildContext context) {
    final calendarProvider = Provider.of<TermineProvider>(context);

    return Scaffold(
      appBar: VereinAppbar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildMonthHeader(calendarProvider),
                  Expanded(
                    child: _buildCalendarView(calendarProvider),
                  ),
                  _buildNavigationButtons(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader(TermineProvider calendarProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              _buildPreviousMonthButton(),
              _buildNextMonthButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousMonthButton() {
    return IconButton(
      icon: const Icon(Icons.chevron_left, color: Colors.white),
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
    );
  }

  Widget _buildNextMonthButton() {
    return IconButton(
      icon: const Icon(Icons.chevron_right, color: Colors.white),
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
    );
  }

  Widget _buildCalendarView(TermineProvider calendarProvider) {
    return TableCalendar(
      locale: 'de_DE',
      firstDay: DateTime.utc(2024, 1, 1),
      lastDay: DateTime.utc(2028, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onPageChanged: (focusedDay) {
        // Aktualisiere den `focusedDay`, wenn der Benutzer wischt
        setState(() {
          _focusedDay = focusedDay;
        });
      },
      headerVisible: false,
      startingDayOfWeek: StartingDayOfWeek.monday,
      daysOfWeekHeight: 40,
      daysOfWeekStyle: _buildDaysOfWeekStyle(),
      calendarStyle: _buildCalendarStyle(),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          final eventsForDay = calendarEvents
              .where((event) =>
                  event.date.year == day.year &&
                  event.date.month == day.month &&
                  event.date.day == day.day)
              .toList();
          bool isOutsideCurrentMonth = day.month != _focusedDay.month;

          return _buildDayCell(day, eventsForDay, isOutsideCurrentMonth);
        },
      ),
      enabledDayPredicate: (day) {
        // Stelle sicher, dass alle Tage aktiv sind
        return true; // Gibt zurück, dass alle Tage aktiv sind
      },
    );
  }

  Widget _buildDayCell(DateTime day, List<CalendarEvent> eventsForDay,
      bool isOutsideCurrentMonth) {
    bool isToday =
        isSameDay(day, DateTime.now()); // Prüft, ob es der heutige Tag ist
    bool isSelected = isSameDay(
        day, _selectedDay); // Überprüft, ob es der ausgewählte Tag ist

    return GestureDetector(
      onTap: () {
        // Nur ein Popup anzeigen, wenn es Termine für den Tag gibt
        setState(() {
          _selectedDay = day; // Neuen ausgewählten Tag setzen
          _focusedDay = day; // Fokus-Tag aktualisieren
        });

        if (eventsForDay.isNotEmpty) {
          _showEventPopup(eventsForDay);
        }
      },
      child: Container(
        height: 160, // Zellenhöhe verringert für kompaktere Darstellung
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: isSameDay(day, _selectedDay)
                ? Colors.blueAccent
                : Colors.transparent,
            width: 2,
          ),
          // Optional: Ändere das Aussehen der Zelle, wenn sie außerhalb des aktuellen Monats ist
          backgroundBlendMode:
              isOutsideCurrentMonth ? BlendMode.darken : BlendMode.srcOver,
        ),
        padding: const EdgeInsets.all(0), // Weniger Abstand
        child: Stack(
          children: [
            // Wenn es der heutige Tag ist, wird der Tag im Kreis in der Mitte angezeigt
            if (isToday)
              Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(8), // <- 'const' nur hier
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${day.day}', // Muss dynamisch bleiben, daher kein 'const'
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            // Wenn es der ausgewählte Tag ist, zentrieren
            if (isSelected)
              Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            // Wenn es nicht der heutige oder ausgewählte Tag ist, oben rechts anzeigen
            if (!isToday && !isSelected)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4),
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(
                      fontSize: 10, // Einheitliche Schriftgröße
                      color: Colors.black54, // Dezente Farbe
                    ),
                  ),
                ),
              ),
            // Inhalte der Zelle
            Positioned.fill(
              child: _buildDayCellContent(eventsForDay),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCellContent(List<CalendarEvent> eventsForDay) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eventsForDay.isNotEmpty) ...[
          // Erster Event
          _buildEventItem(eventsForDay.first, () {
            _showEventDetails(context, eventsForDay.first);
          }),
          // Zweiter Event oder "+X mehr"
          if (eventsForDay.length > 1) ...[
            if (eventsForDay.length == 2)
              _buildEventItem(eventsForDay[1], () {
                _showEventDetails(context, eventsForDay[1]);
              })
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
    );
  }

  Widget _buildEventItem(CalendarEvent event, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 2,
          horizontal: 4,
        ),
        decoration: BoxDecoration(
          color: _getCategoryColor(event.category),
          borderRadius: BorderRadius.circular(0),
        ),
        child: Text(
          event.title,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildMonthViewButton(context),
        const SizedBox(width: 16),
        _buildListViewButton(context),
      ],
    );
  }

  Widget _buildMonthViewButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      onPressed: () {
        // Navigate to month view
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
    );
  }

  Widget _buildListViewButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(),
        ),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      onPressed: () {
        // Navigate to list view
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
    );
  }

  DaysOfWeekStyle _buildDaysOfWeekStyle() {
    return DaysOfWeekStyle(
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
          .substring(0, 2), // Nur die ersten 2 Buchstaben anzeigen
    );
  }

  CalendarStyle _buildCalendarStyle() {
    return CalendarStyle(
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
      outsideTextStyle: const TextStyle(fontSize: 10, color: Colors.grey),
      cellAlignment: Alignment.topRight,
    );
  }

  void _showEventPopup(List<CalendarEvent> eventsForDay) {
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
                                          .format(_selectedDay),
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
                                      child:
                                          Text("Keine Events für diesen Tag."),
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
                                              _showEventDetails(
                                                  dialogContext, event);
                                            },
                                            child: Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: _getCategoryColor(
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
            // Schließen Button oben rechts
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () {
                  Navigator.of(context).pop(); // Schließt den Dialog
                },
              ),
            ),
            // Titel in Blau und Fett
            Center(
              child: Text(
                event.category,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            const SizedBox(height: 8),

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
                onPressed: () => _exportEventAsIcs(event),
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
        print('Die Datei existiert nicht: $icsFilePath');
      }
    } catch (e) {
      print('Fehler beim Teilen der Datei: $e');
    }
  }

  String _formatDateTimeForIcs(DateTime dateTime) {
    return DateFormat('yyyyMMdd\'T\'HHmmss\'Z\'').format(dateTime.toUtc());
  }
}
