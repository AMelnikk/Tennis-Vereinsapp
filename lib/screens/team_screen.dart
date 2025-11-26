// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_utils.dart';
import '../models/season.dart';
import '../providers/season_provider.dart';
import '../models/team.dart';
import '../providers/team_provider.dart';
import '../widgets/team_tile.dart';
import '../widgets/verein_appbar.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});
  static const routename = "/team-screen";

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  // ignore: unused_field
  var _isLoading = true;
  bool _isInitialized = false;
  List<Team> filteredTeams = [];
  List<SaisonData> filterSeasons = [];
  SaisonData? selectedSeason;
  String selectedAgeGroup = 'All';

  @override
  void initState() {
    super.initState();

    // Die gesamte einmalige Ladelogik wird hier gestartet
    if (!_isInitialized) {
      _isInitialized = true; // Flag sofort setzen

      // WidgetsBinding.instance.addPostFrameCallback
      // wartet, bis der Widget-Baum aufgebaut ist und context verfügbar ist.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Sicherstellen, dass das Widget noch existiert, bevor context verwendet wird
        if (!mounted) return;

        // Da wir uns jetzt in initState befinden, müssen wir den Ladezustand
        // sofort setzen, bevor die asynchrone Arbeit beginnt.
        if (mounted) {
          setState(() {
            _isLoading = true;
          });
        }

        final messenger = ScaffoldMessenger.of(context);

        // 1. Alle Daten laden und State setzen
        await loadSeasonData(messenger);

        // 2. Teams laden, nachdem selectedSeason gesetzt wurde (in loadSeasonData)
        if (selectedSeason != null && mounted) {
          await getData(messenger);
        }

        // 3. Ladezustand beenden
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // DIESER BLOCK BLEIBT NUN LEER
    // Er wird nur verwendet, wenn sich Provider-Abhängigkeiten ändern,
    // was hier nicht für die Erstinitialisierung notwendig ist.
  }

  // ... (loadSeasonData, getData und build bleiben wie in der letzten Korrektur)

  // Methode zum Abrufen der Saisondaten
  Future<void> loadSeasonData(ScaffoldMessengerState messenger) async {
    try {
      final saisonProvider =
          Provider.of<SaisonProvider>(context, listen: false);

      // WICHTIG: Prüfen Sie, ob diese Methode (getAllSeasons) EINE leere Liste ODER einen Fehler liefert.
      List<SaisonData> loadedSeasons = await saisonProvider.getAllSeasons();

      if (loadedSeasons.isNotEmpty) {
        // NUR SETSTATE AUFRUFEN, WENN WIR AUF DEM WIDGET MOUNTED SIND
        if (mounted) {
          setState(() {
            filterSeasons = loadedSeasons;
            // KRITISCH: selectedSeason MUSS hier gesetzt werden!
            selectedSeason = filterSeasons.first;
          });
        }
      } else {
        // Wenn keine Daten geladen wurden, setState aufrufen, um filterSeasons leer zu setzen
        if (mounted) {
          setState(() {
            filterSeasons = [];
            selectedSeason = null; // Zur Sicherheit
          });
        }
      }
    } catch (error) {
      // Wenn ein Fehler auftritt, MUSS der State trotzdem aktualisiert werden,
      // damit _isLoading = false gesetzt werden kann, und die "Keine Saisons verfügbar" Meldung erscheint.
      if (mounted) {
        setState(() {
          filterSeasons = [];
          selectedSeason = null;
        });
      }
      // appError(messenger, "Fehler beim Laden der Saisons: $error");
    }
  }

  // Abruf der Teams
  Future<void> getData(ScaffoldMessengerState messenger) async {
    try {
      if (selectedSeason?.key != null) {
        await Provider.of<TeamProvider>(context, listen: false).loadDatatoCache(
          messenger,
          selectedSeason!.key,
        );
        if (!context.mounted) return;
        // filteredTeams = Provider.of<TeamProvider>(context, listen: false)
        //     .getFilteredMannschaften(saisonKey: selectedSeason!.key);
      } else {
        filteredTeams = [];
      }

      // 🔧 NEU: Filter + Sortierung nach dem Laden anwenden
      getFilteredResults();

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      appError(messenger, 'Fehler beim Laden der Daten: ${error.toString()}');
    }
  }

  // Filtermethoden für Saison
  void getFilteredResults() {
    if (selectedSeason == null) {
      filteredTeams = [];
      // Keine Sortierung, einfach leere Liste
      return;
    }
    filteredTeams = Provider.of<TeamProvider>(context, listen: false)
        .getFilteredMannschaften(saisonKey: selectedSeason!.key);

    // Filter für Saison
    //   if (selectedSeason != null && selectedSeason!.key.isNotEmpty) {
    //     filteredTeams = filteredTeams
    //         .where((result) =>
    //             result.saison ==
    //             selectedSeason!.key) // Vergleiche den Saison-Namen
    //         .toList();
    //   }

    // Filter für Jugend und Erwachsene
    if (selectedAgeGroup == 'Jugend') {
      filteredTeams = filteredTeams
          .where((result) =>
              result.mannschaft.startsWith("U9") ||
              result.mannschaft.startsWith("U10") ||
              result.mannschaft.startsWith("Bambini") ||
              result.mannschaft.startsWith("Dunlop") ||
              result.mannschaft.startsWith("Knaben") ||
              result.mannschaft.startsWith("Junioren"))
          .toList();
    } else if (selectedAgeGroup == 'Erwachsene') {
      filteredTeams = filteredTeams
          .where((result) =>
              !result.mannschaft.startsWith("U9") &&
              !result.mannschaft.startsWith("U10") &&
              !result.mannschaft.startsWith("Bambini") &&
              !result.mannschaft.startsWith("Dunlop") &&
              !result.mannschaft.startsWith("Knaben") &&
              !result.mannschaft.startsWith("Junioren"))
          .toList();
    }
    getSortedResults(filteredTeams);
  }

  // Logik für die Teamreihenfolge
  List<Team> getSortedResults(List<Team> results) {
    final sortOrder = [
      "Junioren",
      "Knaben",
      "Bambini",
      "U10",
      "U9",
      "Damen",
      "Herren", // wichtig: vor Herren 30!
      "Herren 30",
      "Herren 40",
      "Herren 50",
    ];

    int getSortIndex(String mannschaftName) {
      for (int i = 0; i < sortOrder.length; i++) {
        if (mannschaftName.contains(sortOrder[i])) {
          return i;
        }
      }
      // Wenn nicht in der Liste: ganz unten einsortieren
      return sortOrder.length;
    }

    results.sort((a, b) {
      int indexA = getSortIndex(a.mannschaft);
      int indexB = getSortIndex(b.mannschaft);
      if (indexA != indexB) {
        return indexA.compareTo(indexB);
      } else {
        return a.mannschaft
            .compareTo(b.mannschaft); // innerhalb einer Kategorie alphabetisch
      }
    });

    return results;
  }

  @override
  Widget build(BuildContext context) {
    // Wichtig: context.read<T>() ist moderner als Provider.of(context, listen: false)
    final messenger = ScaffoldMessenger.of(context);

    // --- 1. ZENTRALE LADESTEUERUNG (Ersetzt den FutureBuilder) ---
    if (_isLoading) {
      // Zeigt den Ladeindikator an, solange initState läuft
      return Scaffold(
        appBar: VereinAppbar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // --- 2. KEINE DATEN VORHANDEN ---
    if (filterSeasons.isEmpty) {
      // Zeigt die Fehlermeldung, wenn loadSeasonData() eine leere Liste zurückgibt
      return Scaffold(
        appBar: VereinAppbar(),
        body: Center(child: Text('Keine Saisons verfügbar')),
      );
    }

    // --- 3. DATEN VORHANDEN – Rendern der Dropdowns ---
    return Scaffold(
      appBar: VereinAppbar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<SaisonData>(
                    // Nutzt die im State gesetzte Variable selectedSeason
                    value: selectedSeason,
                    hint: const Text('Select season'),
                    items: filterSeasons.map((SaisonData saison) {
                      return DropdownMenuItem<SaisonData>(
                        value: saison,
                        child: Text(saison.saison),
                      );
                    }).toList(),
                    onChanged: (SaisonData? value) {
                      if (value != null) {
                        setState(() {
                          selectedSeason = value;
                        });
                        // Hole die Daten für die gewählte Saison
                        getData(messenger);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedAgeGroup,
                    items: ['All', 'Jugend', 'Erwachsene']
                        .map((group) => DropdownMenuItem<String>(
                            value: group, child: Text(group)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedAgeGroup = value!;
                        getFilteredResults();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Anzeige der Teams
          if (filteredTeams.isNotEmpty)
            Expanded(
              child: ListView(
                children: filteredTeams.map((teamT) {
                  return TeamTile(teamTile: teamT);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
