import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/providers/news_provider.dart';
import 'package:verein_app/utils/image_helper.dart';
import '../screens/news_detail_screen.dart';

class NewsTile extends StatelessWidget {
  const NewsTile({
    super.key,
    required this.id,
    required this.title,
    required this.date,
    required this.body,
    required this.photoBlob,
  });

  final String id;
  final List<String> photoBlob;
  final String date;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    NewsProvider newsProvider =
        Provider.of<NewsProvider>(context, listen: false);
    final double tileSize = (MediaQuery.of(context).size.width - 80) / 2;
    final imageCache = newsProvider.imageCache;

    return InkWell(
      onTap: () {
        newsProvider.newsId = id;
        newsProvider.newsDateController.text = date;
        newsProvider.title.text = title;
        newsProvider.body.text = body;
        newsProvider.photoBlob = photoBlob;
        Navigator.of(context).pushNamed(
          NewsDetailScreen.routename,
          arguments: id,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        width: MediaQuery.of(context).size.width,
        height: tileSize,
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
                      style: const TextStyle(fontSize: 22),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            Container(
              height: tileSize,
              width: tileSize,
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
                child: photoBlob.isNotEmpty
                    ? PageView.builder(
                        key: PageStorageKey(id),
                        itemCount: photoBlob.length,
                        itemBuilder: (context, index) {
                          Uint8List bytes =
                              getImage(imageCache, photoBlob[index]);
                          return Image.memory(
                            bytes,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image),
                          );
                        },
                      )
                    : const Center(child: Text("Kein Bild verfügbar")),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
