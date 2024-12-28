import 'package:flutter/material.dart';
import 'package:verein_app/widgets/verein_appbar.dart';

class ImpressumScreen extends StatelessWidget {
  const ImpressumScreen({super.key});

  static const routename = "/impressum-screen";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VereinAppbar(),
      body: const Padding(
        padding: EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                Text(
                  "Impressum",
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                Text("data")
              ],
            ),
          ),
        ),
      ),
    );
  }
}
