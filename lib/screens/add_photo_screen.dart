import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/utils/app_utils.dart';
import '../providers/photo_provider.dart';
import '../widgets/verein_appbar.dart';

class AddPhotoScreen extends StatefulWidget {
  const AddPhotoScreen({super.key});
  static const routename = "/add-photo-screen";

  @override
  State<AddPhotoScreen> createState() => _AddPhotoScreenState();
}

class _AddPhotoScreenState extends State<AddPhotoScreen> {
  bool _isLoading = false;

  Future<void> postImages() async {
    final messenger = ScaffoldMessenger.of(context); // Vorher speichern
    setState(() {
      _isLoading = true;
    });

    try {
      final statusCode =
          await Provider.of<PhotoProvider>(context, listen: false).postImages();
      if (statusCode == 200) {
        appError(messenger, "Erfolg! Die Bilder wurden hochgeladen");
      } else {
        appError(messenger, "Fehler beim Hochladen der Bilder");
      }
    } catch (error) {
      appError(messenger, "Fehler: $error");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VereinAppbar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    const Text(
                      "Fotos Hinzufügen",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          // Anzeigen der ausgewählten Bilder
                          Expanded(
                            child: Column(
                              children: [
                                ...Provider.of<PhotoProvider>(context)
                                    .images
                                    .map((image) {
                                  return Container(
                                    height: 100,
                                    width: 75,
                                    margin: const EdgeInsets.all(5),
                                    child: image,
                                  );
                                }),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: TextButton.icon(
                              onPressed: () {
                                Provider.of<PhotoProvider>(context,
                                        listen: false)
                                    .pickImages();
                              },
                              icon: const Icon(Icons.photo),
                              label: const Text("Bilder wählen",
                                  style: TextStyle(fontSize: 20)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 30),
                      child: ElevatedButton(
                        onPressed: postImages,
                        child: Container(
                          alignment: Alignment.center,
                          width: double.infinity,
                          height: 50,
                          child: const Text("Bilder Hochladen",
                              style: TextStyle(fontSize: 20)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
