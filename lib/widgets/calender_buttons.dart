import 'package:flutter/material.dart';
import '../utils/app_utils.dart';

class CalendarViewSwitcher extends StatelessWidget {
  final VoidCallback onMonthViewPressed;
  final VoidCallback onListViewPressed;

  const CalendarViewSwitcher({
    super.key,
    required this.onMonthViewPressed,
    required this.onListViewPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildButton('Monat', onMonthViewPressed),
        const SizedBox(width: 16),
        buildButton('Liste', onListViewPressed),
      ],
    );
  }
}
