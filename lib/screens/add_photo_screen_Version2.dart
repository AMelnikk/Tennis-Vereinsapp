import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/image_helper.dart';
import '../providers/photo_provider_Version2.dart';
import '../widgets/verein_appbar.dart';
import 'package:intl/intl.dart'; // Für das Formatieren des Datums

class AddPhotoScreen extends StatefulWidget {
  const AddPhotoScreen({super.key});
  static const routename = "/add-photo-screen";

  @override
  State<AddPhotoScreen> createState() => _AddPhotoScreenState();
}

class _AddPhotoScreenState extends State<AddPhotoScreen> {
  bool _isLoading = false;
  final TextEditingController categoryController = TextEditingController();

  // Methode zum Öffnen des DatePickers
  Future<void> _selectDate(PhotoProvider pp, BuildContext context) async {
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
        pp.photoDateController.text =
            DateFormat("dd.MM.yyyy", "de_DE").format(pickedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoProvider = Provider.of<PhotoProvider>(context);
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
                    const Text("Fotos Hinzufügen",
                        style: TextStyle(fontSize: 20)),

                    // Datum Eingabefeld (Datumspicker)
                    TextFormField(
                      controller: photoProvider.photoDateController,
                      decoration: const InputDecoration(
                        labelText: "Datum",
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly:
                          true, // Nur Lesezugriff, um den Kalender zu verwenden
                      onTap: () => _selectDate(photoProvider, context),
                    ),

                    // Textfeld für Kategorie
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Kategorie:",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          TextFormField(
                            controller: categoryController,
                            decoration: const InputDecoration(
                              labelText: 'Gib eine Kategorie ein',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              // Hier wird die Kategorie im Provider aktualisiert
                              photoProvider.updateCategory(value);
                            },
                          ),
                        ],
                      ),
                    ),

                    // Anzeige der hochgeladenen Bilder
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Hochgeladene Bilder:",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(
                            height: 100,
                            child: photoProvider.currentCategoryPhotos.isEmpty
                                ? const Center(
                                    child:
                                        Text("Noch keine Bilder hochgeladen"))
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: photoProvider
                                        .currentCategoryPhotos.length,
                                    itemBuilder: (context, index) {
                                      final imageBytes = base64Decode(
                                          photoProvider
                                              .currentCategoryPhotos[index]);
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
                          )
                        ],
                      ),
                    ),

                    // Bild-Auswahl
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              photoProvider.currentCategoryPhotos =
                                  await pickImages(
                                      messenger); // Bilder auswählen und speichern
                              setState(() {
                                // UI aktualisieren, um die neuen Bilder sofort anzuzeigen
                              });
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
                          await photoProvider
                              .postImages(photoProvider.category);
                          setState(() => _isLoading = false);
                          messenger.showSnackBar(const SnackBar(
                              content: Text("Fotos erfolgreich hochgeladen!")));
                        },
                        child: Container(
                          alignment: Alignment.center,
                          width: double.infinity,
                          height: 50,
                          child: const Text("Fotos Hochladen",
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
