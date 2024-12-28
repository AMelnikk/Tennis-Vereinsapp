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
  bool _isLoading = true;

  Future<void> getData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await Provider.of<NewsProvider>(context, listen: false).getData();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      print(error);
    }
  }

  @override
  void didChangeDependencies() {
    if (_isLoading) {
      if (Provider.of<NewsProvider>(context).loadedNews.isEmpty) {
        getData();
      } else {
        _isLoading = false;
      }
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Provider.of<NewsProvider>(context).loadedNews.isEmpty
            ? RefreshIndicator(
                onRefresh: getData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height -
                        AppBar().preferredSize.height -
                        MediaQuery.of(context).padding.bottom -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).viewInsets.bottom -
                        kBottomNavigationBarHeight,
                    child: const Center(
                      child: Text(
                        "Es gibt noch nichts hier",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: getData,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverList.builder(
                      itemCount:
                          Provider.of<NewsProvider>(context).loadedNews.length,
                      itemBuilder: (ctx, index) => NewsTile(
                        title: Provider.of<NewsProvider>(context)
                            .loadedNews[Provider.of<NewsProvider>(context)
                                    .loadedNews
                                    .length -
                                1 -
                                index]
                            .title,
                        // title: "test",
                        date: Provider.of<NewsProvider>(context)
                            .loadedNews[Provider.of<NewsProvider>(context)
                                    .loadedNews
                                    .length -
                                1 -
                                index]
                            .date,
                        // date: DateFormat("dd.MM.yyyy").format(DateTime.now()),
                        body: Provider.of<NewsProvider>(context)
                            .loadedNews[Provider.of<NewsProvider>(context)
                                    .loadedNews
                                    .length -
                                1 -
                                index]
                            .body,
                        base64image: Provider.of<NewsProvider>(context)
                            .loadedNews[Provider.of<NewsProvider>(context)
                                    .loadedNews
                                    .length -
                                1 -
                                index]
                            .imageData,
                      ),
                    ),
                  ],
                ),
              );
  }
}
