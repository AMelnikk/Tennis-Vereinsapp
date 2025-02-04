import 'package:flutter/material.dart';

class AppColors {
  //Kalenderfarben
  static const Color arbeitseinsatz = Color(0xFFEF6C00); // Gedämpftes Orange
  static const Color termin = Color.fromARGB(255, 210, 25, 25); // Rot
  static const Color jugendtermin = Color(0xFF388E3C); // Gedämpftes Grün
  static const Color ligaspiel = Color.fromARGB(255, 29, 32, 185); // Blau
  static const Color standard = Colors.grey;

  //Team_Details
  static const Color ergCellNeutral = Colors.yellowAccent;
  static const Color ergCellGewonnen = Colors.green;
  static const Color ergCellUnentschieden = Colors.grey;
  static const Color ergCellVerloren = Colors.red;
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

Color getErgebnisCellColor(String ergebnisText, String heim, String gast) {
  Color ergebnisFarbe = AppColors.ergCellNeutral;
  bool ergebnisVorhanden =
      ergebnisText.isNotEmpty && ergebnisText.contains(":");

  if (ergebnisVorhanden) {
    List<String> ergebnisTeile = ergebnisText.split(":");
    int heimMatchpunkte = int.tryParse(ergebnisTeile[0]) ?? 0;
    int gastMatchpunkte = int.tryParse(ergebnisTeile[1]) ?? 0;

    if ((heimMatchpunkte > gastMatchpunkte && heim == "TeG Altmühlgrund") ||
        (heimMatchpunkte < gastMatchpunkte && gast == "TeG Altmühlgrund")) {
      ergebnisFarbe = AppColors.ergCellGewonnen;
    } else if (heimMatchpunkte == gastMatchpunkte) {
      ergebnisFarbe = AppColors.ergCellUnentschieden;
    } else {
      ergebnisFarbe = AppColors.ergCellVerloren;
    }
  }
  return ergebnisFarbe;
}
