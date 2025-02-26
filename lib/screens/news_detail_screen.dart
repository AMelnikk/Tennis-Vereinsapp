import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/models/news.dart';
import '../popUps/show_images_dialog.dart';
import '../providers/user_provider.dart';
import '../screens/add_news_screen.dart';
import '../utils/image_helper.dart';
import '../providers/news_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/verein_appbar.dart';

class NewsDetailScreen extends StatefulWidget {
  static const routename = '/news-detail';

  const NewsDetailScreen({super.key});

  @override
  NewsDetailScreenState createState() => NewsDetailScreenState();
}

class NewsDetailScreenState extends State<NewsDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0; // Track the current page
  List<String> photoBlob = [];

  bool? _isAdmin;

  @override
  void initState() {
    super.initState();

    // Den Admin-Status einmalig beim Initialisieren laden
    _loadAdminStatus();
  }

  // Admin-Status einmalig laden
  Future<void> _loadAdminStatus() async {
    bool isAdmin = await Provider.of<UserProvider>(context, listen: false)
        .isAdmin(context);
    setState(() {
      _isAdmin = isAdmin;
    });
  }

  @override
  Widget build(BuildContext context) {
    NewsProvider newsProvider = Provider.of<NewsProvider>(context, listen: false);
    final imageCache =newsProvider.imageCache;

    final String currentUser =
        Provider.of<AuthorizationProvider>(context, listen: false)
            .userId
            .toString();
    newsProvider.author = currentUser;

    return Scaffold(
      appBar: VereinAppbar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10), // Seitlicher Rand
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[300], // Grauer Rand
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Column(
            children: [
              // Bereich für die Anzeige der Bilder
              buildImageSection(photoBlob, imageCache),

              // Bereich für den Text (nimmt den verbleibenden Platz nach dem Bild ein)
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    color: Colors.white, // Weißer Container für den Inhalt
                    child: Column(
                      children: [
                        // Bereich für den Titel, Datum und Text
                        buildTextSection(newsProvider),

                        // Wenn der Admin-Status bereits geladen wurde
                        if (_isAdmin != null) ...[
                          if (_isAdmin == true ||
                              currentUser == newsProvider.author) ...[
                            // Row für Edit und Delete Buttons nebeneinander
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Edit-Button nur für Admins oder den Autor der Nachricht
                                IconButton(
                                  onPressed: () async {
                                    // Navigiere zum AddNewsScreen und übergebe die News ID zur Bearbeitung
                                    final newsId = await Navigator.push<String>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AddNewsScreen(),
                                      ),
                                    );

                                    // Falls eine neue News ID zurückgegeben wird, setze diese
                                    if (newsId != null && newsId.isNotEmpty) {
                                      setState(() {
                                        // Hier kannst du den Status aktualisieren
                                        newsProvider.newsId = newsId;
                                      });
                                    }
                                    newsProvider.clearNews();
                                  },
                                  icon: const Icon(Icons.edit_rounded),
                                ),
                                // Delete-Button nur für Admins
                                if (_isAdmin == true)
                                  IconButton(
                                    onPressed: () {
                                      Provider.of<NewsProvider>(context,
                                              listen: false)
                                          .deleteNews(newsProvider.newsId);
                                      Navigator.of(context).pop();
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Color.fromARGB(255, 104, 23, 18),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
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
  Widget buildTextSection(NewsProvider newsProvider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 10, right: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              newsProvider.newsDate,
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
              newsProvider.title.text,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              newsProvider.body.text as String,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
            ),
          ),
        ),
      ],
    );
  }
}
