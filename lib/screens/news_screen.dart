import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isRefreshLoading = false;

  Future<void> refreshFunction() async {
    setState(() {
      _isRefreshLoading = true;
    });
    Provider.of<NewsProvider>(context, listen: false).loadedNews = [];
    Provider.of<NewsProvider>(context, listen: false).hasMore = true;
    Provider.of<NewsProvider>(context, listen: false).lastId = null;
    await getData();
    setState(() {
      _isRefreshLoading = false;
    });
  }

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
      if (kDebugMode) {
        print(error);
      }
    }
  }

  // @override
  // void didChangeDependencies() {
  //   if (_isLoading) {
  //     if (Provider.of<NewsProvider>(context).loadedNews.isEmpty) {
  //       // if (mounted) {
  //       //   setState(() {
  //       //     _isFirstLoading = true;
  //       //   });
  //       // }
  //       // getData().then((_) {
  //       //   if (mounted) {
  //       //     setState(() {
  //       //       _isFirstLoading = false;
  //       //     });
  //       //   }
  //       // });
  //     } else {
  //       _isLoading = false;
  //     }
  //   }

  //   super.didChangeDependencies();
  // }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Provider.of<NewsProvider>(context).loadedNews.isEmpty) {
      getData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final newsProvider = Provider.of<NewsProvider>(context);

    final reversedNews = newsProvider.loadedNews.reversed.toList();
    //reversedNews.sort((a, b) => b.date.compareTo(a.date));

    if (kDebugMode) print("screen loadedNews: ${newsProvider.loadedNews}");
    if (kDebugMode) print("screen reversedNews: $reversedNews");

    if (_isRefreshLoading ||
        newsProvider.isNewsLoading ||
        newsProvider.isFirstLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (newsProvider.loadedNews.isEmpty) {
      return RefreshIndicator(
        onRefresh: refreshFunction,
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
      );
    }

    return RefreshIndicator(
      onRefresh: refreshFunction,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, index) {
                final news = reversedNews[index];
                return NewsTile(
                  id: news.id,
                  title: news.title,
                  date: news.date,
                  body: news.body,
                  photoBlob: news.photoBlob,
                );
              },
              childCount: reversedNews.length,
            ),
          ),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (newsProvider.hasMore)
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: getData,
                child: const SizedBox(
                  height: 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pending_rounded),
                      SizedBox(width: 5),
                      Text("mehr anzeigen"),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
