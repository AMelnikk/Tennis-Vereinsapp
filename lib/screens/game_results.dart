import 'package:flutter/material.dart';
import 'package:verein_app/widgets/verein_appbar.dart';

class GameResults extends StatelessWidget {
  const GameResults({super.key});
  static const routename = "./game-results";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VereinAppbar(),
      body: Center(
        child: Text("Spielergebnisse"),
      ),
    );
  }
}
