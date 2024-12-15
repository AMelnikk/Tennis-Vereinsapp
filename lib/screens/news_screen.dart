import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../widgets/news_tile.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  bool _isLoading = false;

  Future<void> getData() async {
    try {
      if (Provider.of<NewsProvider>(context).loadedNews.isEmpty) {
        setState(() {
          _isLoading = true;
        });

        await Provider.of<NewsProvider>(context, listen: false).getData();
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      print(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    getData();
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : CustomScrollView(
            slivers: [
              SliverList.builder(
                itemCount: Provider.of<NewsProvider>(context).loadedNews.length,
                itemBuilder: (ctx, index) => NewsTile(
                  title: Provider.of<NewsProvider>(context)
                      .loadedNews[index]
                      .title,
                  // title: "test",
                  date:
                      Provider.of<NewsProvider>(context).loadedNews[index].date,
                  // date: DateFormat("dd.MM.yyyy").format(DateTime.now()),
                  base64image: Provider.of<NewsProvider>(context)
                      .loadedNews[index]
                      .imageData,
                ),
              ),
            ],
          );
  }
}
