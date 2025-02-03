import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/season.dart';
import '../providers/season_provider.dart';
import '../models/team.dart';
import '../providers/team_provider.dart';
import '../widgets/game_results_tile.dart';
import '../widgets/verein_appbar.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});
  static const routename = "/game-results";

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  var _isLoading = true;
  List<Team> teams = [];
  List<SaisonData> filterSeasons = [];
  SaisonData? selectedSeason;
  String selectedAgeGroup = 'All';

  @override
  void initState() {
    super.initState();
    print('initState gestartet');
    loadSeasonData(); // Lädt Saisondaten direkt in initState
  }

  // Methode zum Abrufen der Saisondaten
  Future<void> loadSeasonData() async {
    try {
      final saisonProvider =
          Provider.of<SaisonProvider>(context, listen: false);
      print('Lade Saisondaten...');
      List<SaisonData> loadedSeasons = await saisonProvider.getAllSeasons();

      if (loadedSeasons.isNotEmpty) {
        setState(() {
          filterSeasons = loadedSeasons;
          selectedSeason = filterSeasons.first;
          print('Saisondaten geladen: ${filterSeasons.length} Seasons');
        });
        // Jetzt auch die Teams für die gewählte Saison laden
        getData();
      } else {
        setState(() {
          filterSeasons = [];
        });
        print("Keine Saisondaten gefunden!");
      }
    } catch (error) {
      print("Fehler beim Laden der Saisons: $error");
    }
  }

  // Abruf der Teams
  Future<void> getData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (selectedSeason?.key != null) {
        teams = await Provider.of<TeamProvider>(context, listen: false).getData(
            selectedSeason!.key); // Wir holen die Teams für die gewählte Saison
        print('Teams geladen: ${teams.length} Teams');
      } else {
        teams = [];
      }

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to load game results. Please try again.')),
        );
      }
    }
  }

  // Filtermethoden für Saison
  List<Team> getFilteredResults() {
    var filteredResults = teams;

    // Filter für Saison
    if (selectedSeason != null && selectedSeason!.key.isNotEmpty) {
      filteredResults = filteredResults
          .where((result) =>
              result.saison ==
              selectedSeason!.key) // Vergleiche den Saison-Namen
          .toList();
    }

    // Filter für Jugend und Erwachsene
    if (selectedAgeGroup == 'Jugend') {
      filteredResults = filteredResults
          .where((result) =>
              result.mannschaft.startsWith("U9") ||
              result.mannschaft.startsWith("U10") ||
              result.mannschaft.startsWith("Bambini") ||
              result.mannschaft.startsWith("Knaben") ||
              result.mannschaft.startsWith("Junioren"))
          .toList();
    } else if (selectedAgeGroup == 'Erwachsene') {
      filteredResults = filteredResults
          .where((result) =>
              !result.mannschaft.startsWith("U9") &&
              !result.mannschaft.startsWith("U10") &&
              !result.mannschaft.startsWith("Bambini") &&
              !result.mannschaft.startsWith("Knaben") &&
              !result.mannschaft.startsWith("Junioren"))
          .toList();
    }

    return filteredResults;
  }

  // Logik für die Teamreihenfolge
  List<Team> getSortedResults(List<Team> results) {
    // Kategorisierte Teams nach den gewünschten Gruppen
    var ladiesTeams = results
        .where((result) => result.mannschaft.startsWith("Damen"))
        .toList();
    var menTeams = results
        .where((result) => result.mannschaft.startsWith("Herren"))
        .toList();
    var juniors = results
        .where((result) => result.mannschaft.startsWith("Junioren"))
        .toList();

    // Knaben, Bambini U9 und Bambini U10 werden separat als eigene Blöcke behandelt
    var knabenTeams = results
        .where((result) => result.mannschaft.startsWith("Knaben"))
        .toList();
    var bambiniTeams = results
        .where((result) => result.mannschaft.startsWith("Bambini"))
        .toList();
    var u10Teams =
        results.where((result) => result.mannschaft.startsWith("U10")).toList();
    var u9Teams =
        results.where((result) => result.mannschaft.startsWith("U9")).toList();

    // Alphabetische Sortierung für alle Teams (Damen, Herren, Junioren, Knaben, U9 und Bambini U10)
    ladiesTeams.sort((a, b) => a.mannschaft.compareTo(b.mannschaft));
    menTeams.sort((a, b) => a.mannschaft.compareTo(b.mannschaft));
    juniors.sort((a, b) => a.mannschaft.compareTo(b.mannschaft));
    knabenTeams.sort((a, b) => a.mannschaft.compareTo(b.mannschaft));
    bambiniTeams.sort((a, b) => a.mannschaft.compareTo(b.mannschaft));
    u10Teams.sort((a, b) => a.mannschaft.compareTo(b.mannschaft));
    u9Teams.sort((a, b) => a.mannschaft.compareTo(b.mannschaft));

    // Zusammenfügen der gefilterten und sortierten Listen in der richtigen Reihenfolge
    return [
      ...ladiesTeams,
      ...menTeams, // Herren alphabetisch sortiert
      ...juniors,
      ...knabenTeams, // Knaben-Teams als eigener Block
      ...bambiniTeams, // Bambini U9-Teams als eigener Block
      ...u10Teams, // Bambini U10-Teams als eigener Block
      ...u9Teams,
    ];
  }

  @override
  Widget build(BuildContext context) {
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
                            getData(); // Hole die Daten für die gewählte Saison
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
          if (teams.isNotEmpty)
            Expanded(
              child: ListView(
                children: teams.map((team) {
                  return GameResultsTile(gameResult: team);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
