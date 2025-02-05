import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserProvider with ChangeNotifier {
  UserProvider(this._token);

  final String? _token;
  var uid = TextEditingController();
  var platzbuchungLink = TextEditingController();
  var name = TextEditingController();

  Future<int> postUser() async {
    final url = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/Users/${uid.text}.json?auth=$_token");
    try {
      var response = await http.put(
        url,
        body: json.encode(
          {
            "platzbuchung_link": platzbuchungLink.text,
            "name": name.text,
            "Berechtigung": "Mitglied",
          },
        ),
      );
      if (kDebugMode) print(response.statusCode);
      return response.statusCode;
    } catch (error) {
      if (kDebugMode) print(error);
      return 400;
    }
  }

  // Methode zum Abrufen der Benutzerdaten
  Future<void> getUserData(String uid) async {
    final url = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/Users/$uid.json?");
    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        // Wenn die Anfrage erfolgreich ist, die Daten als Map zurückgeben
        var userData = json.decode(response.body) as Map<String, dynamic>?;
        if (userData != null) {
          // Variablen mit den abgerufenen Daten füllen
          platzbuchungLink.text = userData['platzbuchung_link'] ?? '';
          name.text = userData['name'] ?? '';
          uid = uid; // Sicherstellen, dass uid auch gefüllt wird
          notifyListeners(); // Notify listeners, wenn die Daten geändert wurden
        }
      } else {
        if (kDebugMode) print("Error: ${response.statusCode}");
      }
    } catch (error) {
      if (kDebugMode) print("Error: $error");
    }
  }
}
