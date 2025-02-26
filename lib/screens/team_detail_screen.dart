import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/news.dart';
import '../models/season.dart';
import '../models/team.dart';
import '../models/tennismatch.dart';
import '../providers/news_provider.dart';
import '../providers/season_provider.dart';
import '../providers/team_result_provider.dart';
import '../screens/news_detail_screen.dart';
import '../utils/app_utils.dart';
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
    final messenger = ScaffoldMessenger.of(context); // Messenger holen
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
            if (team.photoBlob.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 4), // Minimaler Abstand
                child: Image.memory(
                  base64Decode(team.photoBlob[0]),
                  width: 450, // Breiter
                  height: 250, // Höhe beibehalten
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
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Fehler: ${snapshot.error}'));
                  } else if (snapshot.hasData) {
                    return snapshot
                        .data!; // Das Widget, das zurückgegeben wurde
                  } else {
                    appError(messenger, 'Keine Daten verfügbar');
                    return const Center(child: Text('Keine Daten verfügbar'));
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
      padding: const EdgeInsets.all(5),
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
                shape: const RoundedRectangleBorder(
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
    LigaSpieleProvider ligaProvider =
        Provider.of<LigaSpieleProvider>(context, listen: false);

    if (activeTab == 0) {
      List<TennisMatch> mannschaftsSpiele = [];
      List<String> spielberichtIds =
          []; // Hier speichern wir die IDs der Spielberichte

      try {
        await ligaProvider.loadLigaSpieleForSeason(saisonData);
        mannschaftsSpiele = ligaProvider.getFilteredSpiele(
          saisonKey: saisonData.key,
          jahr: null,
          altersklasse: mannschaftName,
        );

        // **Sammle die IDs der Spielberichte**
        for (var spiel in mannschaftsSpiele) {
          if (spiel.spielbericht.isNotEmpty) {
            spielberichtIds.add(spiel.spielbericht);
          }
        }
      } catch (e) {
        return const Center(child: Text("Fehler beim Laden der Spiele."));
      }

      if (!mounted) return Container();

      // **Kein Spiel gefunden**
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

      // **Baue das UI mit Spielen + Spielberichten**
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
                  );
                },
              ),
            ),
          ),

          // **Spielberichte unterhalb der Spiele anzeigen**
          if (spielberichtIds.isNotEmpty)
            getMannschaftsSpielberichte(spielberichtIds),
        ],
      );
    }

    return Container(); // Falls ein anderer Tab aktiv ist
  }

  Widget getMannschaftsSpielberichte(List<String> spielberichtIds) {
    NewsProvider newsProvider =
        Provider.of<NewsProvider>(context, listen: false);
    return FutureBuilder<List<News>>(
      future: newsProvider
          .loadMannschaftsNews(spielberichtIds), // IDs der Spielberichte
      builder: (context, newsSnapshot) {
        if (newsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (newsSnapshot.hasError) {
          return Center(child: Text('Fehler: ${newsSnapshot.error}'));
        } else if (newsSnapshot.hasData && newsSnapshot.data!.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Spielberichte",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: newsSnapshot.data!.length,
                itemBuilder: (context, index) {
                  final news = newsSnapshot.data![index];
                  return Card(
                    child: ListTile(
                      title: Text(news.title),
                      subtitle: Text(news.date),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          NewsDetailScreen
                              .routename, // Korrekte Nutzung des statischen Routennamens
                          arguments: {
                            // Korrekte Verwendung des routename
                            "id": news.id,
                            "title": news.title,
                            "body": news.body,
                            "date": news.date,
                            "author": news.author,
                            "category": news.category,
                            "photoBlob": news.photoBlob,
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          );
        } else {
          return const Center(child: Text('Keine Spielberichte verfügbar'));
        }
      },
    );
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
