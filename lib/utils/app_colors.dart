import 'package:flutter/material.dart';

class AppColors {
  static const Color arbeitseinsatz = Color(0xFFEF6C00); // Gedämpftes Orange
  static const Color termin = Color.fromARGB(255, 210, 25, 25); // Rot
  static const Color jugendtermin = Color(0xFF388E3C); // Gedämpftes Grün
  static const Color ligaspiel = Color.fromARGB(255, 29, 32, 185); // Blau
  static const Color standard = Colors.grey;
}

Color getCategoryColor(String category) {
  switch (category) {
    case 'Arbeitseinsatz':
      return AppColors.arbeitseinsatz;
    case 'Termin':
      return AppColors.termin;
    case 'Jugendtermin':
      return AppColors.jugendtermin;
    case 'Ligaspiel':
      return AppColors.ligaspiel;
    default:
      return AppColors.standard;
  }
}
