import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../models/tennismatch.dart';

class MatchRow extends StatelessWidget {
  final TennisMatch spiel;
  final String teamName;

  const MatchRow({
    super.key,
    required this.spiel,
    required this.teamName,
  });

  @override
  Widget build(BuildContext context) {
    String heim =
        spiel.heim == "TeG Altmühlgrund" ? spiel.altersklasse : spiel.heim;
    String gast =
        spiel.gast == "TeG Altmühlgrund" ? spiel.altersklasse : spiel.gast;

    Color ergebnisFarbe =
        getErgebnisCellColor(spiel.ergebnis, spiel.heim, spiel.gast);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Heim Box (35% der Gesamtbreite)
        Expanded(
          flex: 40,
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 0),
            decoration: BoxDecoration(
              color: heim == teamName ? Colors.blueAccent : Colors.white,
              border: Border.all(color: Colors.black, width: 0.5),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              " $heim",
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
        // Ergebnis Box (20% der Gesamtbreite)
        Expanded(
          flex: 20,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: ergebnisFarbe,
              border: Border.all(color: Colors.black, width: 0.5),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (spiel.ergebnis.isEmpty) ...[
                  Text(
                    DateFormat('dd.MM.yy').format(spiel.datum),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    spiel.uhrzeit,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
                if (spiel.ergebnis.isNotEmpty) ...[
                  Text(
                    spiel.ergebnis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    DateFormat('dd.MM.yy').format(spiel.datum),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ),
        ),
        // Gast Box (35% der Gesamtbreite)
        Expanded(
          flex: 40,
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 0),
            decoration: BoxDecoration(
              color: gast == teamName ? Colors.blueAccent : Colors.white,
              border: Border.all(color: Colors.black, width: 0.5),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              " $gast",
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }
}
