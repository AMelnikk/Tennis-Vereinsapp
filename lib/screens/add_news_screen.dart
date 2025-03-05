import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_utils.dart';
import '../widgets/build_photo_selector.dart';
import '../providers/news_provider.dart';
import '../widgets/verein_appbar.dart';
import 'package:intl/intl.dart'; // Für das Formatieren des Datums

class AddNewsScreen extends StatefulWidget {
  const AddNewsScreen({super.key});

  static const routename = "/add-news-screen";

  @override
  State<AddNewsScreen> createState() => _AddNewsScreenState();
}

class _AddNewsScreenState extends State<AddNewsScreen> {
  bool _isLoading = false;
  final TextEditingController categoryController = TextEditingController();
  bool isCustomCategory =
      false; // Falls der Nutzer eine eigene Kategorie eingibt

  // Methode zum Öffnen des DatePickers
  Future<void> _selectDate(NewsProvider np, BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale("de", "DE"), // Deutsch
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            hintColor: Colors.blue,
            colorScheme: const ColorScheme.light(primary: Colors.blue),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        np.newsDateController.text =
            DateFormat("dd.MM.yyyy", "de_DE").format(pickedDate);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (!mounted) {
        return; // Verhindert Fehler, falls das Widget entfernt wurde
      }
      final newsProvider = Provider.of<NewsProvider>(context, listen: false);

      if (newsProvider.newsId.isNotEmpty) {
        newsProvider.loadNews(newsProvider.newsId);
      } else {
        final today = DateFormat('dd.MM.yyyy').format(DateTime.now());
        newsProvider
          ..newsId = ''
          ..newsDateController.text = today
          ..updateCategory("Allgemein")
          ..body.text = ''
          ..photoBlob = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final newsProvider = Provider.of<NewsProvider>(context);
    final authProvider =
        Provider.of<AuthorizationProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    return Scaffold(
      appBar: VereinAppbar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text("News hinzufügen", style: TextStyle(fontSize: 20)),

                  // Datum Eingabefeld
                  TextFormField(
                    controller: newsProvider.newsDateController,
                    decoration: const InputDecoration(
                      labelText: "Datum",
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(newsProvider, context),
                  ),

                  // Titel Eingabefeld mit externer Methode
                  buildTextFormField(
                    "Titel",
                    controller: newsProvider.title,
                  ),

                  // Textfeld für Body mit externer Methode
                  buildTextFieldScrollable("Text",
                      controller: newsProvider.body),

                  // Dropdown für Kategorie mit externer Methode
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildDropdownField(
                          label: "Kategorie",
                          value: isCustomCategory
                              ? ""
                              : newsProvider.selectedCategory,
                          items: [
                            ...newsProvider.categories,
                            "Andere",
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              if (newValue == "Andere") {
                                isCustomCategory = true;
                                newsProvider.updateCategory("");
                              } else {
                                isCustomCategory = false;
                                newsProvider.updateCategory(newValue!);
                              }
                            });
                          },
                        ),
                        if (isCustomCategory)
                          buildTextFormField(
                            "Eigene Kategorie",
                            controller: categoryController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Bitte eine Kategorie eingeben";
                              }
                              return null;
                            },
                          ),
                      ],
                    ),
                  ),

                  // Fotoauswahl
                  PhotoSelector(
                    onImagesSelected: (List<String> images) {
                      setState(() {
                        newsProvider.photoBlob = images;
                      });
                    },
                  ),

                  // Button zum Hochladen
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() => _isLoading = true);

                        String newsId = await newsProvider.postNews(
                          newsProvider.newsId,
                          authProvider.userId.toString(),
                        );

                        setState(() => _isLoading = false);

                        messenger.showSnackBar(
                          const SnackBar(
                              content: Text("News erfolgreich hochgeladen!")),
                        );

                        if (!mounted) return;

                        if (newsId.isNotEmpty) {
                          Navigator.pop(context, newsId);
                        }
                      },
                      child: const Text("News Hochladen"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
