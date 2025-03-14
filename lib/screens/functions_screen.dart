import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:verein_app/providers/user_provider.dart';
import '../screens/calendar_screen.dart';
import '../screens/getraenkebuchen_screen.dart';
import './place_booking_screen.dart';
import 'photo_gallery_screen.dart';
import './trainers_screen.dart';
import './documents_screen.dart';
import 'team_screen.dart';
import '../widgets/function_tile.dart';

class FunctionsScreen extends StatelessWidget {
  const FunctionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    UserProvider userProvider = Provider.of<UserProvider>(context);
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
                      Navigator.of(context).pushNamed(TeamScreen.routename);
                    }), // Spielergebnisse
                FunctionTile(
                    image: Image.asset("assets/images/Termine.webp"),
                    onTap: () {
                      Navigator.of(context).pushNamed(CalendarScreen.routename);
                    }),

                FunctionTile(
                  image: Image.asset("assets/images/Platzbuchung.webp"),
                  onTap: () {
                    if (userProvider.user.platzbuchungLink.isEmpty) {
                      _showLinkNotFoundDialog(context);
                    } else {
                      Navigator.of(context)
                          .pushNamed(PlaceBookingScreen.routename);
                    }
                  },
                ),
                FunctionTile(
                    image: Image.asset("assets/images/Fotogalerie.webp"),
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed(PhotoGalleryScreen.routename);
                    }), //Fotogalerie
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

  Future<void> _showLinkNotFoundDialog(BuildContext context) async {
    await Future.delayed(
      const Duration(milliseconds: 50),
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Hinweis"),
          content: const Text(
            "Im Userprofil kannst du deinen persönlichen Link hinterlegen, damit du direkt Plätze buchen kannst.",
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); 
              },
              child: const Text("Zurück"),
            ),
            TextButton(
              onPressed: () async {
                // Hier kannst du den gewünschten Link öffnen, wenn er vorhanden ist
                // Beispiel-Link für Platzbuchung
                Navigator.of(context).pop(); // Dialog schließen
                Navigator.of(context).pushNamed(PlaceBookingScreen.routename);
              },
              child: const Text("Weiter als Gast"),
            ),
          ],
        );
      },
    );
  }
}
