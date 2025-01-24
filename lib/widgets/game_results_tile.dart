import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/game_result.dart';

class GameResultsTile extends StatelessWidget {
  const GameResultsTile({super.key, required this.gameResult});

  final GameResult gameResult;

  Image teamIcon() {
    if (gameResult.mannschaft.startsWith("Damen")) {
      return Image.asset("assets/images/Woman_icon.png");
    } else if (gameResult.mannschaft.startsWith("Bambini") ||
        gameResult.mannschaft.startsWith("Dunlop")) {
      return Image.asset("assets/images/Man_Woman_icon.png");
    } else {
      return Image.asset("assets/images/Man_icon.png");
    }
  }

  Future<void> _launchURL() async {
    final Uri url = Uri.parse(gameResult.url);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.inAppBrowserView);
    } else {
      throw 'Could not launch ${gameResult.url}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: InkWell(
        splashColor: Colors.grey,
        onTap: _launchURL, // Link öffnen
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: teamIcon(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Text(
                  gameResult.mannschaft,
                  style: const TextStyle(
                    color: Colors.blue, // Farbe für das "klickbare" Element
                    decoration:
                        TextDecoration.underline, // Optional: Unterstreichen
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
