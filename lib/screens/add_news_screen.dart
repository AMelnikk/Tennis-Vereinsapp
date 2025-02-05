import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
            colorScheme: ColorScheme.light(primary: Colors.blue),
            dialogBackgroundColor: Colors.white,
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
  Widget build(BuildContext context) {
    final newsProvider = Provider.of<NewsProvider>(context);
    final messenger = ScaffoldMessenger.of(context);

    return Scaffold(
      appBar: VereinAppbar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text("News hinzufügen",
                        style: TextStyle(fontSize: 20)),

                    // Datum Eingabefeld
                    TextFormField(
                      controller: newsProvider.newsDateController,
                      decoration: const InputDecoration(
                        labelText: "Datum",
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly:
                          true, // Nur Lesezugriff, um den Kalender zu verwenden
                      onTap: () => _selectDate(
                          newsProvider, context), // Kalender öffnen bei Klick
                    ),

                    // Titel Eingabefeld
                    TextFormField(
                      decoration: const InputDecoration(label: Text("Titel")),
                      controller: newsProvider.title,
                      style: const TextStyle(color: Colors.grey),
                    ),

                    // Textfeld für Body
                    TextFormField(
                      decoration: const InputDecoration(label: Text("Text")),
                      controller: newsProvider.body,
                      maxLines: 5,
                      style: const TextStyle(color: Colors.grey),
                    ),

                    // Dropdown für Kategorie
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Kategorie:",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          DropdownButton<String>(
                            value: isCustomCategory
                                ? null
                                : newsProvider.selectedCategory,
                            items:
                                newsProvider.categories.map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }).toList()
                                  ..add(
                                    const DropdownMenuItem<String>(
                                      value: "Andere",
                                      child: Text("Andere (bitte eingeben)"),
                                    ),
                                  ),
                            onChanged: (String? newValue) {
                              if (newValue == "Andere") {
                                setState(() {
                                  isCustomCategory = true;
                                  newsProvider.updateCategory("");
                                });
                              } else {
                                setState(() {
                                  isCustomCategory = false;
                                  newsProvider.updateCategory(newValue!);
                                });
                              }
                            },
                          ),
                          if (isCustomCategory)
                            TextFormField(
                              controller: categoryController,
                              decoration: const InputDecoration(
                                  label: Text("Eigene Kategorie")),
                              onChanged: (value) {
                                newsProvider.updateCategory(value);
                              },
                            ),
                        ],
                      ),
                    ),

                    // Bild-Auswahl
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 80, // Kleinere Vorschau
                              child: newsProvider.photoBlob.isEmpty
                                  ? const Center(
                                      child: Text("Keine Bilder ausgewählt"))
                                  : ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: newsProvider.photoBlob.length,
                                      itemBuilder: (context, index) {
                                        final imageBytes = base64Decode(
                                            newsProvider.photoBlob[index]);

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.memory(
                                              imageBytes,
                                              fit: BoxFit.cover,
                                              width: 80,
                                              height: 80,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              await newsProvider.pickAndUploadImages(
                                  messenger); // Bilder auswählen und speichern
                              setState(
                                  () {}); // UI aktualisieren, um die neuen Bilder sofort anzuzeigen
                            },
                            icon: const Icon(Icons.photo),
                            label: const Text("Fotos wählen",
                                style: TextStyle(fontSize: 20)),
                          ),
                        ],
                      ),
                    ),

                    // Button zum Hochladen
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: ElevatedButton(
                        onPressed: () async {
                          setState(() => _isLoading = true);
                          await newsProvider.postNews();
                          setState(() => _isLoading = false);
                          messenger.showSnackBar(const SnackBar(
                              content: Text("News erfolgreich hochgeladen!")));
                        },
                        child: Container(
                          alignment: Alignment.center,
                          width: double.infinity,
                          height: 50,
                          child: const Text("News Hochladen",
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
