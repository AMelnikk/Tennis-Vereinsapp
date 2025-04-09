import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/screens/news_detail_screen.dart';
import '../models/season.dart';
import '../providers/news_provider.dart';
import '../screens/add_news_screen.dart';
import '../utils/app_colors.dart';
import '../widgets/build_filter_season_team.dart';
import '../models/tennismatch.dart';
import '../providers/team_result_provider.dart'; // Enthält updateLigaSpiel(TennisMatch spiel)
import '../providers/season_provider.dart'; // Lädt die Saisondaten
import '../widgets/verein_appbar.dart';

class AddTeamResultScreen extends StatefulWidget {
  const AddTeamResultScreen({super.key});
  static const routename = "/add-spiergebnsele-screen";

  @override
  State<AddTeamResultScreen> createState() => _AddTeamResultScreenState();
}

class _AddTeamResultScreenState extends State<AddTeamResultScreen> {
  // Wird als aktuell gewählte Saison verwendet (String aus dem SaisonData.saison-Feld)
  SaisonData _selectedSeason = SaisonData.empty();
  String _selectedAgeGroup = "Alle";
  final TextEditingController _ergebnisController = TextEditingController();
  final TextEditingController _datumController = TextEditingController();
  final TextEditingController _uhrzeitController = TextEditingController();
  final TextEditingController _newsIdController = TextEditingController();
  TennisMatch _selectedMatch = TennisMatch.empty();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadSaisons(); // wartet auf Saisons
      await _loadSpiele(); // lädt Spiele danach
      setState(() {}); // UI aktualisieren
    });
  }

  Future<void> _loadSaisons() async {
    // Lade Saisondaten
    SaisonProvider saisonP =
        Provider.of<SaisonProvider>(context, listen: false);
    await saisonP.getAllSeasons();
    _selectedSeason = saisonP.getFirstSaison();
    _selectedAgeGroup = "Alle";
  }

  Future<void> _loadSpiele() async {
    // Lade Saisondaten
    LigaSpieleProvider lsProvider =
        Provider.of<LigaSpieleProvider>(context, listen: false);
    await lsProvider.loadLigaSpieleForSeason(_selectedSeason);
  }

  Future<void> _saveErgebnis() async {
    final messenger = ScaffoldMessenger.of(context);
    final teamResultProvider =
        Provider.of<LigaSpieleProvider>(context, listen: false);

    // Überprüfe, ob das Ergebnis im richtigen Format ist (z.B. "1:1")
    final resultPattern = RegExp(r'^[0-9]:[0-9]$');
    if (_ergebnisController.text.isNotEmpty &&
        !resultPattern.hasMatch(_ergebnisController.text)) {
      messenger.showSnackBar(const SnackBar(
          content: Text("Ergebnis muss im Format Zahl:Zahl sein (1-9).")));
      return;
    }

    // Übernehme das Ergebnis in das ausgewählte Spiel
    _selectedMatch.ergebnis = _ergebnisController.text;

    // Aktualisiere das Spiel in der Datenquelle
    int responseCode = await teamResultProvider.updateLigaSpiel(_selectedMatch);

    if (responseCode == 200) {
      messenger.showSnackBar(
          const SnackBar(content: Text("Ergebnis erfolgreich aktualisiert.")));
    } else {
      messenger.showSnackBar(const SnackBar(
          content: Text("Fehler beim Aktualisieren des Ergebnisses.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamResultProvider = Provider.of<LigaSpieleProvider>(context);

    // Spiele vorab filtern
    final filteredSpiele = teamResultProvider.getFilteredSpiele(
      saisonKey: _selectedSeason.key,
      jahr: null,
      altersklasse: _selectedAgeGroup,
    );

    return Scaffold(
      appBar: VereinAppbar(),
      body: Column(
        children: [
          const SizedBox(height: 5),
          FilterSection(
            selectedSeason: _selectedSeason,
            selectedAgeGroup: _selectedAgeGroup,
            onSeasonChanged: (newSeason) {
              setState(() {
                _selectedSeason = newSeason;
              });
            },
            onAgeGroupChanged: (newAgeGroup) {
              setState(() {
                _selectedAgeGroup = newAgeGroup;
              });
            },
          ),
          const SizedBox(height: 10),
          Expanded(
            child: teamResultProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredSpiele.isEmpty
                    ? const Center(child: Text("Keine Spiele vorhanden"))
                    : buildLigaSpieleList(filteredSpiele),
          ),
        ],
      ),
    );
  }

  Widget buildLigaSpieleList(List<TennisMatch> spiele) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical, // Vertikales Scrollen aktivieren
      child: SingleChildScrollView(
        scrollDirection:
            Axis.horizontal, // Beibehaltung des horizontalen Scrollens
        child: DataTable(
          columnSpacing: 0, // Abstände zwischen den Spalten
          headingRowHeight: spiele.isEmpty
              ? 0
              : null, // Header ausblenden, wenn keine Spiele vorhanden sind
          columns: [
            DataColumn(
                label: spiele.isEmpty
                    ? Container()
                    : const Text("Datum & Uhrzeit")),
            DataColumn(
                label: spiele.isEmpty ? Container() : const Text("Heim")),
            DataColumn(
                label: spiele.isEmpty ? Container() : const Text("Gast")),
            DataColumn(
                label: spiele.isEmpty ? Container() : const Text("Ergebnis")),
            DataColumn(
                label: spiele.isEmpty ? Container() : const Text("News")),
            DataColumn(
                label: spiele.isEmpty ? Container() : const Text("Aktionen")),
          ],
          rows: spiele.map((spiel) {
            final dateFormatted = DateFormat('dd.MM.yyyy').format(spiel.datum);
            final ergebnisAnzeige = spiel.ergebnis;

            String heimAnzeige = spiel.heim == "TeG Altmühlgrund"
                ? spiel.altersklasse
                : spiel.heim;
            String gastAnzeige = spiel.gast == "TeG Altmühlgrund"
                ? spiel.altersklasse
                : spiel.gast;

            Color ergebnisFarbe =
                getErgebnisCellColor(spiel.ergebnis, spiel.heim, spiel.gast);

            return DataRow(cells: [
              // 📅 Datum & Uhrzeit
              DataCell(
                Container(
                  width: 60,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        dateFormatted,
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 10), // Textgröße auf 10 gesetzt
                      ),
                      Text(
                        spiel.uhrzeit,
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 10), // Textgröße auf 10 gesetzt
                      ),
                    ],
                  ),
                ),
              ),

              // 🏠 Heim-Team
              DataCell(
                Container(
                  width: 100,
                  height: 60,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    " $heimAnzeige",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(fontSize: 14), // Textgröße auf 10 gesetzt
                  ),
                ),
              ),

              // 🏆 Gast-Team
              DataCell(Container(
                width: 100,
                height: 60,
                alignment: Alignment.centerLeft,
                child: Text(
                  " $gastAnzeige",
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(fontSize: 14),
                ),
              )),

              // ⚽ Ergebnis
              DataCell(
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ergebnisFarbe,
                    border: Border.all(color: Colors.black, width: 0.5),
                  ),
                  child: Text(
                    ergebnisAnzeige,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
// 📰 News-Spalte
              DataCell(
                spiel.spielbericht.isNotEmpty
                    ? Tooltip(
                        message: "Spielbericht ansehen",
                        child: IconButton(
                            icon: Icon(Icons.article, color: Colors.orange),
                            onPressed: () {
                              final newsProvider = Provider.of<NewsProvider>(
                                  context,
                                  listen: false);
                              newsProvider.loadNews(spiel.spielbericht);
                              Navigator.pushNamed(
                                context,
                                NewsDetailScreen
                                    .routename, // Korrekte Nutzung des statischen Routennamens
                              );
                            }),
                      )
                    : Container(), // Kein Icon, falls kein Bericht existiert
              ),
              // ✏️ Bearbeiten & 🗑 Löschen
              DataCell(
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🖊 Bearbeiten (öffnet Dialog)
                    Tooltip(
                      message: "Ergebnis bearbeiten",
                      child: IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          setState(() {
                            _selectedMatch = spiel;
                          });

                          _datumController.text = dateFormatted;
                          _uhrzeitController.text = spiel.uhrzeit;
                          _ergebnisController.text = spiel.ergebnis;
                          _newsIdController.text = spiel.spielbericht;

                          _showEditErgebnisDialog();
                        },
                      ),
                    ),
                    // 🗑 Löschen (setzt Ergebnis zurück)
                    Tooltip(
                      message: "Ergebnis löschen",
                      child: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _selectedMatch = spiel;
                          });
                          _selectedMatch.ergebnis = "";
                          Provider.of<LigaSpieleProvider>(context,
                                  listen: false)
                              .updateLigaSpiel(_selectedMatch);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  /// Zeigt einen Dialog, in dem das Ergebnis bearbeitet werden kann.
  void _showEditErgebnisDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text("Ergebnis bearbeiten"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Datumsauswahl
              Row(
                children: [
                  Text(
                    'Datum: ${_datumController.text}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final DateTime? newDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedMatch.datum,
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                      );
                      if (newDate != null) {
                        setState(() {
                          _selectedMatch.datum = newDate;
                          _datumController.text =
                              DateFormat('dd.MM.yyyy').format(newDate);
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Uhrzeit-Auswahl
              Row(
                children: [
                  Text(
                    'Uhrzeit: ${_uhrzeitController.text}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () async {
                      final TimeOfDay? newTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(
                          DateFormat('HH:mm').parse(_selectedMatch.uhrzeit),
                        ),
                      );
                      if (newTime != null) {
                        final formattedTime =
                            "${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}";
                        setState(() {
                          _selectedMatch.uhrzeit = formattedTime;
                          _uhrzeitController.text = formattedTime;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Begegnung
              Row(
                children: [
                  Text(
                    'Begegnung: ${_selectedMatch.heim} vs ${_selectedMatch.gast}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Ergebnis
              TextField(
                controller: _ergebnisController,
                decoration: const InputDecoration(
                    labelText: "Ergebnis im Format (1-9:1-9)"),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 8),

              // News ID + Button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newsIdController,
                      decoration: const InputDecoration(labelText: "News ID"),
                      keyboardType: TextInputType.text,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.article),
                    onPressed: () async {
                      final newsProvider =
                          Provider.of<NewsProvider>(context, listen: false);
                      final lsProvider = Provider.of<LigaSpieleProvider>(
                          context,
                          listen: false);

                      // Setze die Werte im newsProvider
                      newsProvider.title.text =
                          "Begegnung: ${_selectedMatch.heim} vs ${_selectedMatch.gast}";
                      newsProvider.newsDateController.text =
                          DateFormat('dd.MM.yyyy').format(_selectedMatch.datum);
                      newsProvider.updateCategory("Spielbericht");
                      newsProvider.newsId = _newsIdController.text;
                      newsProvider.newsDateController.text =
                          DateFormat('dd.MM.yyyy').format(_selectedMatch.datum);
                      newsProvider.body.text = '';
                      newsProvider.photoBlob = [];

                      // Navigiere zum AddNewsScreen und warte auf die News ID
                      final newsId = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddNewsScreen(),
                        ),
                      );

                      // Setze die News ID, wenn eine zurückgegeben wurde
                      if (newsId != null && newsId.isNotEmpty) {
                        setState(() {
                          _newsIdController.text = newsId;
                          _selectedMatch.spielbericht = newsId;
                          lsProvider.updateLigaSpiel(_selectedMatch);
                        });
                        newsProvider.newsId = newsId;
                      }
                    },
                  )
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Abbrechen"),
            ),
            TextButton(
              onPressed: () {
                _saveErgebnis();
                Navigator.of(ctx).pop();
              },
              child: const Text("Speichern"),
            ),
          ],
        ),
      ),
    );
  }
}
