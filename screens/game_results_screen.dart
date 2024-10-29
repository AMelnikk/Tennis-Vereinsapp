import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/models/game_result.dart';
import 'package:verein_app/providers/game_results_provider.dart';
import 'package:verein_app/widgets/game_results_tile.dart';
import 'package:verein_app/widgets/verein_appbar.dart';

class GameResultsScreen extends StatefulWidget {
  const GameResultsScreen({super.key});
  static const routename = "game-results/";

  @override
  State<GameResultsScreen> createState() => _GameResultsScreenState();
}

class _GameResultsScreenState extends State<GameResultsScreen> {
  var _isLoading = false;
  List<GameResult> gameResults = [];

  Future<void> getData() async {
    setState(() {
      _isLoading = true;
    });
    await Provider.of<GameResultsProvider>(context, listen: false).getData();
    gameResults =
        Provider.of<GameResultsProvider>(context, listen: false).gameResults;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VereinAppbar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: gameResults
                    .map(
                      (el) => GameResultsTile(name: el.name, url: el.url),
                    )
                    .toList(),
              ),
            ),
    );
  }
}
