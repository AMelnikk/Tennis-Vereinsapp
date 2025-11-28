import 'dart:convert';
import 'package:intl/intl.dart';

class Termin {
  final int id;
  final DateTime date;
  final String von;
  final String bis;
  final String title;
  final String ort;
  final String category;
  final String description;
  final String query;
  final int lastUpdate;

  Termin({
    required this.id,
    required this.date,
    required this.von,
    required this.bis,
    required this.title,
    required this.ort,
    required this.category,
    required this.description,
    required this.query,
    int? lastUpdate,
  }) : lastUpdate = lastUpdate ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'von': von,
      'bis': bis,
      'title': title,
      'ort': ort,
      'category': category,
      'details': description,
      'query': query,
      'lastUpdate': lastUpdate,
    };
  }

  String toJson() => json.encode(toMap());

  factory Termin.fromMap(Map<String, dynamic> map) {
    return Termin(
      id: map['id'],
      date: DateFormat('yyyy-MM-dd').parse(map['date']),
      von: map['von'],
      bis: map['bis'],
      title: map['title'],
      ort: map['ort'],
      category: map['category'],
      description: map['details'],
      query: map['query'],
      lastUpdate: map['lastUpdate'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory Termin.fromJson(String source) => Termin.fromMap(json.decode(source));
}
