import 'package:flutter/material.dart';

class NewsOverviewScreen extends StatelessWidget {
  const NewsOverviewScreen({
    super.key,
    required this.image,
    required this.date,
    required this.body,
    required this.title,
  });

  final Image image;
  final String title;
  final String date;
  final String body;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: image,
        ),
        SliverToBoxAdapter(
          child: Text(date),
        ),
        SliverToBoxAdapter(
          child: Text(title),
        ),
        SliverToBoxAdapter(
          child: Text(body),
        ),
      ],
    );
  }
}
