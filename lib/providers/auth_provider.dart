import 'dart:convert';
import 'package:flutter/material.dart';
import "package:http/http.dart" as http;
import '../models/http_exception.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  DateTime? _expiryDate;
  String? _userId;

  String? get token {
    if (_expiryDate != null &&
        _expiryDate!.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    } else {
      return null;
    }
  }

  String? get userId {
    return _userId;
  }

  bool get isAuth {
    return token != null;
  }

  // Future<void> authentificate(
  //   String email,
  //   String password,
  //   String method,
  // ) async {
  //   final dbUrl = Uri.parse(
  //       "https://identitytoolkit.googleapis.com/v1/accounts:$method?key=AIzaSyBO9pr1xgA7hwIoEti0Hf2pM_mvp2QlHG0");
  //   final response = await http.post(
  //     dbUrl,
  //     body: json.encode(
  //       {"email": email, "password": password, "returnSecureToken": true},
  //     ),
  //   );
  //   print(
  //     json.decode(response.body),
  //   );
  // }

  // Future<void> signup(String email, String password) async {
  //   await authentificate(email, password, "signUp");
  // }

  Future<void> signIn(String email, String password) async {
    {
      final dbUrl = Uri.parse(
          "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AIzaSyBO9pr1xgA7hwIoEti0Hf2pM_mvp2QlHG0");
      try {
        final response = await http.post(
          dbUrl,
          body: json.encode(
            {"email": email, "password": password, "returnSecureToken": true},
          ),
        );
        final responseData = json.decode(response.body);
        print(responseData);
        if (responseData["error"] != null) {
          throw HttpException(message: responseData["error"]["message"]);
        }
        _token = responseData["idToken"];
        _userId = responseData["localId"];
        _expiryDate = DateTime.now().add(
          Duration(
            seconds: int.parse(
              responseData["expiresIn"],
            ),
          ),
        );
        notifyListeners();
      } catch (error) {
        rethrow;
      }
    }
  }
}
