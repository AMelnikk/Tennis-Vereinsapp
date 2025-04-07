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
  List<Team> filteredTeams = [];
  List<SaisonData> filterSeasons = [];
  SaisonData? selectedSeason;
  String selectedAgeGroup = 'All';

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This is where you should safely access providers or inherited widgets
    //saisonProvider = Provider.of<SaisonProvider>(context, listen: false);
    // Now you can safely call methods or load data that depend on context
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final messenger = ScaffoldMessenger.of(context); // Vorher speichern
      loadSeasonData(messenger);
    });
  }

  // Methode zum Abrufen der Saisondaten
  Future<void> loadSeasonData(ScaffoldMessengerState messenger) async {
    try {
      final saisonProvider =
          Provider.of<SaisonProvider>(context, listen: false);
      List<SaisonData> loadedSeasons = await saisonProvider.getAllSeasons();

      if (loadedSeasons.isNotEmpty) {
        setState(() {
          filterSeasons = loadedSeasons;
          selectedSeason = filterSeasons.first;
        });
        // Jetzt auch die Teams für die gewählte Saison laden
        getData(messenger);
      } else {
        setState(() {
          filterSeasons = [];
        });
      }
    } catch (error) {
      //appError(messenger, "Fehler beim Laden der Saisons: $error");
    }
  }

  // Abruf der Teams
  Future<void> getData(ScaffoldMessengerState messenger) async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (selectedSeason?.key != null) {
        await Provider.of<TeamProvider>(context, listen: false).loadDatatoCache(
          messenger,
          selectedSeason!.key,
        );

        filteredTeams = Provider.of<TeamProvider>(context, listen: false)
            .getFilteredMannschaften(saisonKey: selectedSeason!.key);
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
    filteredTeams = Provider.of<TeamProvider>(context, listen: false)
        .getFilteredMannschaften(saisonKey: selectedSeason!.key);

    // Filter für Saison
    if (selectedSeason != null && selectedSeason!.key.isNotEmpty) {
      filteredTeams = filteredTeams
          .where((result) =>
              result.saison ==
              selectedSeason!.key) // Vergleiche den Saison-Namen
          .toList();
    }

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
    final messenger = ScaffoldMessenger.of(context); // Vorher speichern
    return Scaffold(
      appBar: VereinAppbar(),
      body: Column(
        children: [
          // Saison Dropdown mit FutureBuilder für Saisondaten
          FutureBuilder<List<SaisonData>>(
            future: Provider.of<SaisonProvider>(context, listen: false)
                .getAllSeasons(), // Diese Methode gibt ein Future zurück
            builder: (context, snapshot) {
              // Ladezustand
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Fehlerbehandlung
              if (snapshot.hasError) {
                return Center(child: Text('Fehler: ${snapshot.error}'));
              }

              // Wenn keine Daten vorhanden sind
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Keine Saisons verfügbar'));
              }

              // Wenn Daten vorhanden sind, speichern wir sie
              filterSeasons = snapshot.data!;

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<SaisonData>(
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
                            getData(
                                messenger); // Hole die Daten für die gewählte Saison
                            getFilteredResults();
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
              );
            },
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
