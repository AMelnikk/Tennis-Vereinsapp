import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';

class TennisMatch {
  final String id;
  DateTime datum;
  String uhrzeit;
  String altersklasse;
  final String spielklasse;
  final String gruppe;
  final String heim;
  final String gast;
  final String spielort;
  String ergebnis;
  final String saison;
  String spielbericht;
  final Uint8List? photoBlobSB;

  TennisMatch(
      {required this.id,
      required this.datum,
      required this.uhrzeit,
      required this.altersklasse,
      required this.spielklasse,
      required this.gruppe,
      required this.heim,
      required this.gast,
      required this.spielort,
      required this.saison,
      required this.ergebnis,
      required this.spielbericht,
      required this.photoBlobSB});

  Map<String, dynamic> toJson(
      {bool includeErgebnis = false,
      bool includeSpielbericht = false,
      bool includePhotoBlob = false}) {
    final jsonMap = {
      'id': id,
      'datum': DateFormat('dd.MM.yyyy').format(datum),
      'uhrzeit': uhrzeit,
      'altersklasse': altersklasse,
      'spielklasse': spielklasse,
      'gruppe': gruppe,
      'heim': heim,
      'gast': gast,
      'spielort': spielort,
      'saison': saison,
    };

    // Wenn die Felder nicht ausgeschlossen sind, füge sie zum JSON hinzu
    if (includeErgebnis) {
      jsonMap['ergebnis'] = ergebnis;
    }
    if (includeSpielbericht) {
      jsonMap['spielbericht'] = spielbericht;
    }
    if (includePhotoBlob) {
      jsonMap['photoBlobSB'] =
          photoBlobSB != null ? base64Encode(photoBlobSB!) : '';
    }

    return jsonMap;
  }

  factory TennisMatch.empty() {
    return TennisMatch(
      id: '',
      datum:
          DateTime.now(), // Datum als DateTime, nicht als formatierter String
      uhrzeit: '',
      altersklasse: '',
      spielklasse: '',
      gruppe: '',
      heim: '',
      gast: '',
      spielort: '',
      ergebnis: '',
      saison: '',
      spielbericht: '',
      photoBlobSB: null, // Kein Bild vorhanden, daher null
    );
  }
}
