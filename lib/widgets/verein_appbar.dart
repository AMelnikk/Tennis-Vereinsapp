import 'package:flutter/material.dart';

class VereinAppbar extends AppBar {
  VereinAppbar({super.key});

  @override
  List<Widget>? get actions => [
        // const SizedBox(width: 15,),
        const Padding(
          padding: EdgeInsets.only(right: 10),

          // child: LayoutBuilder(
          //   builder: (context, constraints) {
          //     double fontSize = constraints.maxWidth * 0.1;

          //     return Text(
          //       "TeG Altmühlgrund",
          //       style: TextStyle(
          //           fontSize: fontSize, fontWeight: FontWeight.w600),
          //     );
          //   },
          // ),

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
