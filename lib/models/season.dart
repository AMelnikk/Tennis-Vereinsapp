class SaisonData {
  final String key;
  final String saison;
  final int jahr;
  final int jahr2;

  // Konstruktor, der alle Felder erwartet
  SaisonData({
    required this.key, // Hier wird 'key' initialisiert
    required this.saison, // Hier wird 'saison' initialisiert
    required this.jahr, // Hier wird 'jahr' initialisiert
    required this.jahr2, // Hier wird 'jahr2' initialisiert
  });

  factory SaisonData.empty() {
    return SaisonData(
      key: '',
      saison: '',
      jahr: -1,
      jahr2: -1,
    );
  }

  // Factory-Methode, um ein Objekt aus JSON zu erstellen
  factory SaisonData.fromJson(Map<String, dynamic> json) {
    return SaisonData(
      key: json['key'] ??
          '', // Falls der 'key' im JSON fehlt, wird ein leerer String verwendet
      saison: json['saison'] ??
          '', // Falls 'saison' fehlt, wird ein leerer String verwendet
      jahr: int.tryParse(json['jahr'].toString()) ??
          -1, // 'jahr' wird als Zahl erwartet
      jahr2: int.tryParse(json['jahr2'].toString()) ??
          -1, // 'jahr2' wird als Zahl erwartet
    );
  }

  // Methode zum Konvertieren in JSON
  Map<String, dynamic> toJson() {
    return {
      'key': key, // 'key' wird ins JSON übertragen
      'saison': saison, // 'saison' wird ins JSON übertragen
      'jahr': jahr, // 'jahr' wird ins JSON übertragen
      'jahr2': jahr2, // 'jahr2' wird ins JSON übertragen
    };
  }
}
