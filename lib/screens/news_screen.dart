import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:verein_app/data/dummy_data.dart';
import 'package:verein_app/widgets/news_tile.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverList.builder(
          itemCount: DummyData.news.length,
          itemBuilder: (ctx, index) => NewsTile(
            title: DummyData.news[index]["title"],
            date: DateFormat("dd.MM.yyy").format(DateTime.now()),
          ),
        ),
      ],
    );
  }
}
