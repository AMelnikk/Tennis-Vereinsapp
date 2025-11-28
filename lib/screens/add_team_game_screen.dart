import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../popUps/add_season_popup.dart';
import '../models/team.dart';
import '../models/tennismatch.dart';
import '../models/season.dart';
import '../providers/team_provider.dart';
import '../utils/app_utils.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final messenger = ScaffoldMessenger.of(context); // Vorher speichern
      final saisonProvider =
          Provider.of<SaisonProvider>(context, listen: false);
      List<SaisonData> loadedSeasons = await saisonProvider.getAllSeasons();

      if (mounted) {
        // Sicherstellen, dass das Widget noch existiert
        setState(() {
          if (loadedSeasons.isNotEmpty) {
            seasons = loadedSeasons;
            selectedSeason = seasons.first.key;
          }
          _isLoading = false;
        });
      } else {
        appError(messenger, "Widget wurde während des Ladevorgangs entfernt.");
      }
    });
  }

  Future<void> importCsvAndSaveToFirebase(String saisonKey) async {
    final messenger =
        ScaffoldMessenger.of(context); // Messenger vorher speichern
    final ligaSpieleProvider =
        Provider.of<LigaSpieleProvider>(context, listen: false);
    final teamProvider = Provider.of<TeamProvider>(context, listen: false);
    if (selectedSeason.isEmpty) {
      appError(messenger, "Bitte wählen Sie eine Saison aus.");
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
        if (!mounted) return;
        if (spiele.isNotEmpty) {
          // Altersklasse direkt mit Mannschaftskennung überschreiben
          for (var spiel in spiele) {
            String mannschaftskennung =
                extractMannschaftskennung(spiel.heim, spiel.gast);
            if (mannschaftskennung.isNotEmpty) {
              spiel.altersklasse =
                  "${spiel.altersklasse.trim()} ${mannschaftskennung.trim()}";
            }
          }

          await ligaSpieleProvider.saveLigaSpiele(spiele);

          // Extrahiere die eindeutigen Teams
          Set<Team> distinctTeams = extractDistinctTeams(spiele);

          // Füge die Teams hinzu oder aktualisiere sie
          await teamProvider.addOrUpdateTeams(
              messenger, saisonKey, distinctTeams);
          appError(messenger, "Spiele und Teams erfolgreich hochgeladen!");
        } else {
          appError(messenger, "Keine gültigen Spiele gefunden.");
        }
      } else {
        appError(messenger, "Keine Datei ausgewählt.");
      }
    } catch (error) {
      appError(messenger, "Fehler: $error");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Set<Team> extractDistinctTeams(List<TennisMatch> spiele) {
    Set<Team> distinctTeams = {};

    for (var spiel in spiele) {
      // Erstelle ein Team-Objekt mit der modifizierten Altersklasse
      Team team = Team.newteam(
        spiel.saison,
        spiel
            .altersklasse, // Hier wird die Altersklasse mit Mannschaftskennung verwendet
        spiel.spielklasse,
        spiel.gruppe,
      );

      distinctTeams.add(team);
    }

    return distinctTeams;
  }

// Funktion zur Extraktion der Mannschaftskennung
  String extractMannschaftskennung(String heim, String gast) {
    RegExp regex = RegExp(r'TeG Altmühlgrund(?: ([IVXLCDM]+))?');
    String mannschaftskennung = "";

    Match? heimMatch = regex.firstMatch(heim);
    if (heimMatch != null && heimMatch.group(1) != null) {
      mannschaftskennung = heimMatch.group(1)!;
    }

    Match? gastMatch = regex.firstMatch(gast);
    if (mannschaftskennung.isEmpty &&
        gastMatch != null &&
        gastMatch.group(1) != null) {
      mannschaftskennung = gastMatch.group(1)!;
    }

    return mannschaftskennung;
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
          id: '${saisonKey}_${fields[8]}',
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
          spielbericht: '',
          photoBlobSB: null,
        ));
      }
    }

    return spiele;
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
                        initialValue:
                            seasons.isNotEmpty ? selectedSeason : null,
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
                          onPressed: () async {
                            // Popup öffnen

                            final newSeason = await showAddSeasonPopup(context);

                            if (newSeason != null && mounted) {
                              setState(() {
                                seasons.add(newSeason);
                                selectedSeason = newSeason.key;
                              });
                            }

                            // Nach dem Schließen die Seasons neu laden
                            if (!context.mounted) return;
                            final saisonProvider = Provider.of<SaisonProvider>(
                                context,
                                listen: false);
                            final updatedSeasons =
                                await saisonProvider.getAllSeasons();

                            if (!mounted) return;

                            setState(() {
                              seasons = updatedSeasons;
                              if (updatedSeasons.isNotEmpty) {
                                // Neue Saison automatisch auswählen → letzte in der Liste
                                selectedSeason = updatedSeasons.last.key;
                              }
                            });
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
