import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserProvider with ChangeNotifier {
  UserProvider(this._token);

  String? _token;
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
          },
        ),
      );
      print(response.statusCode);
      return response.statusCode;
    } catch (error) {
      if (kDebugMode) print(error);
      return 400;
    }
  }
}
