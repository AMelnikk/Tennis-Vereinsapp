import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:verein_app/models/game_result.dart';
import 'package:http/http.dart' as http;

class GameResultsProvider with ChangeNotifier {
  List<GameResult> _gameResults = [];

  List<GameResult> get gameResults{
    return _gameResults;
  }

  Future<void> getData() async {
    final List<GameResult> loadedData = [];
    // try {
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
      _gameResults = loadedData;
    // } catch (e) {
    //   print("An error occured");
    // }
    notifyListeners();
  }
}
