import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/calendar_event.dart';
import '../popUps/calender_show_day_events_popup.dart';
import '../popUps/calender_show_event_details_popup.dart';
import '../providers/team_result_provider.dart';
import '../providers/termine_provider.dart';
import '../screens/calender_list_screen.dart';
import '../utils/app_colors.dart';
import '../widgets/calender_buttons.dart';
import '../widgets/verein_appbar.dart';

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
    int jahr = _focusedDay.year;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      loadTermine(jahr);
    });
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
  void didChangeDependencies() {
    super.didChangeDependencies();
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
          loadTermine(_focusedDay.year);
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
          loadTermine(_focusedDay.year);
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

        final eventsForSelectedDay = calendarProvider
                .eventsCache[selectedDay.year]
                ?.where((event) => isSameDay(event.date, selectedDay))
                .toList() ??
            [];

        if (eventsForSelectedDay.isNotEmpty) {
          showEventPopup(context, eventsForSelectedDay, _selectedDay);
        }
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
          final List<CalendarEvent> eventsForDay =
              calendarProvider.eventsCache[day.year] != null
                  ? calendarProvider.eventsCache[day.year]!
                      .where((event) =>
                          event.date.year == day.year &&
                          event.date.month == day.month &&
                          event.date.day == day.day)
                      .toList()
                  : [];
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
    bool isToday = isSameDay(day, DateTime.now());
    bool isSelected = isSameDay(day, _selectedDay);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDay = day;
          _focusedDay = day;
        });

        if (eventsForDay.isNotEmpty) {
          showEventPopup(context, eventsForDay, _selectedDay);
        }
      },
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(4),
        child: Stack(
          children: [
            // Hintergrund: Wird hinter allem anderen gerendert
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
                Expanded(child: Container()),
              ],
            ),

            // Zuerst die Events anzeigen (über dem Hintergrund)
            Positioned.fill(
              child: Align(
                alignment: Alignment.topLeft, // Links ausrichten
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 10, left: 10), // Leichter Abstand
                  child: _buildDayCellContent(eventsForDay),
                ),
              ),
            ),

            // Dann der Kreis für den selektierten oder heutigen Tag
            if (isSelected || isToday)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? Colors.blue
                              .withValues(blue: 0.5) // Selektierter Tag
                          : Colors.transparent, // Heute-Kreis
                    ),
                    child: const SizedBox.shrink(),
                  ),
                ),
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
            showCalendarEventDetails(context, eventsForDay.first);
          }),
          // Zweiter Event oder "+X mehr"
          if (eventsForDay.length > 1) ...[
            if (eventsForDay.length == 2)
              _buildEventItem(eventsForDay[1], () {
                showCalendarEventDetails(context, eventsForDay[1]);
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
          color: getCategoryColor(event.category),
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
      tableBorder: TableBorder.all(
        color: Colors.grey[400]!, // Einheitliche Umrandung für alle Zellen
        width: 1,
      ),
      defaultTextStyle: const TextStyle(fontSize: 10),
      weekendTextStyle: const TextStyle(fontSize: 10),
      outsideTextStyle: const TextStyle(fontSize: 10, color: Colors.grey),
      cellAlignment: Alignment.topRight,
      todayDecoration: BoxDecoration(
        color: Colors.transparent, // Verhindert das Verdecken durch den Kreis
        shape: BoxShape.circle, // Kreisform
      ),
      selectedDecoration: BoxDecoration(
        color: Colors.transparent, // Verhindert das Verdecken durch den Kreis
        shape: BoxShape.circle, // Kreisform
      ),
    );
  }
}
