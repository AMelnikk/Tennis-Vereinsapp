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
  bool isDebug = false;

  UserProvider(this._token);

  Future<bool> _isRole(BuildContext context, List<String> roles) async {
    final authProvider =
        Provider.of<AuthorizationProvider>(context, listen: false);

    setToken(authProvider.writeToken.toString());
    await getOwnUserData(authProvider.userId.toString());

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
  Future<void> getOwnUserData(String uid) async {
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

  // Methode zum Abrufen der Benutzerdaten und Privilegien
  Future<User> getUserDataWithUid(String uid) async {
    if (uid.isEmpty) return User.empty(); // Check if UID is empty
    // Falls die Liste noch nicht geladen wurde, erst laden
    if (allUsers.isEmpty) {
      await getAllUsers();
    }

    final urlUser = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/Users/$uid.json?auth=$_token");

    User tmpUser = User.empty(); // Temporäres User-Objekt
    try {
      // Benutzerdaten und Berechtigungen abrufen
      var userResponse = await http.get(urlUser);

      // Initialize userData and privilegeData as Map<String, dynamic>
      Map<String, dynamic>? userData;

      if (userResponse.statusCode == 200) {
        userData = json.decode(userResponse.body) as Map<String, dynamic>?;
      }

      if (userData != null) {
        tmpUser = User.fromJson(userData, uid); // User erstellen
      }
      tmpUser.uid = uid;
    } catch (error) {
      if (kDebugMode) print("Error: $error");
    }
    return tmpUser;
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

  Future<Map<String, String>> getAllMFandAdminUserNames() async {
    // 1. Laden ALLER (erlaubten) Benutzer aus der Realtime DB über getAllUsers
    // (allUsers enthält nun entweder alle Benutzer (als Admin) oder nur den eigenen (als Nicht-Admin)).
    if (allUsers.isEmpty) {
      await getAllUsers();
    }

    // Wir arbeiten mit der gefilterten Liste, um nur MFs und Admins zu berücksichtigen.
    final List<User> usersToSelect = allUsers.where((user) {
      final role = user.role.toLowerCase();
      // ✅ NEU: Filtern der lokal geladenen Liste
      return role == 'admin' || role == 'mannschaftsführer';
    }).toList();

    // 2. Sortieren nach Vorname, dann Nachname
    usersToSelect.sort((a, b) {
      // Sortieren nach Vorname
      final nameA = '${a.vorname.trim()} ${a.vorname.trim()}'.toLowerCase();
      final nameB = '${b.nachname.trim()} ${b.vorname.trim()}'.toLowerCase();
      return nameA.compareTo(nameB);
    });

    // 3. Map erstellen (Format: Vorname Nachname)
    Map<String, String> nameMap = {
      for (var user in usersToSelect)
        user.uid: '${user.vorname.trim()} ${user.nachname.trim()}',
    };

    return nameMap;
  }

  Future<Map<String, String>> getAllUserNames() async {
    // Falls die Liste noch nicht geladen wurde, erst laden
    if (allUsers.isEmpty) {
      await getAllUsers();
    }

    // Nach Nachname, dann Vorname sortieren
    allUsers.sort((a, b) {
      final nameA = '${a.nachname.trim()} ${a.vorname.trim()}'.toLowerCase();
      final nameB = '${b.nachname.trim()} ${b.vorname.trim()}'.toLowerCase();
      return nameA.compareTo(nameB);
    });

    // Danach Map erstellen
    Map<String, String> nameMap = {
      for (var user in allUsers)
        user.uid: '${user.nachname.trim()} ${user.vorname.trim()}',
    };

    return nameMap;
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
