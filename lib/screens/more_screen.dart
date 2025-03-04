import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/screens/user_profile_screen.dart';
import '../providers/user_provider.dart';
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
            assetImage: "assets/images/Datenschutz.png",
          ),
          if (!Provider.of<AuthorizationProvider>(context).isSignedIn)
            MoreTile(
              function: () {
                Navigator.of(context).pushNamed(AuthScreen.routeName);
              },
              assetImage: "assets/images/Anmelden.png",
            ),
          if (Provider.of<AuthorizationProvider>(context).isSignedIn) ...[
            MoreTile(
              function:
                  Provider.of<AuthorizationProvider>(context, listen: false)
                      .signOut,
              assetImage: "assets/images/Abmelden.png",
            ),
            MoreTile(
              function: () {
                Navigator.of(context).pushNamed(UserProfileScreen.routename);
              },
              assetImage: "assets/images/Benutzerprofil.png",
            ),
          ], // <--- Korrekte Schließung der Bedingung
          FutureBuilder<bool>(
            future: Provider.of<UserProvider>(context, listen: false)
                .isAdminOrMannschaftsfuehrer(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(); // Oder ein Lade-Icon
              }
              if (snapshot.hasError || !(snapshot.data ?? false)) {
                return SizedBox(); // Falls kein Admin oder Fehler → nichts anzeigen
              }
              return MoreTile(
                function: () {
                  Navigator.of(context).pushNamed(AdminScreen.routename);
                },
                assetImage: "assets/images/Admin-Funktionen.png",
              );
            },
          ),
        ],
      ),
    );
  }
}
