import 'package:flutter/material.dart';
import '../widgets/verein_appbar.dart';

class TrainersScreen extends StatefulWidget {
  const TrainersScreen({super.key});
  static const routename = "/trainers-screen";

  @override
  State<TrainersScreen> createState() => _TrainersScreenState();
}

class _TrainersScreenState extends State<TrainersScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    Future.delayed(const Duration(seconds: 1));
    _isLoading = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VereinAppbar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 10),
                    child: Image.asset(
                        "assets/images/Natali_Gumbrecht_Trainer.webp"),
                  ),
                  const Text(
                    "Natali Gumbrecht",
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 10),
                    child:
                        Image.asset("assets/images/Oliver_Ströbel_Trainer.webp"),
                  ),
                  const Text(
                    "Oliver Ströbel",
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 10,
                  )
                ],
              ),
            ),
    );
  }
}
