import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:verein_app/providers/termine_provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  static const routename = "/calendar";

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
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
    // Sicherstellen, dass der Provider noch keine Events geladen hat
    if (Provider.of<TermineProvider>(context).events.isEmpty) {
      // Verwende WidgetsBinding, um den State nach dem Build zu setzen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadEvents(); // Lade die Events nachdem das Widget gebaut wurde
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final calendarProvider = Provider.of<TermineProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Kalender')),
      body: calendarProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // TableCalendar mit vereinfachtem Styling
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2025, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay =
                          focusedDay; // Stellen sicher, dass auch _focusedDay aktualisiert wird
                    });
                  },
                  eventLoader: (day) {
                    // Überprüfe, ob die Events auch für den neuen Monat geladen werden
                    return calendarProvider.events
                        .where((event) =>
                            event.date.year == day.year &&
                            event.date.month == day.month &&
                            event.date.day == day.day)
                        .map((e) => e.title)
                        .toList();
                  },
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false, // Verstecke den Format-Button
                    titleCentered: true, // Titel in der Mitte
                    decoration: BoxDecoration(
                      color: Colors.blueAccent, // Header-Hintergrundfarbe
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    leftChevronIcon: Icon(
                      Icons.arrow_left,
                      color: Colors.white,
                    ),
                    rightChevronIcon: Icon(
                      Icons.arrow_right,
                      color: Colors.white,
                    ),
                    headerMargin: EdgeInsets.only(bottom: 8),
                  ),
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.orange, // Heute-Hervorhebung
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.green, // Ausgewählter Tag
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle:
                        TextStyle(color: Colors.red), // Wochenend-Tage
                  ),
                ),
                // Terminliste für den ausgewählten Tag
                Expanded(
                  child: ListView(
                    children: calendarProvider.events
                        .where((event) =>
                            event.date.year == _selectedDay.year &&
                            event.date.month == _selectedDay.month &&
                            event.date.day == _selectedDay.day)
                        .map((e) => ListTile(
                              title: Text(e.title),
                              subtitle: Text(e.date.toIso8601String()),
                              onTap: () {
                                // Event Details anzeigen oder bearbeiten
                              },
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
    );
  }
}
