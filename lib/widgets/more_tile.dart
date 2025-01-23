import 'package:flutter/material.dart';

class MoreTile extends StatelessWidget {
  MoreTile({
    super.key,
    required this.function,
    required this.assetImage,
  });

  final _key = GlobalKey();

  final Function() function;
  final String assetImage;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: _key,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: function,
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          assetImage,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}
