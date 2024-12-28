import 'package:flutter/material.dart';

class MoreTile extends StatelessWidget {
  MoreTile({
    super.key,
    required this.navigateTo,
    required this.assetImage,
  });

  final _key = GlobalKey();

  final String navigateTo;
  final String assetImage;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: _key,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(navigateTo);
        },
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          assetImage,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}
