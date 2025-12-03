import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/news.dart';

class NewsProviderNew with ChangeNotifier {
  NewsProviderNew(this.token);
  String? token;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool isNewsLoading = false;
  bool isFirstLoading = true;
  List<News> loadedNews = [];
  bool hasMore = true;
  DocumentSnapshot? lastDocument;
  final int pageSize = 5;
  final Map<String, Uint8List> imageCache = {};

  // variables for admin (e.g. add_news_screen.dart and so on)
  bool isDebug = false;
  final title = TextEditingController();
  final body = TextEditingController();
  final newsDateController = TextEditingController();
  final categoryController = TextEditingController();
  String selectedCategory = "Allgemein";
  String newsId = '';
  List<String> photoBlob = [];
  String newsDate = '';
  String author = '';
  String? lastId;
  final List<String> categories = [
    "Allgemein",
    "Spielbericht",
  ];

  Future<void> getData() async {
    if (!hasMore) return;
    try {
      Query query = _firestore
          .collection('news')
          .orderBy('date', descending: true)
          .limit(pageSize);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        hasMore = false;
        isFirstLoading = false;
        notifyListeners();
        return;
      }

      final List<News> fetched = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final Timestamp ts = data['date'] as Timestamp;
        final String dateString =
            (data['dateString'] as String?) ?? _formatTimestamp(ts);
        final List<String> photoBlob = (data['photoBlob'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        return News(
          id: doc.id,
          title: data['title'] ?? '',
          body: data['body'] ?? '',
          date: dateString,
          author: data['author'] ?? '',
          category: data['category'] ?? '',
          photoBlob: photoBlob,
          lastUpdate: (data['lastUpdate'] != null)
              ? (data['lastUpdate'] is int
                  ? data['lastUpdate'] as int
                  : (data['lastUpdate'] is Timestamp
                      ? (data['lastUpdate'] as Timestamp).millisecondsSinceEpoch
                      : DateTime.now().millisecondsSinceEpoch))
              : DateTime.now().millisecondsSinceEpoch,
        );
      }).toList();

      lastDocument = snapshot.docs.last;
      loadedNews.addAll(fetched);
      if (snapshot.docs.length < pageSize) hasMore = false;

      isFirstLoading = false;
      notifyListeners();
    } catch (e, st) {
      if (kDebugMode) {
        print('getData error: $e\n$st');
      }
      isFirstLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    loadedNews = [];
    lastDocument = null;
    hasMore = true;
    isFirstLoading = true;
    await getData();
  }

  Future<String> postNews({
    required String? docId,
    required String title,
    required String body,
    required String author,
    required String category,
    DateTime? date,
    List<File>? imagesToUpload,
    List<String>? existingPhotoUrls,
  }) async {
    try {
      final DateTime finalDate = date ?? DateTime.now();
      final Timestamp ts = Timestamp.fromDate(finalDate);
      final String dateString =
          "${finalDate.year.toString().padLeft(4, '0')}-${finalDate.month.toString().padLeft(2, '0')}-${finalDate.day.toString().padLeft(2, '0')}";

      final List<String> photoUrls = <String>[];
      if (existingPhotoUrls != null) {
        photoUrls.addAll(existingPhotoUrls);
      }

      if (imagesToUpload != null && imagesToUpload.isNotEmpty) {
        for (final file in imagesToUpload) {
          final ref = _storage.ref().child('news_images').child(
              '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}');
          await ref.putFile(file);
          final url = await ref.getDownloadURL();
          photoUrls.add(url);
        }
      }

      final docData = {
        'title': title,
        'body': body,
        'author': author,
        'category': category,
        'date': ts,
        'dateString': dateString,
        'lastUpdate': Timestamp.fromDate(DateTime.now()),
        'photoUrls': photoUrls,
      };

      if (docId == null || docId.isEmpty) {
        final docRef = await _firestore.collection('news').add(docData);
        loadedNews.insert(
          0,
          News(
            id: docRef.id,
            title: title,
            body: body,
            date: dateString,
            author: author,
            category: category,
            photoBlob: photoUrls,
            lastUpdate: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        notifyListeners();
        return docRef.id;
      } else {
        await _firestore
            .collection('news')
            .doc(docId)
            .set(docData, SetOptions(merge: true));
        final idx = loadedNews.indexWhere((n) => n.id == docId);
        if (idx != -1) {
          loadedNews[idx] = News(
            id: docId,
            title: title,
            body: body,
            date: dateString,
            author: author,
            category: category,
            photoBlob: photoUrls,
            lastUpdate: DateTime.now().millisecondsSinceEpoch,
          );
        }
        notifyListeners();
        return docId;
      }
    } catch (e, st) {
      if (kDebugMode) print('postNews error: $e\n$st');
      return "";
    }
  }

  Future<bool> deleteNews(String docId, {bool deleteImages = true}) async {
    try {
      final doc = await _firestore.collection('news').doc(docId).get();
      if (!doc.exists) return false;
      await _firestore.collection('news').doc(docId).delete();
      loadedNews.removeWhere((n) => n.id == docId);
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('deleteNews error: $e');
      return false;
    }
  }

  Future<List<News>> loadAllNewsForAdmin() async {
    try {
      final snapshot = await _firestore
          .collection('news')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final Timestamp ts = data['date'] as Timestamp;
        final String dateString =
            (data['dateString'] as String?) ?? _formatTimestamp(ts);
        final List<String> urls = (data['photoUrls'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        return News(
          id: doc.id,
          title: data['title'] ?? '',
          body: data['body'] ?? '',
          date: dateString,
          author: data['author'] ?? '',
          category: data['category'] ?? '',
          photoBlob: urls,
          lastUpdate: (data['lastUpdate'] is Timestamp)
              ? (data['lastUpdate'] as Timestamp).millisecondsSinceEpoch
              : 0,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) print('loadAllNewsForAdmin error: $e');
      return [];
    }
  }

  Future<News?> getNewsById(String id) async {
    return loadedNews.firstWhere((n) => n.id == id);
  }

  void updateCategory(String newCategory) {
    selectedCategory = newCategory;
    notifyListeners();
  }

  String _formatTimestamp(Timestamp ts) {
    final dt = ts.toDate();
    return "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}";
  }
}
