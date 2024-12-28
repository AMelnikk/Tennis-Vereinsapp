import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:verein_app/widgets/verein_appbar.dart';

class NewsOverviewScreen extends StatelessWidget {
  static const routename = "/news-overview-screen";

  const NewsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments as Map;

    return Scaffold(
      appBar: VereinAppbar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
            child: Container(
          decoration: const BoxDecoration(color: Colors.white),
          child: Column(
            children: [
              Container(
                  child: (arguments["imageData"] != null
                      ? Image.memory(
                          base64Decode(arguments["imageData"] as String))
                      : null),
                ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    arguments["date"] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    arguments["title"] as String,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    arguments["body"] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              )
            ],
          ),
        )

            //   SliverToBoxAdapter(
            //     child: Text(arguments["body"] as String),
            //   ),
            // ],
            ),
      ),
    );
  }
}
