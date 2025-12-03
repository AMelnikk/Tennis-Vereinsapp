import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../screens/news_detail_screen.dart';

class NewsTileNew extends StatelessWidget {
  const NewsTileNew({
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
    final double tileSize = (MediaQuery.of(context).size.width - 80) / 2;

    return InkWell(
      onTap: () {
        Navigator.of(context)
            .pushNamed(NewsDetailScreen.routename, arguments: id);
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
                    Text(date, style: const TextStyle(color: Colors.grey)),
                    Text(title,
                        style: const TextStyle(fontSize: 22),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: tileSize,
              width: tileSize,
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
                          final url = photoBlob[index];
                          return CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) =>
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
