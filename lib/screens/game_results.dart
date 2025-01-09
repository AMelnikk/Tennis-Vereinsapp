import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/verein_appbar.dart';
import 'package:http/http.dart' as http;

class GameResults extends StatelessWidget {
  const GameResults({super.key});
  static const routename = "game-results/";

  Future<void> getData() async {
    Uri url = Uri.parse("https://www.btv.de/de/spielbetrieb/tabelle-spielplan.html?groupid=1963788");
    var responce = await http.get(url);
    var data = json.decode(responce.body);
    if(kDebugMode) print(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VereinAppbar(),
      body: const Center(
        child: Text("Spielergebnisse"),
      ),
    );
  }
}
