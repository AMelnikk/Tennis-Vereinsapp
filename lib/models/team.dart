import 'dart:convert';
import 'dart:typed_data';

class Team {
  final String url;
  final String saison;
  final String mannschaft;
  final String liga;
  final String gruppe;
  final String matchbilanz;
  final String satzbilanz;
  final String position;
  final String kommentar;
  final Uint8List? pdfBlob;

  Team({
    required this.url,
    required this.saison,
    required this.mannschaft,
    required this.liga,
    required this.gruppe,
    required this.matchbilanz,
    required this.satzbilanz,
    required this.position,
    required this.kommentar,
    this.pdfBlob,
  });

  factory Team.fromJson(Map<String, dynamic> json, String id) {
    return Team(
      url: json['url'],
      saison: json['saison'],
      mannschaft: json['mannschaft'],
      liga: json['liga'],
      gruppe: json['gruppe'],
      matchbilanz: json['matchbilanz'],
      satzbilanz: json['satzbilanz'],
      position: json['position'],
      kommentar: json['kommentar'],
      pdfBlob: json['pdfBlob'] != null ? base64Decode(json['pdfBlob']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'saison': saison,
      'mannschaft': mannschaft,
      'liga': liga,
      'gruppe': gruppe,
      'matchbilanz': matchbilanz,
      'satzbilanz': satzbilanz,
      'position': position,
      'kommentar': kommentar,
      'pdfBlob': pdfBlob != null ? base64Encode(pdfBlob!) : null,
    };
  }

  factory Team.empty() {
    return Team(
      url: '',
      saison: '',
      mannschaft: '',
      liga: '',
      gruppe: '',
      matchbilanz: '',
      satzbilanz: '',
      position: '',
      kommentar: '',
      pdfBlob: null,
    );
  }

  factory Team.newteam(
      String saisonkey, String mannschaft, String liga, String gruppe) {
    return Team(
      url: '',
      saison: saisonkey,
      mannschaft: mannschaft,
      liga: liga,
      gruppe: gruppe,
      matchbilanz: '',
      satzbilanz: '',
      position: '',
      kommentar: '',
      pdfBlob: null,
    );
  }
}
