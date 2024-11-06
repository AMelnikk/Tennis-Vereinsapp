import 'package:flutter/material.dart';
import 'package:verein_app/widgets/verein_appbar.dart';

class TrainersScreen extends StatelessWidget {
  const TrainersScreen({super.key});
  static const routename = "/trainers-screen";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VereinAppbar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
              child: Image.asset("assets/images/Natali_Gumbrecht_Trainer.jpg"),
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
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
              child: Image.asset("assets/images/Oliver_Ströbel_Trainer.jpg"),
            ),
            const Text(
              "Oliver Ströbel",
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10,)
          ],
        ),
      ),
    );
  }
}
