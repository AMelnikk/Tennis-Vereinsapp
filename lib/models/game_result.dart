import 'dart:convert';
import 'dart:typed_data';

class GameResult {
  final String id;
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

  GameResult({
    required this.id,
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

  factory GameResult.fromJson(Map<String, dynamic> json, String id) {
    return GameResult(
      id: id,
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
}
