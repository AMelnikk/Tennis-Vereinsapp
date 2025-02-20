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
