import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_utils.dart';
import '../models/user.dart';

class UserProvider with ChangeNotifier {
  String? _token;
  User user = User.empty(); // User-Objekt anstelle von einzelnen Variablen

  List<User> allUsers = []; // Liste aller Benutzer
  List<User> filteredUsers = []; // Gefilterte Liste von Benutzern

  UserProvider(this._token);

  Future<bool> _isRole(BuildContext context, List<String> roles) async {
    final authProvider =
        Provider.of<AuthorizationProvider>(context, listen: false);

    setToken(authProvider.writeToken.toString());
    await getUserData(authProvider.userId.toString());

    return roles.contains(user.role);
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

  Future<String?> fetchOwnEmail() async {
    final url = Uri.parse(
        "https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=AIzaSyBO9pr1xgA7hwIoEti0Hf2pM_mvp2QlHG0");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode({"idToken": _token}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String email = data["users"]?[0]?["email"];
      user.email = email;
      return email;
    } else {
      return null;
    }
  }

  // Methode zum Abrufen der Benutzerdaten und Privilegien
  Future<User?> getUserData(String uid) async {
    if (uid.isEmpty) return null; // Check if UID is empty
    User user1 = User.empty();

    final urlUser = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/Users/$uid.json?auth=$_token");

    try {
      // Benutzerdaten und Berechtigungen abrufen
      var userResponse = await http.get(urlUser);

      // Initialize userData and privilegeData as Map<String, dynamic>
      Map<String, dynamic>? userData;

      if (userResponse.statusCode == 200) {
        userData =
            await json.decode(userResponse.body) as Map<String, dynamic>?;
      }

      if (userData != null) {
        user1 = User.fromJson(userData, uid); // User erstellen
      }
      user1.uid = uid;
      return user1;
    } catch (error) {
      if (kDebugMode) print("Error: $error");
      return null;
    }
  }

  // Methode zum Hinzufügen eines Benutzers (posten)
  Future<void> postUser(BuildContext context, User postUser, String tok) async {
    final messenger = ScaffoldMessenger.of(context);
    // Null-Prüfung für uid und Token
    if (postUser.uid.isEmpty || tok.isEmpty) {
      if (kDebugMode) print("❌ Fehler: UID oder Token fehlt.");
    }

    final urlUser = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/Users/${postUser.uid}.json?auth=$tok");

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
                  filteredUsers = List.from(allUsersTemp); // Direkt setzen!
                }
              } else {
                throw Exception(
                    'Failed to load all users. Status: ${allUsersResponse.statusCode}');
              }
            } catch (error) {
              //print("❌ Fehler beim Abrufen aller Benutzer: $error");
            }
          } else {
            // Falls kein Admin, nur eigene Daten laden
            allUsers = [User.fromJson(userData, user.uid)];
            filteredUsers = allUsers;
          }
        }
      } else {
        throw Exception(
            'Failed to load user. Status: ${userResponse.statusCode}');
      }
    } catch (error) {
      //print("❌ Fehler beim Abrufen der Benutzerdaten: $error");
    }

    notifyListeners(); // Immer aufrufen!
  }

  void getFilteredUsers(String role, String name) {
    filteredUsers = allUsers.where((user) {
      final nameLower = name.toLowerCase();
      final roleMatch = role.isEmpty || role == "Alle" || user.role == role;
      final nameMatch = name.isEmpty ||
          user.vorname.toLowerCase().contains(nameLower) ||
          user.nachname.toLowerCase().contains(nameLower);

      return roleMatch && nameMatch;
    }).toList();

    notifyListeners(); // wichtig zum UI-Update
  }
}
