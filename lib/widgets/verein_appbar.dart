import 'package:flutter/material.dart';

class VereinAppbar extends AppBar {
  VereinAppbar({super.key})
      : super(
          backgroundColor: Colors.black,
          automaticallyImplyLeading: true,
          elevation: 0,
          title: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Links: ornbau.png
                Image.asset(
                  "assets/images/ornbau.png",
                  height: 40,
                ),

                // Mitte: Text
                const Text(
                  "TeG Altmühlgrund",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                // Rechts: Vereinslogo
                Image.asset(
                  "assets/images/Vereinslogo.png",
                  height: 40,
                ),
              ],
            ),
          ),
        );
}
