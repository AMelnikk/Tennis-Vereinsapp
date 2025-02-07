import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/popUps/show_images_dialog.dart';
import 'package:verein_app/utils/image_helper.dart';
import '../providers/news_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/verein_appbar.dart';

class NewsOverviewScreen extends StatefulWidget {
  static const routename = '/news-overview';

  const NewsOverviewScreen({super.key});

  @override
  NewsOverviewScreenState createState() => NewsOverviewScreenState();
}

class NewsOverviewScreenState extends State<NewsOverviewScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0; // Track the current page

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments as Map;
    final List<String> photoBlob = arguments["photoBlob"] != null
        ? List<String>.from(arguments["photoBlob"])
        : [];
    final imageCache =
        Provider.of<NewsProvider>(context, listen: false).imageCache;

    return Scaffold(
      appBar: VereinAppbar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 10), // Seitlicher Rand für den grauen Container
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors
                .grey[300], // Grauer Rand um den gesamten weißen Container
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Column(
            children: [
              // Bereich für die Anzeige der Bilder
              buildImageSection(photoBlob, imageCache),

              // Bereich für den Text (nimmt den verbleibenden Platz nach dem Bild ein)
              Expanded(
                // Diese Zeile sorgt dafür, dass der Textbereich den restlichen Platz einnimmt
                child: SingleChildScrollView(
                  child: Container(
                    color: Colors.white, // Weißer Container für den Inhalt
                    child: Column(
                      children: [
                        // Bereich für den Titel, Datum und Text
                        buildTextSection(arguments),

                        // Wenn der Benutzer der Admin ist, Button zum Löschen
                        if (Provider.of<AuthProvider>(context).isSignedIn &&
                            Provider.of<AuthProvider>(context).userId ==
                                "UvqMZwTqpcYcLUIAe0qg90UNeUe2")
                          IconButton(
                            onPressed: () {
                              Provider.of<NewsProvider>(context, listen: false)
                                  .deleteNews(arguments["id"]);
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Color.fromARGB(255, 104, 23, 18)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Methode für den Bereich der Bildanzeige
  Widget buildImageSection(
      List<String> photoBlob, Map<String, Uint8List> imageCache) {
    return photoBlob.isNotEmpty
        ? Container(
            width: double.infinity,
            height:
                _imageHeight(), // Dynamische Höhe basierend auf der Breite und dem Seitenverhältnis
            color: Colors
                .white, // Container gelb färben, um den Bereich sichtbar zu machen
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    showImageDialog(context, photoBlob, _currentPage);
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: photoBlob.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index; // Update current page
                      });
                    },
                    itemBuilder: (context, index) {
                      Uint8List bytes = getImage(imageCache, photoBlob[index]);

                      return FittedBox(
                        fit: BoxFit
                            .contain, // Bild wird vollständig angezeigt ohne Zuschnitt
                        alignment: Alignment
                            .topCenter, // Bild oben im Container ausrichten
                        child: Image.memory(
                          bytes,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons
                                  .broken_image), // Fallback für fehlerhafte Bilder
                        ),
                      );
                    },
                  ),
                ),
                // Linker Pfeil
                Positioned(
                  left: 10,
                  top: 50, // Positioniert den Pfeil mittig
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (_pageController.hasClients &&
                          (_pageController.page ?? 0) > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      }
                    },
                  ),
                ),
                // Rechter Pfeil
                Positioned(
                  right: 10,
                  top: 50, // Positioniert den Pfeil mittig
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    onPressed: () {
                      if (_pageController.hasClients &&
                          (_pageController.page ?? 0) < photoBlob.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      }
                    },
                  ),
                ),
                // Anzeige der Bildnummer in der rechten oberen Ecke
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_currentPage + 1} / ${photoBlob.length}', // Anzeige der aktuellen Bildnummer
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          )
        : Container(); // Wenn keine Bilder vorhanden sind, ein leerer Container
  }

// Methode zur Berechnung der Höhe basierend auf der Bildbreite
  double _imageHeight() {
    // Beispielhafte Berechnung der Höhe des Bildes basierend auf der Containerbreite
    double containerWidth = MediaQuery.of(context).size.width;
    double imageWidth = containerWidth;

    // Seitenverhältnis des Bildes annehmen, falls das Bild ein bestimmtes Seitenverhältnis hat
    // Zum Beispiel für ein Seitenverhältnis von 16:9
    double imageAspectRatio = 16 / 9;

    double imageHeight = imageWidth /
        imageAspectRatio; // Höhe basierend auf dem Seitenverhältnis berechnen
    return imageHeight;
  }

  // Methode für den Bereich Titel, Datum und Text
  Widget buildTextSection(Map arguments) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 10, right: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              arguments["date"] as String,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 10, right: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              arguments["title"] as String,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              arguments["body"] as String,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
            ),
          ),
        ),
      ],
    );
  }
}
