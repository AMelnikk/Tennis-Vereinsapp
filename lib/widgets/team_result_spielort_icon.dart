import 'package:flutter/widgets.dart';

/// Gibt ein Icon für den Spielort zurück.
/// Unterstützt aktuell "Ornbau" und "Weidenbach".
Widget getSpielortIcon(String spielort) {
  final ort = spielort.trim().toLowerCase();

  if (ort.contains("ornbau")) {
    return Image.asset(
      'assets/images/ornbau.png',
      width: 24,
      height: 24,
    );
  } else if (ort.contains("weidenbach")) {
    return Image.asset(
      'assets/images/Vereinslogo.png',
      width: 24,
      height: 24,
    );
  } else {
    return SizedBox(
        width: 24, height: 24); // Kein bekanntes Icon für diesen Ort
  }
}
