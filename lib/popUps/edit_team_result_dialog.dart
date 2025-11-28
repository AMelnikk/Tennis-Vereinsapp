import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/providers/news_provider.dart';
import 'package:verein_app/providers/team_result_provider.dart';
import 'package:verein_app/screens/add_news_screen.dart';
import '../models/tennismatch.dart';

Future<void> showEditTeamResultDialog(
  BuildContext context,
  TennisMatch match,
  Function(TennisMatch updatedMatch) onSave,
) async {
  final TextEditingController ergebnisController =
      TextEditingController(text: match.ergebnis);

  final TextEditingController datumController =
      TextEditingController(text: DateFormat('dd.MM.yyyy').format(match.datum));

  final TextEditingController uhrzeitController =
      TextEditingController(text: match.uhrzeit);

  final TextEditingController newsIdController =
      TextEditingController(text: match.spielbericht);

  TennisMatch updatedMatch =
      match.copyWith(); // Wichtig: clone statt direkt modifizieren

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Column(
          // <-- Von Row zu Column geändert
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ergebnis bearbeiten',
              style: TextStyle(
                fontSize: 18, // Etwas kleiner für Dialog-Titel
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ID: ${updatedMatch.id}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Datum
            Row(
              children: [
                Text('Datum: ${datumController.text}'),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final newDate = await showDatePicker(
                      context: context,
                      initialDate: updatedMatch.datum,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (newDate != null) {
                      setState(() {
                        updatedMatch = updatedMatch.copyWith(datum: newDate);
                        datumController.text =
                            DateFormat('dd.MM.yyyy').format(newDate);
                      });
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Uhrzeit
            Row(
              children: [
                Text('Uhrzeit: ${uhrzeitController.text}'),
                IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () async {
                    final newTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(
                        DateFormat('HH:mm').parse(updatedMatch.uhrzeit),
                      ),
                    );

                    if (newTime != null) {
                      final timeString =
                          "${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}";
                      setState(() {
                        updatedMatch =
                            updatedMatch.copyWith(uhrzeit: timeString);
                        uhrzeitController.text = timeString;
                      });
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Begegnung
            Text(
              'Begegnung: ${updatedMatch.heim} vs ${updatedMatch.gast}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 8),

            // Ergebnis
            TextField(
              controller: ergebnisController,
              decoration: const InputDecoration(
                // Klarer LabelText
                labelText: "Ergebnis eingeben",
                // Deutliches Beispiel im HintText, das verschwindet, wenn getippt wird
                hintText: "Format: Heim:Gast, z.B. 6:3",
              ),
              keyboardType: TextInputType
                  .text, // Beibehalten, da der Doppelpunkt (:) benötigt wird
              maxLines: 1, // Stellt sicher, dass die Eingabe nur eine Zeile ist
            ),
            const SizedBox(height: 8),
            // News ID + Button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: newsIdController,
                    decoration: const InputDecoration(labelText: "News ID"),
                    keyboardType: TextInputType.text,
                    enabled: false,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.article),
                  tooltip: "Spielbericht bearbeiten / erstellen",
                  onPressed: () async {
                    final newsProvider =
                        Provider.of<NewsProvider>(context, listen: false);
                    final lsProvider =
                        Provider.of<LigaSpieleProvider>(context, listen: false);

                    // Setze die Werte im newsProvider
                    newsProvider.newsId = newsIdController.text;
                    final String? newsId = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddNewsScreen(),
                      ),
                    );

                    // Wenn eine gültige News-ID zurückgegeben wurde, verarbeite sie
                    if (newsId?.isNotEmpty == true) {
                      setState(() {
                        newsIdController.text = newsId!;
                        updatedMatch.spielbericht = newsId;
                        lsProvider.updateLigaSpiel(updatedMatch);
                      });
                      newsProvider.newsId = newsId!;
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Abbrechen"),
          ),
          TextButton(
            onPressed: () {
              updatedMatch = updatedMatch.copyWith(
                ergebnis: ergebnisController.text,
                spielbericht: newsIdController.text,
              );

              onSave(updatedMatch);
              Navigator.pop(ctx);
            },
            child: const Text("Speichern"),
          ),
        ],
      ),
    ),
  );
}
