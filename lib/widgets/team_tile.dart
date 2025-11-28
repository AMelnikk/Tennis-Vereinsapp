import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/team_detail_screen.dart';
import '../models/team.dart';
import 'dart:convert';
import 'dart:typed_data';

// ==========================================================
// 1. TeamTile: Das unveränderliche Widget (StatefulWidget)
// ==========================================================
class TeamTile extends StatefulWidget {
  // teamTile sollte in einem StatefulWidget IMMUTABLE sein (final)
  final Team teamTile;
  final Function(Team updatedTeam)? onUpdate;

  const TeamTile({
    super.key,
    required this.teamTile,
    this.onUpdate,
  });

  @override
  State<TeamTile> createState() => _TeamTileState();
}

// ==========================================================
// 2. _TeamTileState: Der veränderliche Zustand
// ==========================================================
// Die State-Klasse MUSS außerhalb des Widget-Bodys definiert werden.
class _TeamTileState extends State<TeamTile> {
  // 💡 Speichert die aktuelle (potentiell veränderte) Team-Instanz
  late Team _currentTeam;

  @override
  void initState() {
    super.initState();
    // Kopieren der initialen Daten vom Widget (widget.teamTile) in den State
    _currentTeam = widget.teamTile;
  }

  // Wichtig: Wenn die übergeordnete Liste sich ändert, wird didUpdateWidget benötigt,
  // um sicherzustellen, dass _currentTeam immer noch die korrekten Daten hält.
  // Das ist hier relevant, wenn der Parent die TeamTile mit neuen Daten neu erstellt.
  @override
  void didUpdateWidget(covariant TeamTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.teamTile != widget.teamTile) {
      _currentTeam = widget.teamTile;
    }
  }

  // --- Hilfsmethoden ---

  Color? getBackgroundColor() {
    const highlightedLeagues = ["Nordliga1", "Landesliga 1", "Landesliga 2"];
    // ZUGRIFF auf die State-Variable
    return highlightedLeagues.contains(_currentTeam.liga)
        ? Colors.lightGreen[100]
        : null;
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
      ),
    );
  }

  Future<void> _launchURL(BuildContext context) async {
    try {
      // ZUGRIFF auf die State-Variable
      final Uri url = Uri.parse(_currentTeam.url);
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Could not open the link.', Colors.redAccent);
      }
    }
  }

  // 👇 KORRIGIERTE ASYNCHRONE LOGIK
  void _navigateToDetailScreen() async {
    final result = await Navigator.pushNamed(
      context,
      TeamDetailScreen.routename,
      arguments: _currentTeam, // Senden des aktuellen Zustands
    );

    // Prüfen, ob ein aktualisiertes Team zurückgegeben wurde (nach dem Editieren)
    if (result is Team && mounted) {
      // 1. Lokalen Zustand aktualisieren und Widget neu bauen
      setState(() {
        _currentTeam = result;
      });

      // 2. Optional: Übergeordnetes Widget über die Änderung informieren (Callback)
      widget.onUpdate?.call(result);
    }
  }

  // --- Build Methode ---

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        // Ruft die Methode auf, die _currentTeam verwendet
        color: getBackgroundColor(),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// LINKS: Name + Gruppe + Liga UNTEREINANDER
          Expanded(
            child: InkWell(
              onTap:
                  _navigateToDetailScreen, // Ruft die Methode mit async/await auf
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentTeam.mannschaft, // 👈 ZUGRIFF auf _currentTeam
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentTeam.liga, // 👈 ZUGRIFF auf _currentTeam
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      _currentTeam.gruppe, // 👈 ZUGRIFF auf _currentTeam
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          /// MITTE: Mannschaftsbild
          Container(
            width: 120,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              // ZUGRIFF auf die State-Variable
              child: (_currentTeam.photoBlob.isNotEmpty)
                  ? Stack(
                      children: [
                        PageView.builder(
                          itemCount: _currentTeam
                              .photoBlob.length, // 👈 ZUGRIFF auf _currentTeam
                          itemBuilder: (context, index) {
                            Uint8List bytes = base64Decode(
                                _currentTeam.photoBlob[
                                    index]); // 👈 ZUGRIFF auf _currentTeam

                            return Image.memory(
                              bytes,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image),
                            );
                          },
                        ),
                        // Dots Logik (bleibt statisch, da PageView keine direkte Steuerung
                        // durch ein StatelessWidget-Dot-System erlaubt)
                        if (_currentTeam.photoBlob.length > 1)
                          Positioned(
                            bottom: 5,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                  _currentTeam.photoBlob.length, (index) {
                                return const Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 2.0),
                                  child: Icon(
                                    Icons.circle,
                                    size: 5,
                                    color: Colors.white70,
                                  ),
                                );
                              }),
                            ),
                          ),
                      ],
                    )
                  : const Center(
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 4),

          /// RECHTS: BTV-Icon
          if (_currentTeam.url.isNotEmpty) // 👈 ZUGRIFF auf _currentTeam
            IconButton(
              icon: Image.asset(
                'assets/images/BTV.jpg',
                width: 80,
                height: 80,
              ),
              onPressed: () => _launchURL(context),
            ),
        ],
      ),
    );
  }
}
