import 'package:flutter/material.dart';
import 'package:verein_app/screens/getraenke_summen_screen.dart';
import 'package:verein_app/screens/getraenkedetails_screen.dart';
import 'package:verein_app/screens/add_mannschaft_screen.dart';
import '../screens/add_user_screen.dart';
import './add_news_screen.dart';
import './add_photo_screen.dart';
import '../widgets/admin_function.dart';
import '../widgets/verein_appbar.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});
  static const routename = "/admin-screen";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VereinAppbar(),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            AdminFunction(
                function: () {
                  Navigator.of(context).pushNamed(AddNewsScreen.routename);
                },
                text: "Neuigkeiten hinzufügen"),
            AdminFunction(
                function: () {
                  Navigator.of(context).pushNamed(AddPhotoScreen.routename);
                },
                text: "Fotos hinzufügen"),
            AdminFunction(
              function: () {
                Navigator.of(context).pushNamed(AddMannschaftScreen.routename);
              },
              text: "Mannschaft hinzufügen",
            ),
            AdminFunction(
                function: () {
                  Navigator.of(context).pushNamed(AddUserScreen.routename);
                },
                text: "Nutzer hinzufügen"),
            AdminFunction(
                function: () {
                  Navigator.of(context)
                      .pushNamed(GetraenkeBuchungenDetailsScreen.routename);
                },
                text: "Alle Getränkebuchungen Details"),
            AdminFunction(
              function: () {
                Navigator.of(context)
                    .pushNamed(GetraenkeSummenScreen.routename);
              },
              text: "Getränke Summen",
            )
          ],
        ),
      ),
    );
  }
}
