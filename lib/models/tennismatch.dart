class TennisMatch {
  final String id;
  final String datum;
  final String uhrzeit;
  final String altersklasse;
  final String spielklasse;
  final String gruppe;
  final String heim;
  final String gast;
  final String spielort;
  final String ergebnis;
  final String mf_name;
  final String mf_tel;
  final String photo;
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
    required this.mf_name,
    required this.mf_tel,
    required this.photo,
    required this.saison,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'datum': datum,
      'uhrzeit': uhrzeit,
      'altersklasse': altersklasse,
      'spielklasse': spielklasse,
      'gruppe': gruppe,
      'heim': heim,
      'gast': gast,
      'spielort': spielort,
      'ergebnis': ergebnis,
      'mf_name': mf_name,
      'mf_tel': mf_tel,
      'photo': photo,
      'saison': saison,
    };
  }
}
