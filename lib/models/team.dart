import 'dart:typed_data';
import 'package:verein_app/utils/app_utils.dart';
// Importieren Sie 'decodePdfBlobs' und 'encodePdfBlobs' aus app_utils.dart
// oder definieren Sie sie in dieser Datei.

class Team {
  final String url;
  final String saison;
  final String mannschaft;
  final String liga;
  final String gruppe;
  final String mfName;
  final String mfTel;
  final String mfUID;
  final String matchbilanz;
  final String satzbilanz;
  final String position;
  final String kommentar;
  final List<Uint8List>? pdfBlob;
  List<String> photoBlob;

  Team({
    required this.url,
    required this.saison,
    required this.mannschaft,
    required this.liga,
    required this.gruppe,
    required this.mfName,
    required this.mfTel,
    required this.mfUID,
    required this.matchbilanz,
    required this.satzbilanz,
    required this.position,
    required this.kommentar,
    this.pdfBlob,
    this.photoBlob = const [],
  });

  factory Team.fromJson(Map<String, dynamic> json, String id) {
    // Robustes Parsen für photoBlob
    final List<Uint8List> decodedBlobs = decodePdfBlobs(json['pdfBlobs']);
    return Team(
        url: json['url'],
        saison: json['saison'],
        mannschaft: json['mannschaft'],
        liga: json['liga'],
        gruppe: json['gruppe'],
        mfName: json['mf_name'] ??
            '', // Falls nicht vorhanden, setze einen leeren String
        mfTel: json['mf_tel'] ??
            '', // Falls nicht vorhanden, setze einen leeren String
        mfUID: json['mf_uid'] ?? '',
        matchbilanz: json['matchbilanz'],
        satzbilanz: json['satzbilanz'],
        position: json['position'],
        kommentar: json['kommentar'],
        pdfBlob: decodedBlobs,
        photoBlob: parsePhotoBlob(json['photoBlob']));
  }

  Map<String, dynamic> toJson() {
    return {
      'saison': saison,
      'mannschaft': mannschaft,
      'liga': liga,
      'gruppe': gruppe,
      'mf_name': mfName,
      'mf_tel': mfTel,
      'mf_uid': mfUID,
      'matchbilanz': matchbilanz,
      'satzbilanz': satzbilanz,
      'position': position,
      'url': url,
      'kommentar': kommentar,

      // ✅ KORREKTUR: Null-Prüfung hinzufügen (pdfBlob ?? [])
      // Wenn pdfBlob null ist, wird eine leere Liste übergeben und kodiert.
      'pdfBlobs': encodePdfBlobs(pdfBlob ?? []),

      "photoBlob": photoBlob,
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
      mfUID: '',
      matchbilanz: '',
      satzbilanz: '',
      position: '',
      kommentar: '',
      pdfBlob: [],
      photoBlob: [],
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
      mfUID: '',
      matchbilanz: '',
      satzbilanz: '',
      position: '',
      kommentar: '',
      pdfBlob: [],
      photoBlob: [],
    );
  }
}
