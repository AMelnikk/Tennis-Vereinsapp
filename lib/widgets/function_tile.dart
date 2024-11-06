import 'package:flutter/material.dart';

class FunctionTile extends StatelessWidget {
  const FunctionTile({super.key, required this.image, required this.onTap});

  final Image image;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        splashColor: Colors.white,
        onTap: onTap,
        child: image,
      ),
    );
  }
}
