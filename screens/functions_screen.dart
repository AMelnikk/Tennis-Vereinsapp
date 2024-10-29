import 'package:flutter/material.dart';
import 'package:verein_app/screens/documents_screen.dart';
import 'game_results_screen.dart';
import '../widgets/function_tile.dart';

class FunctionsScreen extends StatelessWidget {
  const FunctionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 3,
            ),
          ),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            delegate: SliverChildListDelegate(
              [
                //Ohne Anmeldung
                FunctionTile(
                    title: "Spielergebnisse",
                    onTap: () {
                      Navigator.of(context).pushNamed(GameResultsScreen.routename);
                    }), // Datenbank od. scrapping von Website(?)
                FunctionTile(
                    title: "Dokumentenbox",
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed(DocumentsScreen.routename);
                    }), // Done
                FunctionTile(
                    title: "Trainer",
                    onTap: () {}), // Emails und Handynummern der Trainer
                FunctionTile(
                    title: "Fotogalerie", onTap: () {}), //Datenbank + Möglichkeit Fotos hochzuladen
                //Nur mit Anmeldung
                FunctionTile(
                    title: "Platzbuchung",
                    onTap:
                        () {}), // Verbindund zu Website der Platzbuchung und app
                FunctionTile(
                    title: "Getränkeabrechnung",
                    onTap: () {}), // auf einer Datenbank? speichern
                FunctionTile(
                    title: "Kalender & Termine",
                    onTap:
                        () {}), //Kalender mit auf Datenbank gespeicherten Terminen
              ],
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 5,
            ),
          ),
        ],
      ),
    );
  }
}
