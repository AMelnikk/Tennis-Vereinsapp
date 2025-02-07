import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:verein_app/providers/auth_provider.dart';
import 'package:verein_app/utils/app_utils.dart';
import '../models/user.dart';

class UserProvider with ChangeNotifier {
  String? _token;
  User user = User.empty(); // User-Objekt anstelle von einzelnen Variablen

  List<User> allUsers = []; // Liste aller Benutzer
  List<User> filteredUsers = []; // Gefilterte Liste von Benutzern

  UserProvider(this._token);

  Future<bool> _isRole(BuildContext context, List<String> roles) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    userProvider.setToken(authProvider.writeToken.toString());
    await userProvider.getUserData(authProvider.userId.toString());

    return roles.contains(userProvider.user.role);
  }

  Future<bool> isAdminOrMannschaftsfuehrer(BuildContext context) async {
    return await _isRole(context, ['Admin', 'Mannschaftsführer']);
  }

  Future<bool> isAdmin(BuildContext context) async {
    return await _isRole(context, ['Admin']);
  }

  void setToken(String wToken) {
    _token = wToken;
  }

  // Methode zum Abrufen der Benutzerdaten und Privilegien
  Future<void> getUserData(String uid) async {
    if (uid.isEmpty) return; // Check if UID is empty

    final urlUser = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/Users/$uid.json?auth=$_token");

    try {
      // Benutzerdaten und Berechtigungen abrufen
      var userResponse = await http.get(urlUser);

      // Initialize userData and privilegeData as Map<String, dynamic>
      Map<String, dynamic>? userData;

      if (userResponse.statusCode == 200) {
        userData = json.decode(userResponse.body) as Map<String, dynamic>?;
      }

      if (userData != null) {
        user = User.fromJson(userData, uid); // User erstellen
      }
      user.uid = uid;
      notifyListeners(); // Notify listeners, wenn die Daten geändert wurden
    } catch (error) {
      if (kDebugMode) print("Error: $error");
    }
  }

  // Methode zum Hinzufügen eines Benutzers (posten)
  Future<void> postUser(
      BuildContext context, User postUser, String _tok) async {
    final messenger = ScaffoldMessenger.of(context);
    // Null-Prüfung für uid und Token
    if (postUser.uid.isEmpty || _tok == null || _tok!.isEmpty) {
      if (kDebugMode) print("❌ Fehler: UID oder Token fehlt.");
    }

    final urlUser = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/Users/${postUser.uid}.json?auth=$_tok");

    try {
      // HTTP Request ausführen
      final response = await http.put(
        urlUser,
        headers: {"Content-Type": "application/json"},
        body: json
            .encode(postUser.toJson()), // Assuming toJson method returns a map
      );

      // Prüfen, ob der Request erfolgreich war
      if (response.statusCode == 200) {
        appError(messenger, "Speichern erfolgreich!");
      } else {
        appError(messenger, "Leider Fehler beim Speichern!");
        if (kDebugMode) {
          print(
              "❌ User Response: ${response.statusCode}, Body: ${response.body}");
        }
      }
    } catch (error) {
      appError(messenger, "Leider Fehler beim Speichern!");
      if (kDebugMode) print("❌ Netzwerk-Fehler: $error");
    }
  }

  Future<void> deleteUser(BuildContext context, String uid) async {
    final messenger = ScaffoldMessenger.of(context);

    // Null-Prüfung für uid und Token
    if (uid.isEmpty || _token == null || _token!.isEmpty) {
      if (kDebugMode) print("❌ Fehler: UID oder Token fehlt.");
    }

    final urlUser = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/Users/$uid.json?auth=$_token");

    try {
      // HTTP DELETE-Request ausführen
      final response = await http.delete(urlUser);

      // Prüfen, ob der Request erfolgreich war
      if (response.statusCode == 200) {
        appError(messenger, "Löschen erfolgreich!");
      } else {
        appError(messenger, "Leider Fehler beim Löschen!");
        if (kDebugMode) {
          print(
              "❌ User Delete Response: ${response.statusCode}, Body: ${response.body}");
        }
      }
    } catch (error) {
      appError(messenger, "Leider Fehler beim Löschen!");
      if (kDebugMode) print("❌ Netzwerk-Fehler: $error");
    }
  }

  Future<void> getAllUsers() async {
    //if (allUsers.isNotEmpty) {
    //  return; // Falls schon geladen, nicht erneut abrufen
    // }

    final urlUser = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/Users/${user.uid}.json?auth=$_token");

    try {
      var userResponse = await http.get(urlUser);

      if (userResponse.statusCode == 200) {
        var userData = json.decode(userResponse.body) as Map<String, dynamic>?;

        if (userData != null) {
          // Falls der User Admin ist, alle User abrufen
          if (userData['role'] == 'Admin') {
            final allUsersUrl = Uri.parse(
                "https://db-teg-default-rtdb.firebaseio.com/Users.json?auth=$_token");

            try {
              var allUsersResponse = await http.get(allUsersUrl);

              if (allUsersResponse.statusCode == 200) {
                var allUsersData =
                    json.decode(allUsersResponse.body) as Map<String, dynamic>?;

                if (allUsersData != null) {
                  List<User> allUsersTemp = [];
                  allUsersData.forEach((uid, data) {
                    allUsersTemp.add(User.fromJson(data, uid));
                  });

                  allUsers = allUsersTemp;
                  notifyListeners();
                }
              } else {
                throw Exception(
                    'Failed to load all users. Status: ${allUsersResponse.statusCode}');
              }
            } catch (error) {
              print("❌ Fehler beim Abrufen aller Benutzer: $error");
            }
          } else {
            // Falls kein Admin, nur eigene Daten laden
            allUsers = [User.fromJson(userData, user.uid)];
            filteredUsers = allUsers;
            notifyListeners();
          }
        }
      } else {
        throw Exception(
            'Failed to load user. Status: ${userResponse.statusCode}');
      }
    } catch (error) {
      print("❌ Fehler beim Abrufen der Benutzerdaten: $error");
    }
  }

  // Filter-Methode für Benutzer mit Berechtigung, Vorname und Nachname
  void getFilteredUsers(String role, String vorname, String nachname) {
    final neueListe = allUsers.where((user) {
      bool matchesRole = true;
      bool matchesVorname = true;
      bool matchesNachname = true;

      if (role.isNotEmpty && role != 'Alle') {
        matchesRole = user.role == role;
      }

      if (vorname.isNotEmpty) {
        matchesVorname =
            user.vorname.toLowerCase().contains(vorname.toLowerCase());
      }

      if (nachname.isNotEmpty) {
        matchesNachname =
            user.nachname.toLowerCase().contains(nachname.toLowerCase());
      }

      return matchesRole && matchesVorname && matchesNachname;
    }).toList();

    if (!listEquals(filteredUsers, neueListe)) {
      filteredUsers = neueListe;
      notifyListeners();
    }
  }
}
