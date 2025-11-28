import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String uid;
  String platzbuchungLink;
  String vorname;
  String nachname;
  String role;
  String email;

  User({
    required this.uid,
    required this.platzbuchungLink,
    required this.vorname,
    required this.nachname,
    required this.email,
    required this.role,
  });

  // Factory constructor to create User from JSON data
  // Factory constructor to create a User from a Map
  factory User.fromJson(Map<String, dynamic> json, String id) {
    return User(
      uid: id, // This is where the ID is assigned
      platzbuchungLink: json['platzbuchung_link'] ?? '',
      vorname: json['vorname'] ?? '',
      nachname: json['nachname'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
    );
  }

  factory User.empty() {
    return User(
      uid: '',
      platzbuchungLink: '',
      vorname: '',
      nachname: '',
      email: '',
      role: '',
    );
  }
  factory User.fromFirestore(DocumentSnapshot doc) {
    // 1. Hole die Daten und werfe einen Fehler, falls das Dokument leer ist
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      // Oder behandeln Sie dies leiser, z.B. return User.empty();
      throw StateError('User data is null for UID: ${doc.id}');
    }

    // 2. Erstelle das User-Objekt, wobei die Dokument-ID als UID dient
    return User(
      uid: doc.id, // Die UID ist immer die Dokumenten-ID in Firestore
      platzbuchungLink: data['platzbuchung_link'] as String? ?? '',
      vorname: data['vorname'] as String? ?? '',
      nachname: data['nachname'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? '',
    );
  }

  // Method to convert User object to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'platzbuchung_link': platzbuchungLink,
      'vorname': vorname,
      'nachname': nachname,
      'role': role,
    };
  }
}
