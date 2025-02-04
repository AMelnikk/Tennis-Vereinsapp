import 'package:intl/intl.dart';

class TennisMatch {
  final String id;
  final DateTime datum;
  final String uhrzeit;
  final String altersklasse;
  final String spielklasse;
  final String gruppe;
  final String heim;
  final String gast;
  final String spielort;
  final String ergebnis;
  final String saison;

  TennisMatch({
    required this.id,
    required this.datum,
    required this.uhrzeit,
    required this.altersklasse,
    required this.spielklasse,
    required this.gruppe,
    required this.heim,
    required this.gast,
    required this.spielort,
    required this.ergebnis,
    required this.saison,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'datum': DateFormat('dd.MM.yyyy').format(datum),
      'uhrzeit': uhrzeit,
      'altersklasse': altersklasse,
      'spielklasse': spielklasse,
      'gruppe': gruppe,
      'heim': heim,
      'gast': gast,
      'spielort': spielort,
      'ergebnis': ergebnis,
      'saison': saison,
    };
  }
}
