import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import "package:http/http.dart" as http;
import '../models/http_exception.dart';

class AuthProvider with ChangeNotifier {
  late final Map<String, String?> credentials;
  final storage = const FlutterSecureStorage();

  String? _token;
  DateTime? _expiryDate;
  String? _userId;
  String? placeBookingLink;

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
        storage.write(key: "email", value: email);
        storage.write(key: "password", value: password);

        var linkResponse = await http.get(Uri.parse(
            "https://db-teg-default-rtdb.firebaseio.com/Users/$_userId.json"));
        Map<String, dynamic>? placeBookingData =
            await json.decode(linkResponse.body);
        if (placeBookingData != null) {
          placeBookingLink = placeBookingData["platzbuchung_link"];
        }
        if (kDebugMode) print(placeBookingLink);

        notifyListeners();
        if (response.statusCode < 300) {}
      } catch (error) {
        if (kDebugMode) print(error);
      }
    }
  }

  Future<void> signUp(String email, String password, String platzbuchungLink,
      String name) async {
    {
      if (name.isEmpty) {
        throw HttpException(message: "NAME_FEHLT");
      }
      final dbUrl = Uri.parse(
          "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=AIzaSyBO9pr1xgA7hwIoEti0Hf2pM_mvp2QlHG0");
      try {
        final response = await http.post(
          dbUrl,
          body: json.encode(
            {"email": email, "password": password, "returnSecureToken": true},
          ),
        );

        final responseData = json.decode(response.body);
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
        storage.write(key: "email", value: email);
        storage.write(key: "password", value: password);

        // var rest =
        await http.put(
          Uri.parse(
              "https://db-teg-default-rtdb.firebaseio.com/Users/$_userId.json?auth=$_token"),
          body: json.encode({
            "name": name,
            "platzbuchung_link": platzbuchungLink,
            "Berechtigung": "Mitglied",
          }),
        );
        // print(rest.statusCode);

        var linkResponse = await http.get(Uri.parse(
            "https://db-teg-default-rtdb.firebaseio.com/Users/$_userId.json"));
        Map<String, dynamic>? placeBookingData =
            await json.decode(linkResponse.body);
        if (placeBookingData != null) {
          placeBookingLink = placeBookingData["platzbuchung_link"];
        }
        // if (kDebugMode) print(placeBookingLink);

        notifyListeners();
        if (response.statusCode < 300) {}
      } catch (error) {
        rethrow;
      }
    }
  }

  void signOut() {
    _token = null;
    _expiryDate = null;
    _userId = null;
    placeBookingLink = null;
    storage.delete(key: "email");
    storage.delete(key: "password");
    notifyListeners();
  }
}
