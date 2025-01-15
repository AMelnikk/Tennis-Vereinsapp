import 'package:flutter/material.dart';

class VereinAppbar extends AppBar {
  VereinAppbar({super.key});

  @override
  List<Widget>? get actions => [
        const Padding(
          padding: EdgeInsets.only(right: 10),

          child: FittedBox(
            fit: BoxFit.fitWidth,
            child: Text(
              "TeG Altmühlgrund",
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ];

  @override
  Widget? get flexibleSpace => Padding(
        padding: const EdgeInsets.only(top: 25, bottom: 5),
        child: Image.asset(
          "assets/images/Vereinslogo.png",
          alignment: Alignment.center,
        ),
      );
}
