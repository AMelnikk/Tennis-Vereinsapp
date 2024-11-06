import 'dart:convert';

import 'package:flutter/material.dart';
import "package:http/http.dart" as http;

class AuthProvider with ChangeNotifier {
  String token = "";
  DateTime expiryDate = DateTime.now();
  String userId = "";

  Future<void> authentificate(
    String email,
    String password,
    String method,
  ) async {
    final dbUrl = Uri.parse(
        "https://identitytoolkit.googleapis.com/v1/accounts:$method?key=AIzaSyBO9pr1xgA7hwIoEti0Hf2pM_mvp2QlHG0");
    final response = await http.post(
      dbUrl,
      body: json.encode(
        {"email": email, "password": password, "returnSecureToken": true},
      ),
    );
    print(
      json.decode(response.body),
    );
  }

  Future<void> signup(String email, String password) async {
    await authentificate(email, password, "signUp");
  }

  Future<void> signin(String email, String password) async {
    await authentificate(email, password, "signInWithCustomToken");
  }
}
