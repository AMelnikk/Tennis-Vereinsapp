import 'package:flutter/material.dart';

class VereinAppbar extends AppBar {
  VereinAppbar({super.key});

  @override
  Widget? get leading => Padding(
        padding: const EdgeInsets.all(3),
        child: Image.asset("assets/images/Vereinslogo.png"),
      );

  @override
  List<Widget>? get actions => const [
        Padding(
          padding: EdgeInsets.only(right: 10),
          child: Text(
            "TeG Altmühlgrund",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
      ];
}
