import 'dart:convert';

import 'package:flutter/material.dart';

class NewsTile extends StatelessWidget {
  const NewsTile(
      {super.key, required this.title, required this.date, this.base64image});

  final String? base64image;
  final String date;
  final String title;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        width: MediaQuery.of(context).size.width,
        height: (MediaQuery.of(context).size.width - 80) / 2,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 25),
                      overflow: TextOverflow.visible,
                    ),
                    const SizedBox(
                      height: 5,
                    )
                  ],
                ),
              ),
            ),
            Container(
              height: (MediaQuery.of(context).size.width - 80) / 2,
              width: (MediaQuery.of(context).size.width - 80) / 2,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                ),
              ),
              child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(5),
                    bottomRight: Radius.circular(5),
                  ),
                  child: base64image != null
                      ? Image.memory(
                          base64Decode(base64image as String),
                          fit: BoxFit.cover,
                        )
                      : null),
            ),
          ],
        ),
      ),
    );
  }
}
