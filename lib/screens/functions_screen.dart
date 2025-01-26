import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:verein_app/screens/calendar_screen.dart';
import 'package:verein_app/screens/getraenkebuchen_screen.dart';
import './place_booking_screen.dart';
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
                    image: Image.asset("assets/images/Spielergebnisse.webp"),
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed(GameResultsScreen.routename);
                    }), // Spielergebnisse
                FunctionTile(
                    image: Image.asset("assets/images/Dokumentenbox.webp"),
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed(DocumentsScreen.routename);
                    }), // Dokumentenbox
                FunctionTile(
                    image: Image.asset("assets/images/Trainer.webp"),
                    onTap: () {
                      Navigator.of(context).pushNamed(TrainersScreen.routename);
                    }), // Trainer
                FunctionTile(
                    image: Image.asset("assets/images/Fotogalerie.webp"),
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed(PhotoGalleryScreen.routename);
                    }), //Fotogalerie
                FunctionTile(
                    image: Image.asset("assets/images/Fotogalerie.webp"),
                    onTap: () {
                      Navigator.of(context).pushNamed(CalendarScreen.routename);
                    }),
                FunctionTile(
                  image: Image.asset("assets/images/Platzbuchung.webp"),
                  onTap: () {
                    Navigator.of(context)
                        .pushNamed(PlaceBookingScreen.routename);
                  },
                ), // Platzbuchung
                FunctionTile(
                  image: Image.asset("assets/images/Getränkebuchung.webp"),
                  onTap: () {
                    Navigator.of(context)
                        .pushNamed(GetraenkeBuchenScreen.routename);
                  },
                ), //Getränkeabrechnung
                FunctionTile(
                  image: Image.asset("assets/images/Online_shop.webp"),
                  onTap: () {
                    launchUrl(
                      Uri.parse(
                          "https://team.jako.com/de-de/team/teg_altmuehlgrund/"),
                    );
                  },
                ), //Online Shop

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
