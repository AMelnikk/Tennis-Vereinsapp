import 'package:flutter/material.dart';
import '../screens/pdf_screen.dart';
import '../widgets/document_tile.dart';
import '../widgets/verein_appbar.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});
  static const routename = "/documents-screen";

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VereinAppbar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            DocumentTile(
              text: "Beitrittserklärung Hauptverein",
              imagePath: "assets/images/Beitritterklärung_Hauptverein.png",
              function: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PdfScreen(
                      assetPath:
                          "assets/pdfs/Beitrittserklärung_Hauptverein.pdf",
                      name: "Beitrittserklärung Hauptverein",
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            DocumentTile(
              text: "Beitrittserklärung Abteilung Tennis",
              imagePath: "assets/images/Beitritterklärung_Abteilung_Tennis.png",
              function: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PdfScreen(
                      assetPath:
                          "assets/pdfs/Beitrittserklärung_Abteilung_Tennis.pdf",
                      name: "Beitritterklärung Abteilung Tennis",
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            DocumentTile(
              text: "Vereinssatzung",
              imagePath: "assets/images/Vereinssatzung.png",
              function: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PdfScreen(
                      assetPath: "assets/pdfs/Vereinssatzung.pdf",
                      name: "Vereinssatzung",
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            DocumentTile(
              text: "Beitragsordnung",
              imagePath: "assets/images/Beitragsordnung.png",
              function: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PdfScreen(
                      assetPath: "assets/pdfs/Beitragsordnung.pdf",
                      name: "Beitragsordnung",
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
