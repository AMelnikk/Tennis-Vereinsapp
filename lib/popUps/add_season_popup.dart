// Methode, um eine neue Saison anzulegen
// Dialog zur Saison-Erstellung
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/providers/season_provider.dart';
import '../models/season.dart';

void showAddSeasonPopup(BuildContext context) {
  final saisonProvider = Provider.of<SaisonProvider>(context, listen: false);
  final seasonController = TextEditingController(); // Controller für Saisonname
  final yearController = TextEditingController(
      text:
          DateTime.now().year.toString()); // Vorbelegung mit dem aktuellen Jahr
  String seasonType = 'Sommer'; // Standardmäßig Sommer
  final formKey = GlobalKey<FormState>(); // Für Validierung

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Neue Saison hinzufügen'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: yearController,
                decoration: const InputDecoration(labelText: 'Jahr'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty || value.length != 4) {
                    return 'Bitte geben Sie ein gültiges Jahr ein';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: seasonController,
                decoration: const InputDecoration(labelText: 'Saisonname'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte geben Sie einen Saisonname ein';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: seasonType,
                onChanged: (newValue) {
                  if (newValue != null) {
                    seasonType = newValue;
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'Sommer', child: Text('Sommer')),
                  DropdownMenuItem(value: 'Winter', child: Text('Winter')),
                ],
                decoration: const InputDecoration(labelText: 'Saisonart'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                String year = yearController.text;

                // Berechnung des Keys und der Jahre basierend auf Saisonart
                String seasonKey;
                int jahr1 = int.parse(year); // Jahr1 als int
                int jahr2 = -1; // Standardwert für Jahr2

                if (seasonType == 'Sommer') {
                  seasonKey = year; // Sommer = Jahr als Key
                } else {
                  // Winter-Saison
                  String nextYear = (int.parse(year) + 1).toString();
                  seasonKey =
                      '${year.substring(2)}_${nextYear.substring(2)}'; // Winter = Jahr1_Jahr2
                  jahr2 = int.parse(nextYear); // Jahr2 für Winter
                }

                // Neue Saison anlegen
                final saison = SaisonData(
                  saison: seasonController.text,
                  key: seasonKey,
                  jahr: jahr1,
                  jahr2: jahr2,
                );
                saisonProvider.saveSaison(saison);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Hinzufügen'),
          ),
        ],
      );
    },
  );
}
