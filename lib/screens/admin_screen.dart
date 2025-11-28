import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/add_team_result.dart';
import '../providers/user_provider.dart';
import './add_team_game_screen.dart';
import './news_admin_screen.dart';
import './add_termine_screen.dart';
import './getraenke_summen_screen.dart';
import './getraenkedetails_screen.dart';
import './add_team_screen.dart';
import '../screens/add_user_screen.dart';
import './add_news_screen.dart';
import '../widgets/admin_function.dart';
import '../widgets/verein_appbar.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});
  static const routename = "/admin-screen";

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return Scaffold(
      appBar: VereinAppbar(),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Anzeigen für Admin und Mannschaftsführer
              FutureBuilder<bool>(
                future: userProvider.isAdminOrMannschaftsfuehrer(context),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator(); // Ladeanzeige
                  }

                  if (snapshot.data == true) {
                    return Column(
                      children: [
                        AdminFunction(
                          function: () {
                            Navigator.of(context)
                                .pushNamed(AddNewsScreen.routename);
                          },
                          text: "Neuigkeiten hinzufügen",
                        ),
                      ],
                    );
                  } else {
                    return SizedBox(); // Wenn der Benutzer nicht Admin oder Mannschaftsführer ist, nichts anzeigen
                  }
                },
              ),

              // Nur für Admins anzeigen
              FutureBuilder<bool>(
                future: userProvider.isAdmin(context),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator(); // Ladeanzeige
                  }
                  if (snapshot.data == true) {
                    return Column(
                      children: [
//                        AdminFunction(
//                          function: () {
//                            Navigator.of(context)
//                                .pushNamed(AddPhotoScreen.routename);
//                          },
//                          text: "Fotos hinzufügen",
//                        ),
                        AdminFunction(
                          function: () {
                            Navigator.of(context)
                                .pushNamed(AddTeamResultScreen.routename);
                          },
                          text: "Ligaspiele verwalten",
                        ),
                        AdminFunction(
                          function: () {
                            Navigator.of(context)
                                .pushNamed(NewsAdminScreen.routename);
                          },
                          text: "News verwalten",
                        ),
                        AdminFunction(
                          function: () {
                            Navigator.of(context)
                                .pushNamed(AddMannschaftScreen.routename);
                          },
                          text: "Mannschaft verwalten",
                        ),

                        AdminFunction(
                          function: () {
                            Navigator.of(context)
                                .pushNamed(AddLigaSpieleScreen.routename);
                          },
                          text: "Ligaspiele hochladen",
                        ),

                        AdminFunction(
                          function: () {
                            Navigator.of(context).pushNamed(
                                GetraenkeBuchungenDetailsScreen.routename);
                          },
                          text: "Alle Getränkebuchungen Details",
                        ),
                        AdminFunction(
                          function: () {
                            Navigator.of(context)
                                .pushNamed(GetraenkeSummenScreen.routename);
                          },
                          text: "Getränke Summen",
                        ),
                        AdminFunction(
                          function: () {
                            Navigator.of(context)
                                .pushNamed(AddUserScreen.routename);
                          },
                          text: "Benutzer verwalten",
                        ),
                        AdminFunction(
                          function: () {
                            Navigator.of(context)
                                .pushNamed(AddTermineScreen.routename);
                          },
                          text: "Termine hochladen",
                        ),
                      ],
                    );
                  } else {
                    return SizedBox(); // Wenn der Benutzer kein Admin ist, nichts anzeigen
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
