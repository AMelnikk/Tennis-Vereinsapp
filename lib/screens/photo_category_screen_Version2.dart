import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/photo_provider_Version2.dart';
import 'photo_view_screen_Version2.dart'; // Ensure this import is added

class PhotoCategoryScreen extends StatelessWidget {
  static const routename = "/photo-category-screen";

  final String categoryName;

  const PhotoCategoryScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    final photoProvider = Provider.of<PhotoProvider>(context);
    final categoryImages = photoProvider.getImagesByCategory(categoryName);

    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: categoryImages.isEmpty
          ? const Center(child: Text("Keine Bilder vorhanden"))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 Spalten
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: categoryImages.length,
              itemBuilder: (ctx, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => PhotoViewScreen(
                          imageData: base64Decode(categoryImages[index]),
                        ),
                      ),
                    );
                  },
                  child: Image.memory(
                    base64Decode(categoryImages[index]),
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
    );
  }
}
