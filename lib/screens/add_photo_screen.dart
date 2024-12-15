import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  void showSnackBar(int responseStatusCode) {
    if (responseStatusCode < 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Erfolg! Das Foto wurde gepostet",
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Schade! Das Foto könnte nicht gepostet werden",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  void resetProvider(BuildContext context) {
    Provider.of<PhotoProvider>(context, listen: false).image = null;
    Provider.of<PhotoProvider>(context, listen: false).title.text = "";
  }

  void showFehler(HttpException error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ein Fehler ist aufgetreten"),
        content: Text(error.message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> postImage() async {
    // try {
      setState(() {
        _isLoading = true;
      });
      var responseStatusCode =
          await Provider.of<PhotoProvider>(context, listen: false).postImage();
      resetProvider(context);
      setState(() {
        _isLoading = false;
      });
      showSnackBar(responseStatusCode);
    // } on HttpException catch (error) {
    //   showFehler(error);
    // } catch (error) {
    //   rethrow;
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VereinAppbar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  const Text(
                    "Foto Hinzufügen",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: TextFormField(
                      controller: Provider.of<PhotoProvider>(context).title,
                      style: const TextStyle(color: Colors.grey),
                      decoration: const InputDecoration(
                        label: Text("title"),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        height: 100,
                        width: 75,
                        decoration: BoxDecoration(
                          border: Border.all(),
                        ),
                        child: Provider.of<PhotoProvider>(context).image ??
                            const Text(
                              "kein Foto gewählt",
                              textAlign: TextAlign.center,
                            ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextButton.icon(
                          onPressed: () {
                            Provider.of<PhotoProvider>(context, listen: false)
                                .pickImage();
                          },
                          icon: const Icon(Icons.photo),
                          label: const Text(
                            "Foto wählen",
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 30),
                    child: ElevatedButton(
                      onPressed: () {
                        postImage();
                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: double.infinity,
                        height: 50,
                        child: const Text(
                          "Foto Hochladen",
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
