// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/popUps/edit_team_result_dialog.dart';
import 'package:verein_app/screens/news_detail_screen.dart';
import '../providers/news_provider.dart';
import '../providers/team_result_provider.dart';
import '../providers/season_provider.dart';
import '../models/news.dart';
import '../models/season.dart';
import '../models/tennismatch.dart';
import 'package:intl/intl.dart';

class NewsAdminScreen extends StatefulWidget {
  static const routename = '/news-admin-screen';
  const NewsAdminScreen({super.key});

  @override
  State<NewsAdminScreen> createState() => _NewsAdminScreenState();
}

class _NewsAdminScreenState extends State<NewsAdminScreen> {
  bool _isLoading = true;
  bool _filterUnassignedOnly = false;
  List<News> _allNews = [];
  List<String> _assignedBerichtIDs = [];
  List<SaisonData> _saisons = [];

  // SPEICHERT ALLE LIGASPIELE FÜR LOOKUP
  List<TennisMatch> _allMatches = [];

  // "Alle" ist der Standardwert, um alle Kategorien anzuzeigen
  String _selectedCategory = 'Alle';
  // Liste der verfügbaren Kategorien für das Dropdown
  List<String> _availableCategories = ['Alle'];

  // NEUER STATE: Map der Altersklasse -> Anzahl der Berichte
  Map<String, int> _altersklassenWithCount = {};
  String _selectedAltersklasse = 'Alle';
  List<String> _availableAltersklassen = ['Alle'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final saisonProv = Provider.of<SaisonProvider>(context, listen: false);
    final ligaProv = Provider.of<LigaSpieleProvider>(context, listen: false);
    final newsProv = Provider.of<NewsProvider>(context, listen: false);

    // 1. Saisons laden
    await saisonProv.loadSaisons();
    _saisons = saisonProv.saisons;

    // 2. Alle Matches laden
    List<TennisMatch> allMatchesTemp = [];
    for (var saison in _saisons) {
      if (saison.jahr != -1) {
        await ligaProv.ensureLigaSpieleGeladen(saison.jahr);
        allMatchesTemp.addAll(ligaProv.getLigaSpiele(saison.jahr));
      }
      if (saison.jahr2 != -1) {
        await ligaProv.ensureLigaSpieleGeladen(saison.jahr2);
        allMatchesTemp.addAll(ligaProv.getLigaSpiele(saison.jahr2));
      }
    }

    _allMatches = allMatchesTemp;

    // Eindeutige News-IDs, die einem Match zugeordnet sind
    _assignedBerichtIDs = _allMatches
        .where((m) => m.spielbericht.isNotEmpty)
        .map((m) => m.spielbericht)
        .toSet() // Verwenden Sie toSet() für Eindeutigkeit, dann toList()
        .toList();

    _allNews = await newsProv.loadAllNewsForAdmin();

    // Distincte Kategorien ermitteln (bleibt unverändert)
    Set<String> distinctCategories = _allNews.map((n) => n.category).toSet();
    _availableCategories = ['Alle', ...distinctCategories];
    if (distinctCategories.contains("Spielbericht") &&
        _availableCategories.length > 2) {
      _availableCategories.remove("Spielbericht");
      _availableCategories.insert(1, "Spielbericht");
    }

    // 4. KORRIGIERTE LOGIK: Zähle die eindeutigen News-Berichte pro Altersklasse

    // 4a. Sammle alle Altersklassen pro eindeutiger News-ID (falls ein Bericht mehrere Matches abdeckt)
    Map<String, Set<String>> newsIdToAltersklassen = {};

    for (var match in _allMatches) {
      final newsId = match.spielbericht;
      final klasse = match.altersklasse;

      if (newsId.isNotEmpty && _assignedBerichtIDs.contains(newsId)) {
        // Füge die Altersklasse zum Set der News-ID hinzu
        newsIdToAltersklassen.putIfAbsent(newsId, () => {}).add(klasse);
      }
    }

    // 4b. Zähle die News-IDs pro Altersklasse
    Map<String, int> counts = {};

    for (var entry in newsIdToAltersklassen.entries) {
      // Zähle jede News für jede Altersklasse, der sie zugeordnet ist
      for (var klasse in entry.value) {
        counts[klasse] = (counts[klasse] ?? 0) + 1;
      }
    }
    _altersklassenWithCount = counts;

    // 5. Distincte Altersklassen ermitteln (nur die mit Berichten)
    _availableAltersklassen = ['Alle', ..._altersklassenWithCount.keys];

    setState(() {
      _isLoading = false;
    });
  }

  // Die Funktion gibt jetzt das ausgewählte Match oder null zurück
  /// Popup, um einem News-Bericht ein Ligaspiel zuzuordnen
  /// Popup, um einem News-Bericht ein Ligaspiel zuzuordnen
  Future<void> _openZuordnungPopup(News news) async {
    final ligaProv = Provider.of<LigaSpieleProvider>(context, listen: false);

    final dateFormat = DateFormat('dd.MM.yyyy');
    DateTime dateObject;
    try {
      dateObject = dateFormat.parse(news.date);
    } catch (e) {
      debugPrint('Fehler beim Parsen des Datums "${news.date}": $e');
      dateObject = DateTime.now(); // Fallback
    }
    int year = dateObject.year;

    await ligaProv.ensureLigaSpieleGeladen(year);
    List<TennisMatch> allMatchesForYear = ligaProv.getLigaSpiele(year);

    if (allMatchesForYear.isEmpty) {
      allMatchesForYear = _allMatches;
    }

    // Zustand-Container für den Dialog
    final dialogState = _DialogState();

    // Initialisierung (falls der Bericht bereits zugeordnet ist)
    if (news.category == "Spielbericht" && news.id.isNotEmpty) {
      final currentlyAssignedMatch =
          allMatchesForYear.where((m) => m.spielbericht == news.id).firstOrNull;
      dialogState.selectedMatch = currentlyAssignedMatch;
      dialogState.selectedFilterKlasse =
          currentlyAssignedMatch?.altersklasse ?? 'Alle';
    }

    // Alle eindeutigen Altersklassen
    final List<String> availableFilterKlassen = [
      'Alle',
      ...allMatchesForYear.map((m) => m.altersklasse).toSet()
    ];
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) {
        if (allMatchesForYear.isEmpty) {
          return AlertDialog(
            title: Text("Bericht zuordnen (${news.date})"),
            content: const Text(
                "Keine Ligaspiele im passenden Jahr/Bestand gefunden."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
            ],
          );
        }

        return AlertDialog(
          title: Text("Bericht zuordnen (${news.date})"),
          // 🔑 KORREKTUR: Der gesamte Inhalt (Dropdowns + Buttons) kommt in den Content
          content: StatefulBuilder(
            builder: (ctx, setState) {
              // ... Filter/Sortierlogik ...
              List<TennisMatch> filteredMatches = allMatchesForYear.where((m) {
                final isUnassigned = m.spielbericht.isEmpty;
                final isCurrentlyAssigned = m.spielbericht == news.id;

                if (!isUnassigned && !isCurrentlyAssigned) {
                  return false;
                }

                if (dialogState.selectedFilterKlasse != 'Alle' &&
                    m.altersklasse != dialogState.selectedFilterKlasse) {
                  return false;
                }

                return true;
              }).toList();

              filteredMatches.sort((a, b) => a.datum.compareTo(b.datum));

              if (dialogState.selectedMatch != null &&
                  !filteredMatches.contains(dialogState.selectedMatch)) {
                dialogState.selectedMatch = null;
              }
              // ... Ende Filter/Sortierlogik ...

              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Altersklasse Dropdown (Filtern)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Altersklasse filtern",
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                      value: dialogState.selectedFilterKlasse,
                      items: availableFilterKlassen.map((klasse) {
                        return DropdownMenuItem(
                          value: klasse,
                          child: Text(klasse),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          // Aktualisiere den Zustand
                          dialogState.selectedFilterKlasse = newValue!;
                          dialogState.selectedMatch =
                              null; // Auswahl zurücksetzen
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    // 2. Ligaspiel auswählen Dropdown
                    if (filteredMatches.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                            "Keine Ligaspiele, die den Filtern entsprechen."),
                      )
                    else
                      DropdownButtonFormField<TennisMatch>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: "Ligaspiel auswählen",
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
                        ),
                        value: dialogState.selectedMatch,
                        items: filteredMatches.map((m) {
                          final displayDate =
                              DateFormat('dd.MM.yyyy').format(m.datum);
                          final displayText =
                              "${m.altersklasse} | $displayDate: ${m.heim} - ${m.gast}";

                          return DropdownMenuItem(
                            value: m,
                            child: Text(displayText),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            // Aktualisiere den Zustand
                            dialogState.selectedMatch = value;
                          });
                        },
                      ),

                    // 🔑 NEU: Buttons sind JETZT Teil des StatefulBuilder-Contents!
                    // Dadurch werden sie bei jedem setState() neu bewertet.
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("Abbrechen")),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            // Button-Zustand wird immer korrekt aktualisiert
                            onPressed: dialogState.selectedMatch == null
                                ? null // Deaktiviert, wenn kein Match ausgewählt
                                : () async {
                                    // Zuordnungslogik
                                    final matchToUpdate =
                                        dialogState.selectedMatch!;
                                    matchToUpdate.spielbericht = news.id;

                                    await ligaProv
                                        .updateLigaSpiel(matchToUpdate);

                                    Navigator.pop(ctx);
                                    (context as Element)
                                        .findAncestorStateOfType<
                                            _NewsAdminScreenState>()
                                        ?._loadInitialData();
                                  },
                            child: const Text("Zuordnen"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // 🔑 KORREKTUR: actions-Feld ist leer oder entfernt
          actions: [],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final newsProv = Provider.of<NewsProvider>(context);

    // **Erweiterte Filterlogik anwenden**
    List<News> filtered = _allNews.where((n) {
      final isSpielbericht = n.category == "Spielbericht";
      final isAssigned = _assignedBerichtIDs.contains(n.id);

      // 1. Filter nach Kategorie
      if (_selectedCategory != 'Alle' && n.category != _selectedCategory) {
        return false;
      }

      // 2. Filter nach "Nur unzugeordnet"
      if (_filterUnassignedOnly) {
        // Wenn Filter aktiv: nur unzugeordnete Spielberichte anzeigen
        if (!isSpielbericht || isAssigned) {
          return false;
        }
      }

      // 3. Filter nach Altersklasse
      if (_selectedAltersklasse != 'Alle') {
        final isSpielbericht = n.category == "Spielbericht";
        final isAssigned = _assignedBerichtIDs.contains(n.id);

        if (isSpielbericht && isAssigned) {
          // Nur zugeordnete Spielberichte mit passender Altersklasse anzeigen
          final assignedMatch = _allMatches.firstWhere(
            (m) => m.spielbericht == n.id,
            // Fallback-Objekt muss ALLE required Felder im Konstruktor enthalten
            orElse: () => TennisMatch(
              id: '',
              datum: DateTime.now(),
              uhrzeit: '', // <--- HINZUGEFÜGT
              altersklasse: 'N/A',
              spielklasse: '', // <--- HINZUGEFÜGT
              gruppe: '', // <--- HINZUGEFÜGT
              heim: '',
              gast: '',
              spielort: '', // <--- HINZUGEFÜGT
              saison: '', // <--- HINZUGEFÜGT
              ergebnis: '',
              spielbericht: n.id,
              photoBlobSB: null, // <--- HINZUGEFÜGT
            ),
          ); // <- Der Klammer- und Semikolon-Fehler wurde behoben

          if (assignedMatch.altersklasse != _selectedAltersklasse) {
            return false;
          }
        } else {
          // Wenn Altersklasse ausgewählt, aber kein zugewiesener Spielbericht (oder gar kein Spielbericht), filtern
          return false;
        }
      }

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("News Verwaltung"),
        actions: const [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Container für die Filter-Elemente
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    // Column, um Row und Checkbox zu stapeln
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Dropdown zur Kategorie-Filterung
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: "Kategorie",
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 12),
                              ),
                              value: _selectedCategory,
                              items: _availableCategories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _selectedCategory = newValue!;
                                  // Wenn Kategorie gewechselt wird, Altersklassenfilter zurücksetzen, falls die neue Kat. kein Spielbericht ist
                                  if (newValue != 'Spielbericht') {
                                    _selectedAltersklasse = 'Alle';
                                  }
                                });
                              },
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: "Altersklasse",
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 12),
                              ),
                              value: _selectedAltersklasse,
                              // PASST HIER AN
                              items: _availableAltersklassen
                                  .map((altersklasse) {
                                    String displayText = altersklasse;
                                    if (altersklasse != 'Alle') {
                                      int count = _altersklassenWithCount[
                                              altersklasse] ??
                                          0;
                                      // Zeige nur Altersklassen mit min. einem Bericht an
                                      if (count == 0) return null;

                                      displayText = "$altersklasse ($count)";
                                    }
                                    return DropdownMenuItem(
                                      value: altersklasse,
                                      child: Text(displayText),
                                    );
                                  })
                                  .whereType<DropdownMenuItem<String>>()
                                  .toList(), // Entfernt alle null-Einträge

                              // ... (restliche onChanged Logik bleibt unverändert)
                              onChanged: (newValue) {
                                setState(() {
                                  _selectedAltersklasse = newValue!;
                                  // Beim Filtern nach Altersklasse muss die Kategorie "Spielbericht" sein
                                  if (newValue != 'Alle' &&
                                      _selectedCategory != 'Spielbericht' &&
                                      _availableCategories
                                          .contains('Spielbericht')) {
                                    _selectedCategory = 'Spielbericht';
                                    _filterUnassignedOnly = false;
                                  }
                                  if (newValue != 'Alle') {
                                    _filterUnassignedOnly = false;
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      // Checkbox zur Unzugeordnet-Filterung (nimmt jetzt volle Breite ein)
                      CheckboxListTile(
                        title: const Text("Nur unzugeordnete Spielberichte"),
                        value: _filterUnassignedOnly,
                        onChanged: (bool? newValue) {
                          setState(() {
                            _filterUnassignedOnly = newValue!;
                            if (_filterUnassignedOnly) {
                              // Beim Aktivieren: Kategorie auf Spielbericht setzen und Altersklasse zurücksetzen
                              if (_selectedCategory != 'Spielbericht' &&
                                  _availableCategories
                                      .contains('Spielbericht')) {
                                _selectedCategory = 'Spielbericht';
                              }
                              _selectedAltersklasse = 'Alle';
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                // --- NEUER COUNTER ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    // Zeigt die Anzahl der News im gefilterten Array an
                    "${filtered.length} News angezeigt",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                // ---
                // ERGEBNISLISTE
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                              "Keine News gefunden, die den Filtern entsprechen."),
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final n = filtered[i];

                            final isSpielbericht = n.category == "Spielbericht";
                            final isAssigned =
                                _assignedBerichtIDs.contains(n.id);

                            // Neues Widget für die Zuordnungsinformation
                            Widget matchInfoWidget = const SizedBox.shrink();

                            if (isSpielbericht) {
                              if (isAssigned) {
                                // Referenz gefunden: Altersklasse als klickbarer Link anzeigen
                                final assignedMatch = _allMatches.firstWhere(
                                  (m) => m.spielbericht == n.id,
                                  // Fallback, wenn Match aus irgendeinem Grund nicht gefunden wird
                                  orElse: () => TennisMatch(
                                    id: '',
                                    datum: DateTime.now(),
                                    uhrzeit: '',
                                    altersklasse: 'N/A',
                                    spielklasse: '',
                                    gruppe: '',
                                    heim: '',
                                    gast: '',
                                    spielort: '',
                                    saison: '',
                                    ergebnis: '',
                                    spielbericht: n.id,
                                    photoBlobSB: null,
                                  ),
                                );

                                // 🔑 KORREKTUR: Verwende TextButton, um die Match-Details anzuzeigen
                                matchInfoWidget = Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: TextButton(
                                    // Ruft die Funktion auf, die den Detail-Dialog öffnet
                                    onPressed: () {
                                      // Stellen Sie sicher, dass der Fallback 'N/A' nicht aufgerufen wird,
                                      // wenn kein Match gefunden wurde.
                                      if (assignedMatch.altersklasse != 'N/A') {
                                        showEditTeamResultDialog(
                                          context,
                                          assignedMatch,
                                          (updated) {
                                            Provider.of<LigaSpieleProvider>(
                                                    context,
                                                    listen: false)
                                                .updateLigaSpiel(updated);
                                          },
                                        );
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      // TextButton hat standardmäßig eine Polsterung.
                                      // Diese entfernt unnötigen Raum.
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      alignment: Alignment.centerLeft,
                                    ),
                                    child: Text(
                                      assignedMatch.altersklasse,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors
                                            .blue, // Blaue Farbe für Link-Look
                                        decoration: TextDecoration
                                            .underline, // Unterstreichung für Link-Look
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                // Nicht zugeordnet: Link-Icon anzeigen
                                matchInfoWidget = IconButton(
                                  tooltip: "Ligaspiel zuordnen",
                                  icon: const Icon(Icons.link),
                                  color: Colors.orange,
                                  onPressed: () => _openZuordnungPopup(n),
                                );
                              }
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text(n.title),
                                subtitle: Text("${n.date} — ${n.category}"),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    matchInfoWidget, // Altersklasse oder Link-Icon
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        newsProv.newsId = n.id;
                                        newsProv.newsDateController.text =
                                            n.date;
                                        newsProv.title.text = n.title;
                                        newsProv.body.text = n.body;
                                        newsProv.photoBlob = n.photoBlob;
                                        Navigator.of(context).pushNamed(
                                          NewsDetailScreen.routename,
                                          arguments: n.id,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

extension DateFormatExt on TennisMatch {
  String get datumFormatted =>
      "${datum.day.toString().padLeft(2, '0')}.${datum.month.toString().padLeft(2, '0')}.${datum.year}";

  String get datumZeitFormatted =>
      "${datum.day.toString().padLeft(2, '0')}.${datum.month.toString().padLeft(2, '0')}.${datum.year}, "
      "${datum.hour.toString().padLeft(2, '0')}:${datum.minute.toString().padLeft(2, '0')} Uhr";
}

class _DialogState {
  TennisMatch? selectedMatch;
  String selectedFilterKlasse = 'Alle';
}
