import 'package:flutter/material.dart';

class VereinAppbar extends AppBar {
  VereinAppbar({super.key});

  @override
  List<Widget>? get actions => [
        // const SizedBox(width: 15,),
        const Padding(
          padding: EdgeInsets.only(right: 10),
          child: Text(
            "TeG Altmühlgrund",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
      ];

  @override
  Widget? get flexibleSpace => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 5),
        child: Image.asset(
          "assets/images/Vereinslogo.png",
          alignment: Alignment.center,
        ),
      );
}
