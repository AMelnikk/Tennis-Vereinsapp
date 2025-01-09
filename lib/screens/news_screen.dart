import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/providers/photo_provider.dart';
import '../providers/news_provider.dart';
import '../widgets/news_tile.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  bool _isFirstLoading = false;
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
      if (kDebugMode) {
        print(error);
      }
    }
  }

  @override
  void didChangeDependencies() {
    if (_isLoading) {
      if (Provider.of<NewsProvider>(context).loadedNews.isEmpty) {
        if (mounted) {
          setState(() {
            _isFirstLoading = true;
          });
        }
        Provider.of<PhotoProvider>(context).getData();
        getData().then((_) {
          if (mounted) {
            setState(() {
              _isFirstLoading = false;
            });
          }
        });
      } else {
        _isLoading = false;
      }
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return _isFirstLoading
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
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverList.builder(
                    itemCount:
                        Provider.of<NewsProvider>(context).loadedNews.length,
                    itemBuilder: (ctx, index) => NewsTile(
                      id: Provider.of<NewsProvider>(context)
                          .loadedNews[Provider.of<NewsProvider>(context)
                                  .loadedNews
                                  .length -
                              1 -
                              index]
                          .id,
                      title: Provider.of<NewsProvider>(context)
                          .loadedNews[Provider.of<NewsProvider>(context)
                                  .loadedNews
                                  .length -
                              1 -
                              index]
                          .title,
                      date: Provider.of<NewsProvider>(context)
                          .loadedNews[Provider.of<NewsProvider>(context)
                                  .loadedNews
                                  .length -
                              1 -
                              index]
                          .date,
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
                  if (_isLoading)
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 50,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  else if ((Provider.of<NewsProvider>(context).hasMore))
                    SliverToBoxAdapter(
                      child: GestureDetector(
                        onTap: getData,
                        child: const SizedBox(
                          height: 50,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.pending_rounded),
                              SizedBox(
                                width: 5,
                              ),
                              Text("mehr anzeigen"),
                            ],
                          ),
                        ),
                      ),
                    )
                ],
              );
  }
}
