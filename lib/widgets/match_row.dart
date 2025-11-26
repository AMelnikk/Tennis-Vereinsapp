import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:verein_app/screens/news_detail_screen.dart';
import '../utils/app_colors.dart';
import '../models/tennismatch.dart';

class MatchRow extends StatelessWidget {
  final TennisMatch spiel;
  final String teamName;

  final Function(TennisMatch)? onEdit;
  final Function(TennisMatch)? onDelete;

  const MatchRow({
    super.key,
    required this.spiel,
    required this.teamName,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    String heim = spiel.heim.startsWith("TeG Altmühlgrund")
        ? spiel.altersklasse
        : spiel.heim;
    String gast = spiel.gast.startsWith("TeG Altmühlgrund")
        ? spiel.altersklasse
        : spiel.gast;

    Color ergebnisFarbe =
        getErgebnisCellColor(spiel.ergebnis, spiel.heim, spiel.gast);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Heim Box (35% der Gesamtbreite)
        Expanded(
          flex: 37,
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
            // Wir nutzen Stack, um Icons über den Text zu legen, ohne das Layout zu sprengen
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Dein bestehender Inhalt (Text/Datum) - bleibt unverändert
                Column(
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

                // 2. Die neuen Icons (rechtsbündig positioniert)
                // Fall A: Ergebnis existiert -> Editieren & Löschen (weiß, weil Hintergrund farbig)
                if (spiel.ergebnis.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Edit Icon (klein)
                        if (onEdit !=
                            null) // <--- NUR ANZEIGEN, WENN onEdit NICHT NULL IST
                          InkWell(
                            onTap: () => onEdit!
                                .call(spiel), // Jetzt sicher mit `!` aufrufbar
                            child: const Padding(
                              padding: EdgeInsets.all(2.0),
                              child: Icon(Icons.edit,
                                  size: 16, color: Colors.white70),
                            ),
                          ),

                        // **KORREKTUR für Delete-Icon:**
                        if (onDelete !=
                            null) // <--- NUR ANZEIGEN, WENN onDelete NICHT NULL IST
                          InkWell(
                            onTap: () => onDelete!
                                .call(spiel), // Jetzt sicher mit `!` aufrufbar
                            child: const Padding(
                              padding: EdgeInsets.all(2.0),
                              child: Icon(Icons.delete,
                                  size: 16, color: Colors.white70),
                            ),
                          ),
                      ],
                    ),
                  ),
                // Fall B: Kein Ergebnis -> Nur Eintragen (dunkelgrau, weil Hintergrund weiß)
                if (spiel.ergebnis.isEmpty)
                  if (onEdit !=
                      null) // <-- Bedingung für das Ausblenden des Icons
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: InkWell(
                        onTap: () => onEdit!
                            .call(spiel), // Wichtig: `!` da auf null geprüft
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.edit_note,
                              size: 18, color: Colors.black54),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
        // Gast Box (35% der Gesamtbreite)
        Expanded(
          flex: 37,
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
        Expanded(
          flex: 6,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.black, width: 0.5),
            ),
            child: Column(
              // Jetzt zentriert, da maximal ein Icon sichtbar ist
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Spielbericht Lesen (Nur sichtbar, wenn Spielbericht-ID vorhanden)
                if (spiel.spielbericht.isNotEmpty)
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        // ANFÜHRUNGSZEICHEN ENTFERNEN und Klasse direkt verwenden
                        NewsDetailScreen.routename,
                        arguments: spiel.spielbericht,
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Icon(
                        Icons.article, // NEUES ICON: Ein Artikel/Dokument
                        size: 20, // Etwas größer, da es das einzige Icon ist
                        color: Colors.teal, // Beispielhafte Farbe
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
