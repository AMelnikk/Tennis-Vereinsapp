import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:verein_app/screens/team_detail_screen.dart';
import '../models/team.dart';

class TeamTile extends StatelessWidget {
  const TeamTile({super.key, required this.teamTile});

  final Team teamTile;

  // Logik für die Hintergrundfarbe
  Color? getBackgroundColor() {
    const highlightedLeagues = ["Nordliga1", "Landesliga 1", "Landesliga 2"];
    return highlightedLeagues.contains(teamTile.liga)
        ? Colors.lightGreen[100] // Hellgrün für die hervorgehobenen Ligen
        : null;
  }

  // Team-Icons je nach Mannschaft
  Image teamIcon() {
    const iconMap = {
      "Damen": "assets/images/Woman_icon.png",
      "Bambini": "assets/images/Man_Woman_icon.png",
      "Dunlop": "assets/images/Man_Woman_icon.png",
    };

    for (var key in iconMap.keys) {
      if (teamTile.mannschaft.startsWith(key)) {
        return Image.asset(iconMap[key]!, width: 40, height: 40);
      }
    }
    return Image.asset("assets/images/Man_icon.png", width: 40, height: 40);
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
      final Uri url = Uri.parse(teamTile.url); // Parse the URL
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication, // Open in external browser
      );
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(
          context,
          'Could not open the link.',
          Colors.redAccent,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color:
            getBackgroundColor(), // Hintergrundfarbe für hervorgehobene Ligen
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Teamname (verlinkt)
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  TeamDetailScreen.routename,
                  arguments: teamTile, // Hier das Team-Objekt übergeben
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: Text(
                  teamTile.mannschaft,
                  style: const TextStyle(
                    fontSize: 16, // Schriftgröße für den Teamnamen
                    fontWeight: FontWeight.bold,
                    color:
                        Colors.black, // Keine Unterstreichung oder blaue Farbe
                  ),
                ),
              ),
            ),
          ),
          // Liga
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(1),
              ),
              child: Text(
                teamTile.liga,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Gruppe
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                teamTile.gruppe,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // BTV-Symbol
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child:
                teamTile.url.isNotEmpty // Überprüfe, ob die URL nicht leer ist
                    ? IconButton(
                        icon: Image.asset(
                          'assets/images/BTV.jpg', // Dein benutzerdefiniertes Icon
                          width: 30, // Größe des Icons
                          height: 30,
                        ),
                        onPressed: () =>
                            _launchURL(context), // URL aufrufen bei Klick
                      )
                    : const SizedBox
                        .shrink(), // Falls die URL leer ist, nichts anzeigen
          ),
        ],
      ),
    );
  }
}
