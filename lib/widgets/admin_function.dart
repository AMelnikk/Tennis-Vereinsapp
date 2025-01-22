import 'package:flutter/material.dart';

class AdminFunction extends StatelessWidget {
  const AdminFunction({super.key, required this.function, required this.text});

  final Function() function;
  final String text;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: function,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                text,
                textAlign: TextAlign.left,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                height: 75,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
