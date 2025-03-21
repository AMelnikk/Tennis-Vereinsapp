import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import "package:http/http.dart" as http;
import 'package:verein_app/utils/app_utils.dart';
import '../models/http_exception.dart';

class AuthorizationProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthorizationProvider() {
    try {
      //  print("⚡ AuthProvider wird initialisiert...");
      //  print("Aktueller Nutzer: ${_auth.currentUser?.email}");
    } catch (e) {
      //  print("❌ Fehler in AuthProvider-Konstruktor: $e");
    }
  }
  late final Map<String, String?> credentials;
  final storage = const FlutterSecureStorage();
  String? _writeToken;
  DateTime? _expiryDate;
  String? _userId;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  String? get writeToken {
    if (_expiryDate != null &&
        _expiryDate!.isAfter(DateTime.now()) &&
        _writeToken != null) {
      return _writeToken;
    } else {
      return null;
    }
  }

  String? get userId {
    return _userId;
  }

  bool get isSignedIn {
    return _writeToken != null;
  }

  Future<void> signIn(BuildContext context, email, String password) async {
    final dbUrl = Uri.parse(
        "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AIzaSyBO9pr1xgA7hwIoEti0Hf2pM_mvp2QlHG0");
    dynamic responseData;
    try {
      final response = await http.post(
        dbUrl,
        body: json.encode({
          "email": email,
          "password": password,
          "returnSecureToken": true,
        }),
      );

      responseData = json.decode(response.body);

      if (response.statusCode >= 400 || responseData["error"] != null) {
        throw HttpException(message: responseData["error"]["message"]);
      }

      _writeToken = responseData["idToken"];
      _userId = responseData["localId"];
      _expiryDate = DateTime.now().add(
        Duration(seconds: int.parse(responseData["expiresIn"])),
      );

      // **SICHERE SPEICHERUNG**
      await secureStorage.write(key: "email", value: email);
      await secureStorage.write(
          key: "password", value: password); // Sicherer als SharedPreferences
      notifyListeners();
    } catch (error) {
      throw HttpException(message: responseData["error"]["message"]);
    }
  }

  Future<void> resetPassword(BuildContext context, String email) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      appError(messenger, "⚡ Passwort-Reset wird für $email gestartet...");
      await _auth.sendPasswordResetEmail(email: email);
      appError(messenger, "✅ Passwort-Reset-E-Mail erfolgreich gesendet!");
    } on FirebaseAuthException catch (e) {
      appError(messenger, "❌ FirebaseAuthException: ${e.code} - ${e.message}");
      throw Exception("Fehler: ${e.code} - ${e.message}");
    } catch (e) {
      appError(messenger, "❌ Unbekannter Fehler: $e");
      throw Exception("Unbekannter Fehler: $e");
    }
  }

  Future<Map> signUp(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw HttpException(message: "EMAIL oder PASSWORT FEHLT");
    }

    final signUpUrl = Uri.parse(
        "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=AIzaSyBO9pr1xgA7hwIoEti0Hf2pM_mvp2QlHG0");

    final signInUrl = Uri.parse(
        "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AIzaSyBO9pr1xgA7hwIoEti0Hf2pM_mvp2QlHG0");

    try {
      var response = await http.post(
        signUpUrl,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": email,
          "password": password,
          "returnSecureToken": true,
        }),
      );

      var responseData = json.decode(response.body);

      if (response.statusCode >= 400 || responseData["error"] != null) {
        // Falls Benutzer schon existiert, Sign-In versuchen
        response = await http.post(
          signInUrl,
          headers: {"Content-Type": "application/json"},
          body: json.encode({
            "email": email,
            "password": password,
            "returnSecureToken": true,
          }),
        );
        responseData = json.decode(response.body);

        if (response.statusCode >= 400 || responseData["error"] != null) {
          throw HttpException(message: responseData["error"]["message"]);
        }
      }

      // **Token-basiertes Speichern statt Passwort-Speicherung**
      await secureStorage.write(key: "idToken", value: responseData["idToken"]);
      await secureStorage.write(
          key: "refreshToken", value: responseData["refreshToken"]);

      return responseData;
    } catch (error) {
      rethrow;
    }
  }

  void signOut() {
    _writeToken = null;
    _expiryDate = null;
    _userId = null;
    storage.delete(key: "email");
    storage.delete(key: "password");
    notifyListeners();
  }
}
