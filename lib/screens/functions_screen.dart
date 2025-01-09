import 'package:flutter/material.dart';
import './place_booking_screen.dart';
// import './place_booking_screen.dart';
import './photo_gallery_screen.dart';
import './trainers_screen.dart';
import './documents_screen.dart';
import './game_results_screen.dart';
import '../widgets/function_tile.dart';

class FunctionsScreen extends StatelessWidget {
  const FunctionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 15,
            ),
          ),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            delegate: SliverChildListDelegate(
              [
                //Ohne Anmeldung
                FunctionTile(
                    image: Image.asset("assets/images/Spielergebnisse.jpg"),
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed(GameResultsScreen.routename);
                    }), // Done (Kann verbessert werden)
                FunctionTile(
                    image: Image.asset("assets/images/Dokumentenbox.jpg"),
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed(DocumentsScreen.routename);
                    }), // Done
                FunctionTile(
                    image: Image.asset("assets/images/Trainer.jpg"),
                    onTap: () {
                      Navigator.of(context).pushNamed(TrainersScreen.routename);
                    }), // Done
                FunctionTile(
                    image: Image.asset("assets/images/Fotogalerie.jpg"),
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed(PhotoGalleryScreen.routename);
                    }), //Fotogalerie
                //Datenbank + Möglichkeit Fotos hochzuladen
                //Nur mit Anmeldung
                FunctionTile(
                  image: Image.asset("assets/images/Spielergebnisse.jpg"),
                  onTap: () {
                    Navigator.of(context)
                        .pushNamed(PlaceBookingScreen.routename);
                  },
                ), // Platzbuchung
                // // Verbindund zu Website der Platzbuchung und app
                // FunctionTile(
                //     image: Image.asset("assets/images/Spielergebnisse.jpg"),
                //     onTap: () {}), //Getränkeabrechnung
                // // auf einer Datenbank? speichern
                // FunctionTile(
                //     image: Image.asset("assets/images/Spielergebnisse.jpg"),
                //     onTap: () {}), //Termine
                // //Kalender mit auf Datenbank gespeicherten Terminen
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
