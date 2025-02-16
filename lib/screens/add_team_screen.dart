import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/season.dart';
import '../popUps/show_team_popup.dart';
import '../providers/season_provider.dart';
import '../utils/app_utils.dart';
import '../providers/team_provider.dart';
import '../models/team.dart';

class AddMannschaftScreen extends StatefulWidget {
  static const routename = "/add_mannschaft_screen";

  const AddMannschaftScreen({super.key});

  @override
  State<AddMannschaftScreen> createState() => _AddMannschaftScreenState();
}

class _AddMannschaftScreenState extends State<AddMannschaftScreen> {
  List<SaisonData> filterSeasons = [];
  String _selectedSaisonFilterKey = '';
  String _selectedFilterMannschaft = '';
  final List<String> _filterTeams = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSeasons();
    });
  }

  Future<void> _loadSeasons() async {
    final saisonProvider = Provider.of<SaisonProvider>(context, listen: false);
    try {
      final saisons = await saisonProvider.getAllSeasons();
      if (saisons.isNotEmpty) {
        setState(() {
          filterSeasons = saisons;
          if (_selectedSaisonFilterKey.isEmpty) {
            _selectedSaisonFilterKey = saisons.first.key;
          }
          //_selectedSaison = saisons.first;
        });
      }
    } catch (e) {
      _showWarning('Error loading seasons: $e');
    }
  }

  void _showWarning(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Warnung"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context); // Vorher speichern
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mannschaften verwalten"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showTeamDialog(context, filterSeasons,
                Team.empty()), // Leere Liste für neues Team
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Consumer2<TeamProvider, SaisonProvider>(
          builder: (context, provider, saisonProvider, child) {
            return FutureBuilder<List<SaisonData>>(
              future: saisonProvider.getAllSeasons(), // Nur einmal abrufen
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Fehler beim Laden: ${snapshot.error}'),
                  );
                }
                final seasons = snapshot.data ?? [];

                return Column(
                  children: [
                    // Filter-Zeile für die Saison-Auswahl
                    _buildFilterRow(seasons),
                    const SizedBox(height: 10),
                    // Tabelle mit Team-Ergebnissen
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: _buildGameResultsTable(
                            messenger, provider, saisonProvider),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showTeamDialog(
      BuildContext context, List<SaisonData> seasons, Team teamData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return MyTeamDialog(
            seasons: seasons,
            teamData: teamData); // Dialog aufrufen und Daten übergeben
      },
    );
  }

  Widget _buildFilterRow(List<SaisonData> seasons) {
    if (seasons.isEmpty) {
      return const Text('Keine Saisons verfügbar');
    }
    return Row(
      children: [
        Expanded(
          child: buildDropdownField(
            label: 'Saison',
            value: _selectedSaisonFilterKey,
            items: seasons.map((season) => season.key).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSaisonFilterKey = value.toString();
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: buildDropdownField(
            label: 'Mannschaft',
            value: _selectedFilterMannschaft,
            items: _filterTeams,
            onChanged: (value) {
              setState(() {
                _selectedFilterMannschaft = value ?? '';
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGameResultsTable(ScaffoldMessengerState messenger,
      TeamProvider teamProvider, SaisonProvider seasonProvider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection:
            Axis.horizontal, // Horizontales Scrollen für kleine Geräte
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical, // Vertikales Scrollen hinzufügen
          child: FutureBuilder<void>(
            future: teamProvider.loadDatatoCache(
                messenger, _selectedSaisonFilterKey),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator()); // Ladeindikator
              } else if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Fehler: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => teamProvider.loadDatatoCache(
                            messenger, _selectedSaisonFilterKey),
                        child: const Text('Erneut versuchen'),
                      ),
                    ],
                  ),
                );
              } else {
                final teams = teamProvider.getFilteredMannschaften(
                  saisonKey: _selectedSaisonFilterKey,
                  mannschaft: _selectedFilterMannschaft,
                );

                if (teams.isEmpty) {
                  return const Center(child: Text('Keine Einträge vorhanden.'));
                }

                return DataTable(
                  columnSpacing:
                      15, // Reduzierte Spaltenabstände für kompaktere Darstellung
                  columns: const [
                    DataColumn(
                        label: Text('Saison', style: TextStyle(fontSize: 16))),
                    DataColumn(
                        label:
                            Text('Mannschaft', style: TextStyle(fontSize: 16))),
                    DataColumn(
                        label: Text('Liga', style: TextStyle(fontSize: 16))),
                    DataColumn(
                        label: Text('Gruppe', style: TextStyle(fontSize: 16))),
                    DataColumn(
                        label: Text('Matchbilanz',
                            style: TextStyle(fontSize: 16))),
                    DataColumn(
                        label:
                            Text('Satzbilanz', style: TextStyle(fontSize: 16))),
                    DataColumn(
                        label: Text('Link', style: TextStyle(fontSize: 16))),
                    DataColumn(
                        label:
                            Text('Aktionen', style: TextStyle(fontSize: 16))),
                  ],
                  rows: teams.map((entry) {
                    return DataRow(
                      cells: [
                        DataCell(Text(entry.saison,
                            style: const TextStyle(fontSize: 14))),
                        DataCell(Text(entry.mannschaft,
                            style: const TextStyle(fontSize: 14))),
                        DataCell(Text(entry.liga,
                            style: const TextStyle(fontSize: 14))),
                        DataCell(Text(entry.gruppe,
                            style: const TextStyle(fontSize: 14))),
                        DataCell(Text(entry.matchbilanz,
                            style: const TextStyle(fontSize: 14))),
                        DataCell(Text(entry.satzbilanz,
                            style: const TextStyle(fontSize: 14))),
                        DataCell(
                          entry.url.isNotEmpty && entry.url.startsWith('http')
                              ? GestureDetector(
                                  onTap: () =>
                                      _launchURL(entry.url), // URL öffnen
                                  child: const Text(
                                    'Link öffnen',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              : const SizedBox
                                  .shrink(), // Nichts anzeigen, wenn URL leer oder nicht mit 'http' beginnend
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    size: 18), // Kleinere Icons
                                onPressed: () => _showTeamDialog(context,
                                    filterSeasons, entry), // Bearbeiten
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                onPressed: () async {
                                  final confirmed =
                                      await _showDeleteConfirmation(context);
                                  if (!mounted) return;

                                  if (confirmed) {
                                    await teamProvider.deleteTeam(entry.saison,
                                        entry.mannschaft); // Löschen
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Eintrag gelöscht.'),
                                          backgroundColor: Colors.green),
                                    );

                                    // Nur den Eintrag löschen und die Anzeige aktualisieren
                                    setState(() {});
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Eintrag löschen'),
            content: const Text('Möchten Sie diesen Eintrag wirklich löschen?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Löschen'),
              ),
            ],
          ),
        ) ??
        false; // Default false, falls Dialog abgebrochen wird
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {}
  }
}
