import 'package:flutter/material.dart';

class DocumentTile extends StatelessWidget {
  const DocumentTile(
      {super.key,
      required this.text,
      required this.imagePath,
      required this.function});
  final String text;
  final String imagePath;
  final Function() function;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => function(),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                height: 100,
                width: 70,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                text,
                textAlign: TextAlign.left,
                style: const TextStyle(fontSize: 14),
              ),
            )
          ],
        ),
      ),
    );
  }
}
