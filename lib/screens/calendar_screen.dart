import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:verein_app/models/calendar_event.dart';
import 'package:verein_app/popUps/calender_show_day_events_popup.dart';
import 'package:verein_app/popUps/calender_show_event_details_popup.dart';
import 'package:verein_app/providers/team_result_provider.dart';
import 'package:verein_app/providers/termine_provider.dart';
import 'package:verein_app/utils/app_colors.dart';
import 'package:verein_app/widgets/verein_appbar.dart';

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
          showEventPopup(context, eventsForDay, _selectedDay);
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
            showEventDetails(context, eventsForDay.first);
          }),
          // Zweiter Event oder "+X mehr"
          if (eventsForDay.length > 1) ...[
            if (eventsForDay.length == 2)
              _buildEventItem(eventsForDay[1], () {
                showEventDetails(context, eventsForDay[1]);
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
}
