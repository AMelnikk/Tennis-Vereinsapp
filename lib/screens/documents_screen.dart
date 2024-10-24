import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:verein_app/widgets/document_tile.dart';
import 'package:verein_app/widgets/verein_appbar.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});
  static const routename = "documents-screen/";

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  Future<void> _loadUrlPdf(String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw "Something went wrong";
    }
  }

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
                _loadUrlPdf(
                    "https://www.tsv-weidenbach.de/wp-content/uploads/2023/10/TSV_Beitritt_2023.pdf");
              },
            ),
            const SizedBox(height: 10),
            DocumentTile(
              text: "Beitrittserklärung Abteilung Tennis",
              imagePath: "assets/images/Beitritterklärung_Abteilung_Tennis.png",
              function: () {
                _loadUrlPdf(
                    "https://www.tsv-weidenbach.de/wp-content/uploads/2020/02/TSV-Beitritt_Tennis_2020_V1.pdf");
              },
            ),
            const SizedBox(height: 10),
            DocumentTile(
              text: "Vereinssatzung",
              imagePath: "assets/images/Vereinssatzung.png",
              function: () {
                _loadUrlPdf(
                    "https://www.tsv-weidenbach.de/wp-content/uploads/2020/01/TSV-Satzung_HV_2019.pdf");
              },
            ),
            const SizedBox(height: 10),
            DocumentTile(
              text: "Beitragsordnung",
              imagePath: "assets/images/Beitragsordnung.png",
              function: () {
                _loadUrlPdf(
                    "https://www.tsv-weidenbach.de/wp-content/uploads/2023/09/TSV-Weidenbach_Beitragsordnung_2023.pdf");
              },
            ),
          ],
        ),
      ),
    );
  }
}
