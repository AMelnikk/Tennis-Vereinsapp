import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './datenschutz_screen.dart';
import './auth_screen.dart';
import './impressum_screen.dart';
import '../widgets/more_tile.dart';
import '../providers/auth_provider.dart';
import '../screens/admin_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: GridView(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 25,
          mainAxisSpacing: 25,
        ),
        children: [
          MoreTile(
            function: () {
              Navigator.of(context).pushNamed(ImpressumScreen.routename);
            },
            assetImage: "assets/images/Impressum.png",
          ),
          MoreTile(
              function: () {
                Navigator.of(context).pushNamed(DatenschutzScreen.routename);
              },
              assetImage: "assets/images/Datenschutz.png"),
          if (Provider.of<AuthProvider>(context).isSignedIn == false)
            MoreTile(
              function: () {
                Navigator.of(context).pushNamed(AuthScreen.routeName);
              },
              assetImage: "assets/images/Anmelden.png",
            ),
          if (Provider.of<AuthProvider>(context).isSignedIn)
            MoreTile(
                function: Provider.of<AuthProvider>(context).signOut,
                assetImage: "assets/images/Abmelden.png"),
          if (Provider.of<AuthProvider>(context).userId ==
              "UvqMZwTqpcYcLUIAe0qg90UNeUe2")
            MoreTile(
              function: () {
                Navigator.of(context).pushNamed(AdminScreen.routename);
              },
              assetImage: "assets/images/Admin-Funktionen.png",
            ),
        ],
      ),
    );
  }
}
