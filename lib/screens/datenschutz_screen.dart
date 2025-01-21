import 'package:flutter/material.dart';
import '../widgets/verein_appbar.dart';

class DatenschutzScreen extends StatelessWidget {
  const DatenschutzScreen({super.key});

  static const routename = "/datenschutz-screen";

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
                "Datenschutzerklärung",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
                textAlign: TextAlign.left,
              ),
              Space(),
              Text(
                "Der Schutz Ihrer personenbezogenen Daten ist uns ein wichtiges Anliegen. Wir verarbeiten Ihre Daten ausschließlich im Rahmen der gesetzlichen Bestimmungen, insbesondere gemäß der Datenschutz-Grundverordnung (DSGVO).",
              ),
              Space(),
              Text(
                "1. Verantwortliche Stelle",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                "Verantwortlich für die Datenverarbeitung ist der TSV Weidenbach-Triesdorf e. V., vertreten durch Christian Höger (E-Mail: vorstand@tsv-weidenbach.de).",
              ),
              Text(
                "2. Datenverarbeitung",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                "• Wir verarbeiten personenbezogene Daten nur, wenn dies zur Bereitstellung unserer App oder zur Erfüllung gesetzlicher oder vertraglicher Verpflichtungen notwendig ist.",
              ),
              Text(
                "• Verarbeitete Daten können z. B. Kontakt- und Kommunikationsdaten sein, wenn Sie uns über E-Mail oder andere Kanäle kontaktieren.",
              ),
              Text(
                "3. Speicherung und Löschung von Daten",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                "Personenbezogene Daten werden nur so lange gespeichert, wie dies für die genannten Zwecke erforderlich ist oder gesetzliche Aufbewahrungsfristen bestehen.",
              ),
              Text(
                "4. Weitergabe von Daten",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                "Eine Weitergabe Ihrer Daten an Dritte erfolgt nur, wenn dies zur Erfüllung von Vertragszwecken erforderlich ist, Sie eingewilligt haben oder wir rechtlich dazu verpflichtet sind.",
              ),
              Text(
                "5. Rechte der Betroffenen",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                "Ihnen stehen folgende Rechte zu:\n• Auskunft über Ihre gespeicherten Daten (Art. 15 DSGVO)\n• Berichtigung unrichtiger Daten (Art. 16 DSGVO)\n• Löschung Ihrer Daten, soweit keine gesetzlichen Aufbewahrungsfristen bestehen (Art. 17 DSGVO)\n• Einschränkung der Verarbeitung (Art. 18 DSGVO)\n• Datenübertragbarkeit (Art. 20 DSGVO)\n • Widerspruch gegen die Verarbeitung Ihrer Daten (Art. 21 DSGVO)",
              ),
              Text(
                "6. Kontakt bei Datenschutzfragen",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                "Für Fragen zum Datenschutz oder zur Ausübung Ihrer Rechte wenden Sie sich bitte an: Christian Höger E-Mail: vorstand@tsv-weidenbach.de",
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
