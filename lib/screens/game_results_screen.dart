import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_result.dart';
import '../providers/game_results_provider.dart';
import '../widgets/game_results_tile.dart';
import '../widgets/verein_appbar.dart';

class GameResultsScreen extends StatefulWidget {
  const GameResultsScreen({super.key});
  static const routename = "/game-results";

  @override
  State<GameResultsScreen> createState() => _GameResultsScreenState();
}

class _GameResultsScreenState extends State<GameResultsScreen> {
  var _isLoading = false;
  List<GameResult> gameResults = [];
  List<String> filterSeasons = [];
  String? selectedSeason;
  String? selectedGroup;

  // Filter für Saison und Jugend/Erwachsene
  String selectedAgeGroup = 'All';

  // Methode zum Abrufen der Daten
  Future<void> getData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      gameResults =
          await Provider.of<GameResultsProvider>(context, listen: false)
              .getData();

      // Saison extrahieren und filtern
      filterSeasons = gameResults
          .map((result) => result.saison)
          .toSet()
          .toList(); // Entfernen von Duplikaten

      // Die Liste nach Saison sortieren
      filterSeasons.sort((a, b) => a.compareTo(b));

      // Setze die ausgewählte Saison auf den ersten Wert, falls vorhanden
      if (filterSeasons.isNotEmpty) {
        selectedSeason = filterSeasons.first;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to load game results. Please try again.')),
      );
    }
  }

  // Filtermethoden für Saison
  List<GameResult> getFilteredResults() {
    var filteredResults = gameResults;

    // Filter für Saison
    if (selectedSeason != null && selectedSeason!.isNotEmpty) {
      filteredResults = filteredResults
          .where((result) => result.saison == selectedSeason)
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
  List<GameResult> getSortedResults(List<GameResult> results) {
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
  void initState() {
    super.initState();
    getData(); // Daten abrufen, ohne Logik für die aktuelle Saison
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VereinAppbar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter oben in einer Zeile
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // Dropdown für Saison-Filter
                      Expanded(
                        child: DropdownButton<String>(
                          value: selectedSeason, // Vorausgewählte Saison
                          hint: const Text('Select season'),
                          items: filterSeasons
                              .map((season) => DropdownMenuItem<String>(
                                    value: season,
                                    child: Text(season),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSeason = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Dropdown für Jugend/Erwachsene-Filter
                      Expanded(
                        child: DropdownButton<String>(
                          value: selectedAgeGroup,
                          items: ['All', 'Jugend', 'Erwachsene']
                              .map((group) => DropdownMenuItem<String>(
                                    value: group,
                                    child: Text(group),
                                  ))
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
                ),
                // Zeigen Sie gefilterte und sortierte Ergebnisse
                Expanded(
                  child: ListView(
                    children: getSortedResults(getFilteredResults())
                        .map(
                          (el) => GameResultsTile(gameResult: el),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
    );
  }
}
