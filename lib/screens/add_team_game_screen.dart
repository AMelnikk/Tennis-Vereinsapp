import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:verein_app/models/team.dart';
import 'package:verein_app/models/tennismatch.dart';
import 'package:verein_app/models/season.dart';
import 'package:verein_app/providers/team_provider.dart';
import '../providers/team_result_provider.dart';
import '../providers/season_provider.dart'; // Importiere den SaisonProvider
import '../widgets/verein_appbar.dart';

class AddLigaSpieleScreen extends StatefulWidget {
  const AddLigaSpieleScreen({super.key});
  static const routename = "/add-liga-spiele-screen";

  @override
  State<AddLigaSpieleScreen> createState() => _AddLigaSpieleScreenState();
}

class _AddLigaSpieleScreenState extends State<AddLigaSpieleScreen> {
  bool _isLoading = false;
  String selectedSeason = '';
  List<SaisonData> seasons = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final saisonProvider =
          Provider.of<SaisonProvider>(context, listen: false);
      List<SaisonData> loadedSeasons = await saisonProvider.getAllSeasons();

      if (loadedSeasons.isNotEmpty) {
        setState(() {
          seasons = loadedSeasons;
          selectedSeason = seasons.first.key;
          setState(() {
            _isLoading = false;
          });
        });
      } else {
        print("Keine Saisondaten gefunden!");
      }
    });
  }

  Future<void> importCsvAndSaveToFirebase(String saisonKey) async {
    if (selectedSeason.isEmpty) {
      showSnackBar("Bitte wählen Sie eine Saison aus.");
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        List<TennisMatch> spiele = [];

        if (kIsWeb || result.files.single.bytes != null) {
          // Web oder Bytes-Modus
          Uint8List? fileBytes = result.files.single.bytes;
          if (fileBytes != null) {
            // Wenn BOM vorhanden ist, wird es entfernt
            String csvString = utf8.decode(fileBytes, allowMalformed: true);
            if (csvString.startsWith("\u{FEFF}")) {
              // Entferne das BOM (Byte Order Mark)
              csvString = csvString.substring(1);
            }
            spiele = _parseCsv(csvString, saisonKey); // Parse the CSV string
          }
        }

        if (spiele.isNotEmpty) {
          await Provider.of<LigaSpieleProvider>(context, listen: false)
              .saveLigaSpiele(spiele);

          // Extrahiere die eindeutigen Teams
          Set<Team> distinctTeams = extractDistinctTeams(spiele);

          // Füge die Teams hinzu oder aktualisiere sie
          await Provider.of<TeamProvider>(context, listen: false)
              .addOrUpdateTeams(
                  saisonKey, distinctTeams); // Die Methode aufrufen

          if (!mounted) return; // Prüfen, ob das Widget noch existiert

          showSnackBar("Spiele und Teams erfolgreich hochgeladen!");
        } else {
          if (!mounted) return;

          showSnackBar("Keine gültigen Spiele gefunden.");
        }
      } else {
        showSnackBar("Keine Datei ausgewählt.");
      }
    } catch (error) {
      showSnackBar("Fehler: $error");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Set<Team> extractDistinctTeams(List<TennisMatch> spiele) {
    Set<Team> distinctTeams = {};

    for (var spiel in spiele) {
      // Erstelle ein Team-Objekt aus den drei Feldern
      Team team = Team.newteam(
        spiel.saison,
        spiel.altersklasse,
        spiel.spielklasse,
        spiel.gruppe,
      );
      distinctTeams.add(
          team); // Das Set stellt sicher, dass es nur eindeutige Teams gibt
    }

    return distinctTeams;
  }

  List<TennisMatch> _parseCsv(String csvString, String saisonKey) {
    List<TennisMatch> spiele = [];
    List<String> lines = csvString.split('\n');

    // Loop through the lines and parse each line
    for (var i = 1; i < lines.length; i++) {
      List<String> fields = lines[i].split(';');
      if (fields.length >= 10) {
        int index = fields[5].indexOf("Gr");
        String gruppe = fields[5].substring(index);
        final String datumString = fields[0]; // "19.10.2024"
        final DateFormat dateFormat = DateFormat("dd.MM.yyyy");
        DateTime? datum = dateFormat.parse(datumString);
        spiele.add(TennisMatch(
          id: fields[8],
          datum: datum,
          uhrzeit: fields[1],
          altersklasse: fields[2],
          spielklasse: fields[3],
          gruppe: gruppe,
          heim: fields[6],
          gast: fields[7],
          spielort: fields[9],
          saison: saisonKey,
          ergebnis: '',
        ));
      }
    }

    return spiele;
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // Methode, um eine neue Saison anzulegen
  // Dialog zur Saison-Erstellung
  void _showAddSeasonPopup(BuildContext context) {
    final saisonProvider = Provider.of<SaisonProvider>(context, listen: false);
    final seasonController =
        TextEditingController(); // Controller für Saisonname
    final yearController = TextEditingController(
        text: DateTime.now()
            .year
            .toString()); // Vorbelegung mit dem aktuellen Jahr
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VereinAppbar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    const Text(
                      "Liga-Spiele aus CSV importieren",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20),
                    ),
                    // Dropdown für Saison
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: DropdownButtonFormField<String>(
                        value: seasons.isNotEmpty ? selectedSeason : null,
                        hint: const Text('Wählen Sie eine Saison'),
                        items: seasons.map<DropdownMenuItem<String>>((season) {
                          return DropdownMenuItem<String>(
                            value: season.key,
                            child: Text(season.saison),
                          );
                        }).toList(),
                        onChanged: seasons.isNotEmpty
                            ? (value) {
                                setState(() {
                                  selectedSeason = value!;
                                });
                              }
                            : null, // Deaktiviert Dropdown, falls seasons leer ist
                      ),
                    ),
                    // Add-Button für Saison hinzufügen
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _showAddSeasonPopup(context);
                          },
                          child: const Text('Neue Saison hinzufügen'),
                        ),
                      ],
                    ),
                    // Button zum Hochladen der CSV-Datei
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: ElevatedButton(
                        onPressed: () =>
                            importCsvAndSaveToFirebase(selectedSeason),
                        child: Container(
                          alignment: Alignment.center,
                          width: double.infinity,
                          height: 50,
                          child: const Text(
                            "CSV-Datei importieren",
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
