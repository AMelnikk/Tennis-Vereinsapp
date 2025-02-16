import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/providers/team_result_provider.dart';
import '../models/calendar_event.dart';
import '../popUps/calender_show_event_details_popup.dart';
import '../providers/termine_provider.dart';
import '../screens/calendar_screen.dart';
import '../widgets/calender_buttons.dart';

class CalenderListScreen extends StatefulWidget {
  const CalenderListScreen({super.key});
  static const routename = "/calendar_list";

  @override
  State<CalenderListScreen> createState() => _CalenderListScreenState();
}

class _CalenderListScreenState extends State<CalenderListScreen> {
  int currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    loadTermine(currentYear);
  }

  void _changeYear(int offset) {
    setState(() {
      currentYear += offset;
    });
    loadTermine(currentYear);
  }

  loadTermine(int jahr) async {
    try {
      final termineProvider =
          Provider.of<TermineProvider>(context, listen: false);
      final ligaSpieleProvider =
          Provider.of<LigaSpieleProvider>(context, listen: false);

      // Zuerst prüfen, ob die Events für das Jahr bereits geladen sind
      if (!termineProvider.eventsCache.containsKey(jahr)) {
        List<CalendarEvent> terminEvents =
            await termineProvider.loadEvents(jahr);
        // Liga-Spiele ebenfalls laden
        await ligaSpieleProvider.loadLigaSpieleForYear(jahr);
        List<CalendarEvent> lsEvents =
            ligaSpieleProvider.getLigaSpieleAsEvents(jahr);
        // Alle Events zusammenführen
        setState(() {
          List<CalendarEvent> calendarEvents = [
            ...terminEvents,
            ...lsEvents,
          ];
          termineProvider.eventsCache[jahr] = calendarEvents;
        });
        // Events für das Jahr im Cache speichern
      }
    } catch (e) {
      debugPrint("Fehler beim Laden der Events: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jahresübersicht $currentYear'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _changeYear(-1),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => _changeYear(1),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<TermineProvider>(
              builder: (context, termineProvider, child) {
                if (termineProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Termine nach Monaten gruppieren
                Map<String, List<CalendarEvent>> groupedEvents = {};
                List<CalendarEvent>? calEvents =
                    termineProvider.eventsCache[currentYear];

                if (calEvents != null) {
                  for (var event in calEvents) {
                    String monthKey =
                        DateFormat('MMMM yyyy', 'de_DE').format(event.date);
                    if (!groupedEvents.containsKey(monthKey)) {
                      groupedEvents[monthKey] = [];
                    }
                    groupedEvents[monthKey]!.add(event);
                  }
                }

                // Sortiere die Monate aufsteigend
                List<String> sortedMonths = groupedEvents.keys.toList()
                  ..sort((a, b) {
                    final monthA = DateFormat('MMMM yyyy', 'de_DE').parse(a);
                    final monthB = DateFormat('MMMM yyyy', 'de_DE').parse(b);
                    return monthA.compareTo(monthB);
                  });

                // Layout der Monatsübersicht
                return ListView.builder(
                  itemCount: sortedMonths.length,
                  itemBuilder: (context, index) {
                    String month = sortedMonths[index];
                    List<CalendarEvent> monthEvents = groupedEvents[month]!;

                    // Events nach Tagen gruppieren
                    Map<String, List<CalendarEvent>> eventsByDay = {};
                    for (var event in monthEvents) {
                      String dayKey =
                          DateFormat('yyyy-MM-dd').format(event.date);
                      if (!eventsByDay.containsKey(dayKey)) {
                        eventsByDay[dayKey] = [];
                      }
                      eventsByDay[dayKey]!.add(event);
                    }

                    // Tage aufsteigend sortieren
                    List<String> sortedDays = eventsByDay.keys.toList()..sort();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMonthHeader(month),
                        ...sortedDays.map((day) {
                          List<CalendarEvent> dayEvents = eventsByDay[day]!;

                          // Sortiere Events innerhalb eines Tages (ohne Uhrzeit zuerst)
                          dayEvents.sort((a, b) {
                            if (a.date.hour == 0 && a.date.minute == 0) {
                              return -1;
                            }
                            if (b.date.hour == 0 && b.date.minute == 0) {
                              return 1;
                            }
                            return a.date.compareTo(b.date);
                          });

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDayHeader(
                                  dayEvents.first.date), // Tagesüberschrift
                              ...dayEvents
                                  .map((event) => _buildDayEvents(event))
                                  ,
                            ],
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildNavigationButtons(
              context), // Korrekt platziert unterhalb der Event-Liste
        ],
      ),
    );
  }

  Widget _buildDayHeader(DateTime date) {
    String dateFormatted = DateFormat('dd MMMM yyyy', 'de_DE').format(date);
    String weekday = DateFormat('EEEE', 'de_DE').format(date);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateFormatted,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(
            weekday,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Methode zur Anzeige des Monatsheaders
  Widget _buildMonthHeader(String month) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        month,
        style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent),
      ),
    );
  }

  // Methode zur Anzeige der Event-Tage
  Widget _buildDayEvents(CalendarEvent event) {
    String time = DateFormat('HH:mm').format(event.date);

    return InkWell(
      onTap: () => showEventDetails(context, event), // Hier Popup aufrufen
      child: Row(
        children: [
          // Uhrzeit, falls vorhanden
          if (time != "00:00")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                time,
                style: TextStyle(fontSize: 14),
              ),
            ),
          // Event-Titel
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                event.title,
                style: TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return CalendarViewSwitcher(
      onMonthViewPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CalendarScreen()),
        );
      },
      onListViewPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CalenderListScreen()),
        );
      },
    );
  }
}
