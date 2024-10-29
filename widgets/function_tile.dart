import 'package:flutter/material.dart';

class FunctionTile extends StatelessWidget {
  const FunctionTile({super.key, required this.title, required this.onTap});

  final String title;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        child: Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 17),
            ),
          ),
        ),
      ),
    );
  }
}
