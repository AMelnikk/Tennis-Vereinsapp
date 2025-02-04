import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:verein_app/models/calendar_event.dart';
import 'package:verein_app/models/season.dart';
import 'package:verein_app/models/team.dart';
import 'package:verein_app/models/tennismatch.dart';
import 'package:verein_app/providers/season_provider.dart';
import 'package:verein_app/providers/team_result_provider.dart';

class TeamDetailScreen extends StatefulWidget {
  static const routename = "/team-detail";

  const TeamDetailScreen({super.key});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  late Team team;
  int activeTab = 0; // 0 = Spiele, 1 = Spieler/-innen

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Team) {
      team = args;
    } else {
      team = Team.empty();
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Saison: ${saisonData.saison}"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Foto Container
            if (team.photoBlob != null && team.photoBlob!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 4), // Minimaler Abstand
                child: Image.memory(
                  team.photoBlob!,
                  width: 600, // Breiter
                  height: 300, // Höhe beibehalten
                  fit: BoxFit.contain, // Seitenverhältnis beibehalten
                ),
              ),

            // Mannschaft Details - Aufruf der ausgelagerten Methode
            getMannschaftDetails(saisonData),

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
              FutureBuilder<Widget>(
                future: getMannschaftsSpiele(
                    activeTab, team.mannschaft, saisonData),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Fehler: ${snapshot.error}'));
                  } else if (snapshot.hasData) {
                    return snapshot
                        .data!; // Das Widget, das zurückgegeben wurde
                  } else {
                    return Center(child: Text('Keine Daten verfügbar'));
                  }
                },
              ),
            if (activeTab == 1) getSpieler(activeTab),
          ],
        ),
      ),
    );
  }

  Widget getMannschaftDetails(SaisonData saisonData) {
    return Container(
      padding: EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8), // Mehr Rand
            child: ElevatedButton(
              onPressed: () {}, // Aktion hier hinzufügen
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.symmetric(
                    vertical: 16), // Mehr Innenabstand
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // Ecken eckig
                ),
              ),
              child: Text(
                "${saisonData.saison} - ${team.mannschaft}",
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold, // Falls Hervorhebung gewünscht
                ),
                textAlign: TextAlign.center, // Zentrierter Text
              ),
            ),
          ),
          const SizedBox(height: 5),
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
          Row(
            children: [
              const Icon(Icons.phone, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  team.mfTel.isNotEmpty ? team.mfTel : "Nicht verfügbar",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4), // Etwas mehr Abstand zur Liga-Info
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
          const SizedBox(height: 10),
          Center(
            child: ElevatedButton(
              onPressed: _openNuLigaLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 14),
              ),
              child: const Text("nuLiga öffnen",
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Future<Widget> getMannschaftsSpiele(
      int activeTab, String mannschaftName, SaisonData saisonData) async {
    if (activeTab == 0) {
      if (saisonData == null) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text("Saison-Daten für die Mannschaft nicht gefunden."),
        );
      }

      List<TennisMatch> mannschaftsSpiele = [];

      if (saisonData.jahr != -1) {
        List<TennisMatch> spieleErstesJahr =
            await Provider.of<LigaSpieleProvider>(context, listen: false)
                .getLigaSpieleForMannschaft(
                    saisonData.jahr, mannschaftName, saisonData.key);
        mannschaftsSpiele.addAll(spieleErstesJahr);
      }

      if (saisonData.jahr2 != -1) {
        List<TennisMatch> spieleZweitesJahr =
            await Provider.of<LigaSpieleProvider>(context, listen: false)
                .getLigaSpieleForMannschaft(
                    saisonData.jahr2, mannschaftName, saisonData.key);
        mannschaftsSpiele.addAll(spieleZweitesJahr);
      }

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

      return Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: mannschaftsSpiele.length,
            itemBuilder: (context, index) {
              TennisMatch spiel = mannschaftsSpiele[index];

              String heim = spiel.heim == "TeG Altmühlgrund"
                  ? spiel.altersklasse
                  : spiel.heim;
              String gast = spiel.gast == "TeG Altmühlgrund"
                  ? spiel.altersklasse
                  : spiel.gast;

              bool ergebnisVorhanden =
                  spiel.ergebnis.isNotEmpty && spiel.ergebnis.contains(":");
              String ergebnisText = spiel.ergebnis;

              Color ergebnisFarbe = Colors.yellowAccent!;
              if (ergebnisVorhanden) {
                List<String> ergebnisTeile = spiel.ergebnis.split(":");
                int heimMatchpunkte = int.tryParse(ergebnisTeile[0]) ?? 0;
                int gastMatchpunkte = int.tryParse(ergebnisTeile[1]) ?? 0;

                if ((heimMatchpunkte > gastMatchpunkte &&
                        spiel.heim == "TeG Altmühlgrund") ||
                    (heimMatchpunkte < gastMatchpunkte &&
                        spiel.gast == "TeG Altmühlgrund")) {
                  ergebnisFarbe = Colors.green;
                } else if (heimMatchpunkte == gastMatchpunkte) {
                  ergebnisFarbe = Colors.grey;
                } else {
                  ergebnisFarbe = Colors.red;
                }
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Heim Box (35% der Gesamtbreite)
                  Expanded(
                    flex: 40,
                    child: Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 0), // Kleines Padding für Text
                      decoration: BoxDecoration(
                        color: heim == team.mannschaft
                            ? Colors.blueAccent
                            : Colors.white,
                        border: Border.all(color: Colors.black, width: 0.5),
                      ),
                      alignment: Alignment.centerLeft, // Linksbündig
                      child: Text(
                        " $heim",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  // Ergebnis Box (20% der Gesamtbreite)
                  Expanded(
                    flex: 20,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: ergebnisFarbe,
                        border: Border.all(color: Colors.black, width: 0.5),
                      ),
                      alignment: Alignment.center, // Zentriert
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (ergebnisText.isEmpty) ...[
                            Text(
                              DateFormat('dd.MM.yy').format(spiel.datum),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              spiel.uhrzeit,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                          if (ergebnisText.isNotEmpty) ...[
                            Text(
                              ergebnisText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              DateFormat('dd.MM.yy').format(spiel.datum),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Gast Box (35% der Gesamtbreite)
                  Expanded(
                    flex: 40,
                    child: Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 0), // Kleines Padding für Text
                      decoration: BoxDecoration(
                        color: gast == team.mannschaft
                            ? Colors.blueAccent
                            : Colors.white,
                        border: Border.all(color: Colors.black, width: 0.5),
                      ),
                      alignment: Alignment.centerLeft, // Linksbündig
                      child: Text(
                        " $gast",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    return Container(); // Fallback für andere Tabs
  }

  Widget getSpieler(int activeTab) {
    if (activeTab == 0) {
      return Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
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
