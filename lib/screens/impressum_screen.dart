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
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
                textAlign: TextAlign.left,
              ),
              Space(),
              Text(
                "TSV Weidenbach-Triesdorf e. V.",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text("Am Sportplatz \n91746 Weidenbach"),
              Space(),
              Text(
                "Vertreten durch:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Text(
                "Vertretungsberechtigter Vorstand: Oliver Ströbel \nMobil: +4915254690802 \nE-Mail: tennis-weidenbach@t-online.de",
              ),
              Space(),
              Text(
                "Verantwortlich gemäß § 55 Abs. 2 RStV:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Text(
                "Oliver Ströbel (Vertretungsberechtigter Vorstand)",
              ),
              Space(),
              Text(
                "Haftungsausschluss",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
              ),
              Text(
                "Haftungsbeschränkung",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              Text(
                "Die Inhalte dieser App werden mit größtmöglicher Sorgfalt erstellt. Der Anbieter übernimmt jedoch keine Gewähr für die Richtigkeit, Vollständigkeit und Aktualität der bereitgestellten Inhalte. Die Nutzung der Inhalte der App erfolgt auf eigene Gefahr des Nutzers. Namentlich gekennzeichnete Beiträge geben die Meinung des jeweiligen Autors und nicht immer die Meinung des Anbieters wieder. Mit der reinen Nutzung der Webseite des Anbieters kommt keinerlei Vertragsverhältnis zwischen dem Nutzer und dem Anbieter zustande.",
              ),
              Space(),
              Text(
                "Externe Links",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              Text(
                'Diese App enthält Verknüpfungen zu Webseiten Dritter („externe Links“), auf deren Inhalte der Anbieter keinen Einfluss hat. Diese Webseiten unterliegen der Haftung der jeweiligen Betreiber. Zum Zeitpunkt der Verlinkung wurden die externen Seiten auf mögliche Rechtsverstöße überprüft; es waren keine rechtswidrigen Inhalte erkennbar. Der Anbieter hat jedoch keine Kontrolle über die aktuelle und zukünftige Gestaltung der Inhalte der verknüpften Seiten. Das Setzen externer Links bedeutet nicht, dass sich der Anbieter die Inhalte dieser Seiten zu eigen macht. Bei Kenntnis von Rechtsverstößen werden derartige Links unverzüglich entfernt.',
              ),
              Space(),
              Text(
                "Urheber- und Leistungsschutzrechte",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
              ),
              Text(
                'Alle auf dieser App veröffentlichten Inhalte unterliegen dem deutschen Urheber- und Leistungsschutzrecht. Jede Verwertung, die nicht ausdrücklich durch das deutsche Urheberrecht gestattet ist, bedarf der vorherigen schriftlichen Zustimmung des Anbieters oder des jeweiligen Rechteinhabers. Dies umfasst insbesondere die Vervielfältigung, Bearbeitung, Übersetzung, Einspeicherung und Verarbeitung in elektronische Medien oder Systeme. Inhalte Dritter sind dabei entsprechend gekennzeichnet. Die unerlaubte Vervielfältigung oder Weitergabe einzelner Inhalte oder kompletter Seiten ist nicht gestattet und strafbar. Kopien und Downloads dürfen ausschließlich für den persönlichen, privaten und nicht kommerziellen Gebrauch angefertigt werden.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Space extends SizedBox {
  const Space({super.key});

  @override
  double? get height => 15;
}
