import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/widgets/news_tile.dart';
import '../providers/news_provider_new.dart';

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
    Provider.of<NewsProviderNew>(context, listen: false).refresh();
    setState(() {
      _isRefreshLoading = false;
    });
  }

  Future<void> getData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await Provider.of<NewsProviderNew>(context, listen: false).getData();
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Provider.of<NewsProviderNew>(context).loadedNews.isEmpty &&
        Provider.of<NewsProviderNew>(context).isFirstLoading) {
      getData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final newsProvider = Provider.of<NewsProviderNew>(context);

    if (kDebugMode) print("screen loadedNews: ${newsProvider.loadedNews}");

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
                final news = newsProvider.loadedNews[index];
                return NewsTile(
                  id: news.id,
                  title: news.title,
                  date: news.date,
                  body: news.body,
                  photoBlob: news.photoBlob,
                );
              },
              childCount: newsProvider.loadedNews.length,
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
