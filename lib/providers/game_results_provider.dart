import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/game_result.dart';
import 'package:http/http.dart' as http;

class GameResultsProvider with ChangeNotifier {

  Future<List<GameResult>> getData() async {
    final List<GameResult> loadedData = [];
    try {
      final responce = await http.get(
        Uri.parse(
            "https://db-teg-default-rtdb.firebaseio.com/Spielergebnisse.json/"),
      );
      final extractedData =
          await (json.decode(responce.body)) as Map<String, dynamic>;
      extractedData.forEach(
        (resId, resData) {
          loadedData.add(
            GameResult(
              id: resId,
              name: resData["name"],
              url: resData["url"],
            ),
          );
        },
      );
    } catch (e) {
      print("An error occured");
    }
    notifyListeners();
    return loadedData;
  }
}
