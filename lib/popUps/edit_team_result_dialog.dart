import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/providers/news_provider.dart';
import 'package:verein_app/providers/team_result_provider.dart';
import 'package:verein_app/screens/add_news_screen.dart';
import 'package:verein_app/utils/app_utils.dart';
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
      builder: (ctx, setState) {
        // 1. DYNAMISCHE HÖHENBERECHNUNG FÜR DIE KORREKTUR
        // Wir verwenden ctx hier, da es der Builder-Context ist (obwohl context auch funktionieren würde).
        final screenHeight = MediaQuery.of(ctx).size.height;
        // Setze eine sichere Max-Höhe für den Inhalt (z.B. 65%), um Platz für Tastatur, Titel und Aktionen zu lassen.
        final maxDialogContentHeight = screenHeight * 0.65;

        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ergebnis bearbeiten',
                style: TextStyle(
                  fontSize: 18,
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

          // 💡 KORREKTUR DER CONTENT-STRUKTUR START
          content: ConstrainedBox(
            // 1. Begrenzt die Höhe des Dialog-Contents
            constraints: BoxConstraints(maxHeight: maxDialogContentHeight),
            child: SingleChildScrollView(
              // 2. Ermöglicht Scrollen, wenn die Tastatur den Platz reduziert
              child: Column(
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
                              updatedMatch =
                                  updatedMatch.copyWith(datum: newDate);
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
                  buildTextFormField(
                    "Ergebnis eingeben", // label
                    controller: ergebnisController,
                    keyboardType: TextInputType
                        .text, // Muss Text bleiben wegen des Doppelpunkts (:)
                    maxLines: 1,
                    icon: const Icon(Icons.sports_score_outlined),
                    // Spezielle Decoration für den HintText, da Ihr Helper dies nicht standardmäßig setzt:
                    decoration: const InputDecoration(
                      hintText: "Format: Heim:Gast, z.B. 6:3",
                    ),
                  ),

                  const SizedBox(height: 8),

                  // News ID + Button
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newsIdController,
                          decoration:
                              const InputDecoration(labelText: "News ID"),
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
                          final lsProvider = Provider.of<LigaSpieleProvider>(
                              context,
                              listen: false);

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
                              updatedMatch =
                                  updatedMatch.copyWith(spielbericht: newsId);
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
            ),
          ),
          // 💡 KORREKTUR DER CONTENT-STRUKTUR ENDE

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
        );
      },
    ),
  );
}
