import 'package:flutter/material.dart';
import '../widgets/verein_appbar.dart';

class ImpressumScreen extends StatelessWidget {
  const ImpressumScreen({super.key});

  static const routename = "/impressum-screen";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VereinAppbar(),
      body: const Padding(
        padding: EdgeInsets.all(15),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Impressum",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
                textAlign: TextAlign.left,
              ),
              SizedBox(
                height: 15,
              ),
              Text(
                  "TSV Weidenbach-Triesdorf e. V. \nAm Sportplatz \n91746 Weidenbach"),
              SizedBox(
                height: 18,
              ),
              Text(
                "Vertreten durch:",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                  "Vertretungsberechtigter Vorstand Christian Höger \nEmail: vorstand@tsv-weidenbach.de"),
                  SizedBox(
                height: 18,
              ),
              Text(
                "Haftungsausschlus / Haftungsbeschränkung",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              Text(
                "Die Inhalte dieser App werden mit größtmöglicher Sorgfalt erstellt. Der Anbieter übernimmt jedoch keine Gewähr für die Richtigkeit, Vollständigkeit und Aktualität der bereitgestellten Inhalte. Die Nutzung der Inhalte der App erfolgt auf eigene Gefahr des Nutzers. Namentlich gekennzeichnete Beiträge geben die Meinung des jeweiligen Autors und nicht immer die Meinung des Anbieters wieder. Mit der reinen Nutzung der Webseite des Anbieters kommt keinerlei Vertragsverhältnis zwischen dem Nutzer und dem Anbieter zustande.",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
