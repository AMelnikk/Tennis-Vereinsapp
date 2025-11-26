// Methode, um eine neue Saison anzulegen
// Dialog zur Saison-Erstellung
// ignore_for_file: unnecessary_brace_in_string_interps

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/providers/season_provider.dart';
import '../models/season.dart';

Future<SaisonData?> showAddSeasonPopup(BuildContext context) async {
  final saisonProvider = Provider.of<SaisonProvider>(context, listen: false);

  final yearController =
      TextEditingController(text: DateTime.now().year.toString());
  final year2Controller = TextEditingController(); // wird automatisch gesetzt
  final seasonNameController = TextEditingController(); // automatisch generiert

  String seasonType = 'Sommer';
  final formKey = GlobalKey<FormState>();
  SaisonData? newSeason; // Variable für die neue Saison

  // Hilfsfunktion, um Jahr2 + Saisonname automatisch zu setzen
  void updateFields() {
    int year1 = int.tryParse(yearController.text) ?? DateTime.now().year;

    if (seasonType == 'Sommer') {
      year2Controller.text = "-1";
      seasonNameController.text = "Sommer $year1";
    } else {
      int year2 = year1 + 1;
      year2Controller.text = year2.toString();
      seasonNameController.text = "Winter $year1/$year2";
    }
  }

  // Initiale Berechnung beim Öffnen
  updateFields();

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Neue Saison hinzufügen'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// SAISONART – erstes Feld
                  DropdownButtonFormField<String>(
                    value: seasonType,
                    decoration: const InputDecoration(labelText: 'Saisonart'),
                    items: const [
                      DropdownMenuItem(value: 'Sommer', child: Text('Sommer')),
                      DropdownMenuItem(value: 'Winter', child: Text('Winter')),
                    ],
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          seasonType = newValue;
                          updateFields();
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 10),

                  /// JAHR
                  TextFormField(
                    controller: yearController,
                    decoration: const InputDecoration(labelText: 'Jahr'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      setState(() => updateFields());
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length != 4) {
                        return 'Bitte ein gültiges Jahr eingeben';
                      }
                      return null;
                    },
                  ),

                  /// JAHR 2 – nur sichtbar bei Winter, nicht editierbar
                  if (seasonType == 'Winter')
                    TextFormField(
                      controller: year2Controller,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Jahr 2'),
                    ),

                  const SizedBox(height: 10),

                  /// SAISONNAME – NICHT EDITIERBAR
                  TextFormField(
                    controller: seasonNameController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Saisonname'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // null zurückgeben bei Abbrechen
                },
                child: const Text('Abbrechen'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    int jahr1 = int.parse(yearController.text);
                    int jahr2 = (seasonType == 'Sommer')
                        ? -1
                        : int.parse(year2Controller.text);

                    // Saisonkey berechnen
                    String seasonKey;
                    if (seasonType == 'Sommer') {
                      seasonKey = yearController.text;
                    } else {
                      String y1 = yearController.text.substring(2);
                      String y2 = year2Controller.text.substring(2);
                      seasonKey = "${y1}_${y2}";
                    }

                    // Saisonobjekt anlegen
                    newSeason = SaisonData(
                      saison: seasonNameController.text,
                      key: seasonKey,
                      jahr: jahr1,
                      jahr2: jahr2,
                    );

                    int status = await saisonProvider.saveSaison(newSeason!);

                    if (!context.mounted) return;
                    if (status == 200) {
                      Navigator.of(context).pop(newSeason); // zurückgeben
                    }
                  }
                },
                child: const Text('Hinzufügen'),
              ),
            ],
          );
        },
      );
    },
  );

  return newSeason; // Gibt null zurück, falls abgebrochen
}
