import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/news.dart';
import '../popUps/show_images_dialog.dart';
import '../providers/user_provider.dart';
import '../screens/add_news_screen.dart';
import '../utils/image_helper.dart';
import '../providers/news_provider_new.dart';
import '../providers/auth_provider.dart';
import '../widgets/verein_appbar.dart';

class NewsDetailScreen extends StatefulWidget {
  static const routename = '/news-detail';

  const NewsDetailScreen({super.key});

  @override
  NewsDetailScreenState createState() => NewsDetailScreenState();
}

class NewsDetailScreenState extends State<NewsDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  News? detailNews;
  bool? _isAdmin;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newsID = ModalRoute.of(context)?.settings.arguments as String?;
    if (newsID != null && newsID.isNotEmpty) {
      Provider.of<NewsProviderNew>(context, listen: false)
          .getNewsById(newsID)
          .then((news) {
        if (mounted) {
          setState(() {
            detailNews = news;
          });
        }
      }).catchError((error) {
        // Handle error, for example by showing a snackbar or logging it
        debugPrint('Error loading news: $error');
      });
    }

    _loadAdminStatus();
  }

  Future<void> _loadAdminStatus() async {
    bool isAdmin = await Provider.of<UserProvider>(context, listen: false)
        .isAdmin(context);
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (detailNews == null) {
      return Scaffold(
        appBar: VereinAppbar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    NewsProviderNew newsProvider =
        Provider.of<NewsProviderNew>(context, listen: false);
    AuthorizationProvider authProvider =
        Provider.of<AuthorizationProvider>(context, listen: false);

    final imageCache = newsProvider.imageCache;

    final String currentUser =
        Provider.of<AuthorizationProvider>(context, listen: false)
            .userId
            .toString();

    return Scaffold(
      appBar: VereinAppbar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Column(
            children: [
              buildImageSection(detailNews!.photoBlob, imageCache),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        buildTextSection(detailNews!),
                        if (_isAdmin != null) ...[
                          if (_isAdmin == true ||
                              (authProvider.isSignedIn &&
                                  currentUser == detailNews!.author)) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    final newsId = await Navigator.push<String>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AddNewsScreen(),
                                      ),
                                    );

                                    if (newsId != null && newsId.isNotEmpty) {
                                      setState(() {
                                        detailNews!.id = newsId;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.edit_rounded),
                                ),
                                if (_isAdmin == true)
                                  IconButton(
                                    onPressed: () {
                                      Provider.of<NewsProviderNew>(context,
                                              listen: false)
                                          .deleteNews(detailNews!.id);
                                      Navigator.of(context).pop();
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Color.fromARGB(255, 104, 23, 18),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _imageHeight() {
    double containerWidth = MediaQuery.of(context).size.width;
    double imageAspectRatio = 16 / 9;
    return containerWidth / imageAspectRatio;
  }

  Widget buildImageSection(
      List<String> photoBlob, Map<String, Uint8List> imageCache) {
    return photoBlob.isNotEmpty
        ? Container(
            width: double.infinity,
            height: _imageHeight(),
            color: Colors.white,
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    showImageDialog(context, photoBlob, _currentPage);
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: photoBlob.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      Uint8List bytes = getImage(imageCache, photoBlob[index]);

                      return FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.topCenter,
                        child: Image.memory(
                          bytes,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 50,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (_pageController.hasClients &&
                          (_pageController.page ?? 0) > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      }
                    },
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 50,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    onPressed: () {
                      if (_pageController.hasClients &&
                          (_pageController.page ?? 0) < photoBlob.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      }
                    },
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_currentPage + 1} / ${photoBlob.length}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          )
        : Container();
  }

  Widget buildTextSection(News news) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 10, right: 10),
          child: Text(
            news.date,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 10, right: 10),
          child: Text(
            news.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            news.body,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
}
