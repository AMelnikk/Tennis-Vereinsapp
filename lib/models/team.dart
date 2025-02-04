import 'dart:convert';
import 'dart:typed_data';

class Team {
  final String url;
  final String saison;
  final String mannschaft;
  final String liga;
  final String gruppe;
  final String mfName;
  final String mfTel;
  final String matchbilanz;
  final String satzbilanz;
  final String position;
  final String kommentar;
  final Uint8List? pdfBlob;
  final Uint8List? photoBlob;

  Team({
    required this.url,
    required this.saison,
    required this.mannschaft,
    required this.liga,
    required this.gruppe,
    required this.mfName,
    required this.mfTel,
    required this.matchbilanz,
    required this.satzbilanz,
    required this.position,
    required this.kommentar,
    this.pdfBlob,
    this.photoBlob,
  });

  factory Team.fromJson(Map<String, dynamic> json, String id) {
    return Team(
      url: json['url'],
      saison: json['saison'],
      mannschaft: json['mannschaft'],
      liga: json['liga'],
      gruppe: json['gruppe'],
      mfName: json['mf_name'] ??
          '', // Wenn mf_name nicht vorhanden, setze einen leeren String
      mfTel: json['mf_tel'] ??
          '', // Wenn mf_tel nicht vorhanden, setze einen leeren String
      matchbilanz: json['matchbilanz'],
      satzbilanz: json['satzbilanz'],
      position: json['position'],
      kommentar: json['kommentar'],
      pdfBlob: json['pdfBlob'] != null ? base64Decode(json['pdfBlob']) : null,
      photoBlob:
          json['photoBlob'] != null ? base64Decode(json['photoBlob']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'saison': saison,
      'mannschaft': mannschaft,
      'liga': liga,
      'gruppe': gruppe,
      'mf_name': mfName,
      'mf_tel': mfTel,
      'matchbilanz': matchbilanz,
      'satzbilanz': satzbilanz,
      'position': position,
      'kommentar': kommentar,
      'pdfBlob': pdfBlob != null ? base64Encode(pdfBlob!) : null,
      'photoBlob': photoBlob != null ? base64Encode(photoBlob!) : null,
    };
  }

  factory Team.empty() {
    return Team(
      url: '',
      saison: '',
      mannschaft: '',
      liga: '',
      gruppe: '',
      mfName: '',
      mfTel: '',
      matchbilanz: '',
      satzbilanz: '',
      position: '',
      kommentar: '',
      pdfBlob: null,
      photoBlob: null,
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
      mfName: '',
      mfTel: '',
      matchbilanz: '',
      satzbilanz: '',
      position: '',
      kommentar: '',
      pdfBlob: null,
      photoBlob: null,
    );
  }
}
