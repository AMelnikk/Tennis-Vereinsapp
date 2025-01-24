import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/game_result.dart';

class GameResultsTile extends StatelessWidget {
  const GameResultsTile({super.key, required this.gameResult});

  final GameResult gameResult;

  // Logik für die Hintergrundfarbe
  Color? getBackgroundColor() {
    const highlightedLeagues = ["Nordliga1", "Landesliga 1", "Landesliga 2"];
    return highlightedLeagues.contains(gameResult.liga)
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
      if (gameResult.mannschaft.startsWith(key)) {
        return Image.asset(iconMap[key]!, width: 40, height: 40);
      }
    }
    return Image.asset("assets/images/Man_icon.png", width: 40, height: 40);
  }

  Future<void> _launchURL(BuildContext context) async {
    final Uri? url = Uri.tryParse(gameResult.url);
    if (url != null && await canLaunchUrl(url)) {
      try {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication, // Externer Browser
        );
      } catch (e) {
        print('Fehler beim Öffnen der URL: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the link.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid URL: ${gameResult.url}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
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
              onTap: () => _launchURL(context),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  gameResult.mannschaft,
                  style: const TextStyle(
                    fontSize: 18, // Schriftgröße für den Teamnamen
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                gameResult.liga,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
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
                gameResult.gruppe,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // BTV-Symbol
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: IconButton(
              icon: Image.asset(
                'assets/images/BTV.jpg', // Dein benutzerdefiniertes Icon
                width: 40, // Größe des Icons
                height: 40,
              ),
              onPressed: () => _launchURL(context), // URL aufrufen bei Klick
            ),
          ),
        ],
      ),
    );
  }
}
