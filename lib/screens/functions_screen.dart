import 'package:flutter/material.dart';
import 'package:verein_app/screens/documents_screen.dart';
import '../screens/game_results.dart';
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
                    tap: () {
                      Navigator.of(context).pushNamed(GameResults.routename);
                    }), // Datenbank od. scrapping von Website(?)
                FunctionTile(
                    title: "Dokumentenbox",
                    tap: () {
                      Navigator.of(context)
                          .pushNamed(DocumentsScreen.routename);
                    }), // Dokumente + Download od. pdf - reader (?)
                FunctionTile(
                    title: "Mannschaften",
                    tap: () {}), // Wovon sollen Mannschaften genommen werden?
                FunctionTile(
                    title: "Trainer",
                    tap: () {}), // Emails und Handynummern der Trainer
                FunctionTile(
                    title: "Fotogalerie", tap: () {}), //Datenbank + Möglichkeit Fotos hochzuladen

                //Nur mit Anmeldung
                FunctionTile(
                    title: "Platzbuchung",
                    tap:
                        () {}), // Verbindund zw. Website der Platzbuchung und app
                FunctionTile(
                    title: "Getränkeabrechnung",
                    tap: () {}), // auf einer Datenbank? speichern
                FunctionTile(
                    title: "Kalender & Termine",
                    tap:
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
