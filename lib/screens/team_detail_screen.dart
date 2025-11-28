// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:verein_app/popUps/edit_team_result_dialog.dart';
import 'package:verein_app/popUps/show_images_dialog.dart';
import 'package:verein_app/popUps/show_team_popup.dart';
import 'package:verein_app/providers/team_provider.dart';
import 'package:verein_app/providers/user_provider.dart';
import 'package:verein_app/utils/image_helper.dart';
import '../models/season.dart';
import '../models/team.dart';
import '../models/tennismatch.dart';
import '../providers/season_provider.dart';
import '../providers/team_result_provider.dart';

import '../widgets/match_row.dart';

class TeamDetailScreen extends StatefulWidget {
  static const routename = "/team-detail";

  const TeamDetailScreen({super.key});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  late Team team;
  int activeTab = 0; // 0 = Spiele, 1 = Spieler/-innen
  bool _isInitialized = false;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _canEdit = false;
  bool _isLoadingPermission = true; // Zeigt an, ob die Prüfung noch läuft

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      // 1️⃣ Team initialisieren
      final args = ModalRoute.of(context)!.settings.arguments as Team?;
      if (args != null) {
        team = args;
      } else {
        return;
      }
      // 2️⃣ Provider holen
      final ligaProvider =
          Provider.of<LigaSpieleProvider>(context, listen: false);
      final saisonProvider =
          Provider.of<SaisonProvider>(context, listen: false);

      // 3️⃣ Saison suchen
      final saisonData = saisonProvider.saisons.firstWhere(
        (s) => s.key == team.saison,
        orElse: () => SaisonData(key: '', saison: '', jahr: -1, jahr2: -1),
      );

      // 4️⃣ Spiele laden
      if (saisonData.key.isNotEmpty &&
          !ligaProvider.isLigaSpieleLoaded(team.saison)) {
        Future.microtask(() async {
          await ligaProvider.loadLigaSpieleForSeason(saisonData);
          if (mounted) setState(() {}); // Build aktualisieren
        });
      }

      _isInitialized = true;
    }
  }

  void _openNuLigaLink() async {
    final url = Uri.parse(team.url);
    await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final saisonProvider = Provider.of<SaisonProvider>(context, listen: false);
    final saisonData = saisonProvider.getSaisonDataForSaisonKey(team.saison);
    final teamProvider = Provider.of<TeamProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${saisonData.saison} - ${team.mannschaft}",
          style: const TextStyle(
            fontSize: 18.0, // 👈 Hier die gewünschte Größe festlegen
            // optional: fontWeight: FontWeight.bold,
            // optional: color: Colors.white, // Wenn Sie die Schriftfarbe ändern möchten
          ),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(team); // <--- Gibt das Team-Objekt zurück
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Mannschaft Details inklusive Mannschaftsbild
            getMannschaftDetails(saisonData, team, teamProvider.imageCache),

            // Tab Navigation
            Container(
              color: Colors.grey,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => setState(() => activeTab = 0),
                    child: Text(
                      "Spiele",
                      style: TextStyle(
                        color:
                            activeTab == 0 ? Colors.blueAccent : Colors.white,
                        fontWeight: activeTab == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => activeTab = 1),
                    child: Text(
                      "Spieler/-innen",
                      style: TextStyle(
                        color:
                            activeTab == 1 ? Colors.blueAccent : Colors.white,
                        fontWeight: activeTab == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Anzeige der Tabs
            if (activeTab == 0)
              getMannschaftsSpieleWidget(
                  team.mannschaft, saisonData), // NEUE METHODE
            if (activeTab == 1) getSpieler(activeTab),
          ],
        ),
      ),
    );
  }

  // NEUE Methode, ersetzt die alte getMannschaftsSpiele
  Widget getMannschaftsSpieleWidget(
      String mannschaftName, SaisonData saisonData) {
    // Consumer lauscht auf Änderungen im LigaSpieleProvider und wird neu aufgebaut,
    // sobald notifyListeners() aufgerufen wird (z.B. nach dem Laden in didChangeDependencies).
    return Consumer<LigaSpieleProvider>(
      builder: (context, ligaProvider, child) {
        // NEU: Zustand 1 - Lädt die Daten gerade
        if (ligaProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        // HINWEIS: Wenn die Daten beim ersten Laden leer sind UND der Ladevorgang
        // abgeschlossen ist (isLoading == false), gehen wir davon aus, dass keine Daten existieren.

        // Filtern der Spiele basierend auf den Daten im Provider
        final List<TennisMatch> mannschaftsSpiele =
            ligaProvider.getFilteredSpiele(
          saisonKey: saisonData.key,
          jahr: null,
          altersklasse: mannschaftName,
        );

        // Zustand 2: Kein Spiel gefunden (nachdem Laden beendet ist)
        if (mannschaftsSpiele.isEmpty) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text("Keine Spiele gefunden."),
          );
        }

        // Zustand 3: Baue das UI mit Spielen + Spielberichten
        return Column(
          children: [
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: mannschaftsSpiele.length,
                  itemBuilder: (context, index) {
                    TennisMatch spiel = mannschaftsSpiele[index];
                    return MatchRow(
                      spiel: spiel,
                      teamName: mannschaftName,
                      onEdit: _canEdit ? _openSpielberichtAction : null,
                      onDelete: _canEdit ? _confirmDeleteSpielbericht : null,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Methode 1: Öffnet den Dialog/Screen zum Bearbeiten oder Eintragen
  void _openSpielberichtAction(TennisMatch spiel) async {
    // Entferne den Navigations-Code (MaterialPageRoute) und nutze NUR den Dialog

    // Ruft den Dialog zur Eingabe/Bearbeitung auf
    showEditTeamResultDialog(
      context,
      spiel,
      // Callback-Funktion, die ausgeführt wird, NACHDEM der Dialog das aktualisierte Match zurückgibt
      (updatedMatch) async {
        // 1. Aktualisiert die Daten im Provider (z.B. Datenbank-Update)
        await Provider.of<LigaSpieleProvider>(context, listen: false)
            .updateLigaSpiel(updatedMatch);

        // 2. Aktualisiert das aktuelle Widget (TeamDetailScreen), um die neue Liste anzuzeigen
        setState(() {});
      },
    );

    // Der gesamte 'if (result is TennisMatch && mounted)' Block, der sich auf den
    // Navigator-Push bezieht, ist jetzt überflüssig und kann entfernt werden.
  }

  void _confirmDeleteSpielbericht(TennisMatch spiel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Spielbericht löschen?'),
        content: Text(
            'Sind Sie sicher, dass Sie den Spielbericht für ${spiel.heim} - ${spiel.gast} löschen möchten?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              // Callback muss async sein wegen await

              // 1. Modifizierbare Kopie des Matches erstellen und Felder leeren
              final updatedMatch = spiel.copyWith(
                ergebnis: "",
                spielbericht: "",
              );

              // 2. Provider aufrufen und auf Abschluss warten
              // Wir verwenden den context des Dialogs (ctx), da wir uns noch innerhalb des Dialogs befinden.
              await Provider.of<LigaSpieleProvider>(ctx, listen: false)
                  .updateLigaSpiel(updatedMatch);

              // 3. Dialog schließen
              Navigator.of(ctx).pop();

              // 4. Prüfen, ob das Widget noch existiert (mounted check)
              //    bevor der externe context für die Snackbar verwendet wird.
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Spielbericht gelöscht!')));
              }
            },
            child: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

// **WICHTIG:** Die alte Methode `Future<Widget> getMannschaftsSpiele(...)` kann jetzt entfernt werden.

  Widget getMannschaftDetails(
      SaisonData saisonData, dynamic team, Map<String, Uint8List> imageCache) {
    return Container(
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🖼️ NEU: Mannschaftsbilder mit Paging
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: buildImageSection(team.photoBlob, imageCache),
          ),

          const SizedBox(height: 10),

          // 👤 Mannschaftsführer
          const Text(
            "Mannschaftsführer:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.person, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  team.mfName.isNotEmpty ? team.mfName : "Nicht verfügbar",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),
          // 📞 Telefonnummer, nuLiga Button und Edit Button in EINER Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Telefonnummer
              const Icon(Icons.phone, size: 20),
              const SizedBox(width: 8),
              Text(
                team.mfTel.isNotEmpty ? team.mfTel : "Nicht verfügbar",
                style: const TextStyle(fontSize: 16),
              ),

              const Spacer(),

              // 2. nuLiga Button (Mitte)
              ElevatedButton(
                onPressed: _openNuLigaLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 14),
                ),
                child: const Text(
                  "nuLiga öffnen",
                  style: TextStyle(color: Colors.white),
                ),
              ),

              // 🚀 Spacer, um den Edit Button ganz nach rechts zu drücken
              const Spacer(),

              // 3. ✅ Edit Button (ganz rechts)
              _isLoadingPermission
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _canEdit
                      ? IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: _openEditDialog,
                        )
                      : const SizedBox.shrink(),
            ],
          ),

          const SizedBox(height: 4),

          // 🎾 Liga und Gruppe
          Row(
            children: [
              const Icon(Icons.sports_tennis, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${team.liga} - ${team.gruppe}",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),
          // 🔗 NuLiga Link Button
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  void _loadPermissions() async {
    // 1. Provider und IDs abrufen
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Annahme: 'team' ist über 'widget.team' in der State-Klasse verfügbar.
    final currentUserId = userProvider.user.uid;

    // 2. Asynchrone Prüfung: Ist der User Admin oder allgemeiner MF?
    final isGeneralAdmin = await userProvider.isAdmin(context);

    // 3. Synchrone Prüfung: Ist der User der spezifische MF dieser Mannschaft?
    // HINWEIS: Es wird '==' für den Vergleich und 'widget.team' (falls nötig) verwendet.
    final isSpecificMF = currentUserId == team.mfUID;

    // 4. Den State aktualisieren, falls das Widget noch aktiv ist
    if (mounted) {
      setState(() {
        // Setze _canEdit auf TRUE, wenn mindestens eine der Bedingungen erfüllt ist.
        _canEdit = isGeneralAdmin || isSpecificMF;
        _isLoadingPermission = false;
      });
    }
  }

// 2. Methode zum Anzeigen des MyTeamDialog
// (Annahme: MyTeamDialog gibt bei Erfolg das aktualisierte Team zurück)
  Future<Team?> _showTeamDialog(
      BuildContext context, List<SaisonData> seasons, Team teamData) async {
    // Ersetzen Sie MyTeamDialog und die Modelle/Provider durch Ihre tatsächlichen Klassen
    // Es ist wichtig, dass diese Methode existiert und den Dialog öffnet.
    final updatedTeam = await showDialog<Team>(
      context: context,
      builder: (BuildContext context) {
        // Annahme, dass MyTeamDialog hier korrekt instanziiert wird
        return MyTeamDialog(
          seasons: seasons,
          teamData: teamData,
        );
      },
    );
    return updatedTeam;
  }

// 3. Methode, die beim Klick auf den Edit-Button ausgelöst wird
  void _openEditDialog() async {
    // Annahme: Sie haben einen SaisonProvider zur Bereitstellung der Saisons
    final saisonProvider = Provider.of<SaisonProvider>(context, listen: false);

    // Öffnet den Dialog
    final updatedTeam = await _showTeamDialog(
      context,
      saisonProvider.saisons,
      team, // 'team' ist die State-Variable mit den aktuellen Details
    );
    if (updatedTeam != null && mounted) {
      setState(() {
        team = updatedTeam;
      });
    }
  }

  double _imageHeight() {
    double containerWidth = MediaQuery.of(context).size.width;
    double imageAspectRatio = 16 / 9;
    return containerWidth / imageAspectRatio;
  }

  Widget buildImageSection(
      List<String> photoBlob, Map<String, Uint8List> imageCache) {
    return photoBlob.isNotEmpty
        ? Container(
            width: double.infinity,
            height: _imageHeight(),
            color: Colors.white,
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    showImageDialog(context, photoBlob, _currentPage);
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: photoBlob.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      Uint8List bytes = getImage(imageCache, photoBlob[index]);

                      return FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.topCenter,
                        child: Image.memory(
                          bytes,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 50,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (_pageController.hasClients &&
                          (_pageController.page ?? 0) > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      }
                    },
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 50,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    onPressed: () {
                      if (_pageController.hasClients &&
                          (_pageController.page ?? 0) < photoBlob.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      }
                    },
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_currentPage + 1} / ${photoBlob.length}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          )
        : Container();
  }

  Widget getSpieler(int activeTab) {
    if (activeTab == 0) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Column(
          children: [
            // Placeholder for players (will be filled later)
            Text("Spieler/-innen - In Arbeit",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    return Container(); // Empty container if activeTab is not 1
  }
}
