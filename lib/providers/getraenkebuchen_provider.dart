import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GetraenkeBuchenProvider with ChangeNotifier {
  GetraenkeBuchenProvider(this._token);

  final String? _token;

  // Controllers for input fields
  final TextEditingController _wasserController = TextEditingController();
  final TextEditingController _softController = TextEditingController();
  final TextEditingController _bierController = TextEditingController();
  final TextEditingController _summeController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  // Getters for controllers to allow controlled access
  TextEditingController get wasserController => _wasserController;
  TextEditingController get softController => _softController;
  TextEditingController get bierController => _bierController;
  TextEditingController get summeController => _summeController;
  TextEditingController get usernameController => _usernameController;

  Future<int> postGetraenke() async {
    if (_token == null || _token!.isEmpty) {
      if (kDebugMode) print("Token is missing");
      return 400;
    }

    final url = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/GetrankeListe/Getraenkeliste.json?auth=$_token");

    final payload = {
      "Username": _usernameController.text,
      "Wasser": _wasserController.text,
      "Soft": _softController.text,
      "Bier": _bierController.text,
      "Summe": _summeController.text,
    };

    try {
      final response = await http.put(
        url,
        body: json.encode(payload),
        headers: {'Content-Type': 'application/json'},
      );

      if (kDebugMode) print("Response status: ${response.statusCode}");
      if (kDebugMode) print("Response body: ${response.body}");

      return response.statusCode;
    } on SocketException {
      if (kDebugMode) print("Network error occurred");
      return 500; // Simulate server error for network issues
    } catch (error) {
      if (kDebugMode) print("An unexpected error occurred: $error");
      return 400; // Default error code
    }
  }

  // Dispose controllers to prevent memory leaks
  @override
  void dispose() {
    _wasserController.dispose();
    _softController.dispose();
    _bierController.dispose();
    _summeController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}
