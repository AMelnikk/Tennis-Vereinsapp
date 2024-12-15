import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../widgets/verein_appbar.dart';

class AddNewsScreen extends StatefulWidget {
  const AddNewsScreen({super.key});
  static const routename = "/add-news-screen";

  @override
  State<AddNewsScreen> createState() => _AddNewsScreenState();
}

enum NewsTag { tag1, tag2 } // TODO

class _AddNewsScreenState extends State<AddNewsScreen> {
  bool _isLoading = false;

  void showSnackBar(int responseStatusCode) {
    if (responseStatusCode < 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Erfolg! Die Neuigkeit wurde gepostet",
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Schade! Die Neuigkeit könnte nicht gepostet werden",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    "News hinzufügen",
                    style: TextStyle(fontSize: 20),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: TextFormField(
                      decoration: const InputDecoration(
                        label: Text("title"),
                      ),
                      controller: Provider.of<NewsProvider>(context).title,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: TextFormField(
                      decoration: const InputDecoration(
                        label: Text("body"),
                      ),
                      controller: Provider.of<NewsProvider>(context).body,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 20,
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(),
                          ),
                          width: 75,
                          height: 100,
                          child: Provider.of<NewsProvider>(context).image ??
                              const Text(
                                "kein Foto gewählt",
                                textAlign: TextAlign.center,
                              ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: TextButton.icon(
                            onPressed: () {
                              Provider.of<NewsProvider>(context, listen: false)
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
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 30),
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                        });

                        final responseStatusCode =
                            await Provider.of<NewsProvider>(context,
                                    listen: false)
                                .postNews();
                        setState(() {
                          _isLoading = false;
                        });

                        showSnackBar(responseStatusCode);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: double.infinity,
                        height: 50,
                        child: const Text(
                          "News Hochladen",
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
