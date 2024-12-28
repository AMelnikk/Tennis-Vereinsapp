import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GameResultsTile extends StatelessWidget {
  const GameResultsTile({super.key, required this.name, required this.url});

  final String name;
  final String url;

  Image teamIcon() {
    if (name.startsWith("Damen")) {
      return Image.asset("assets/images/Woman_icon.png");
    } else if (name.startsWith("Bambini") || name.startsWith("Dunlop")) {
      return Image.asset("assets/images/Man_Woman_icon.png");
    } else {
      return Image.asset("assets/images/Man_icon.png");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(5)),
      child: InkWell(
        splashColor: Colors.grey,
        onTap: () {
          launchUrl(
            Uri.parse(url),
            mode: LaunchMode.inAppBrowserView
          );
        },
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: teamIcon(),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(child: Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Text(name),
            )),
          ],
        ),
      ),
    );
  }
}
