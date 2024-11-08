import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:verein_app/models/game_result.dart';
import 'package:http/http.dart' as http;

class FotoProvider with ChangeNotifier{

  Future<List<GameResult>> getData() async {
    final List<GameResult> loadedData = [];
    try {
      final responce = await http.get(
        Uri.parse(
            "https://db-teg-default-rtdb.firebaseio.com/Fotos.json"),
      );
    //   final extractedData =
    //       await (json.decode(responce.body)) as Map<String, Image>;
    //   extractedData.forEach(
    //     (resId, resData) {
    //       loadedData.add(
    //         GameResult(
    //           id: resId,
    //           name: resData["name"],
    //           url: resData["url"],
    //         ),
    //       );
    //     },
    //   );
    } catch (e) {
      print("An error occured");
    }
    notifyListeners();
    return loadedData;
  }
}