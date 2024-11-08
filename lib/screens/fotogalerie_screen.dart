import 'package:flutter/material.dart';
import 'package:verein_app/widgets/verein_appbar.dart';

class FotogalerieScreen extends StatelessWidget {
  const FotogalerieScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: VereinAppbar(),
        body: CustomScrollView(
          slivers: [
            // SliverGrid(
            //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            //         crossAxisCount: 2,
            //         crossAxisSpacing: 10,
            //         mainAxisSpacing: 10),
            //     delegate: SliverChildListDelegate(),)
          ],
        ),);
  }
}
