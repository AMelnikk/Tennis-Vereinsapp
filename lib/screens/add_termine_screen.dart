import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/termine_provider.dart';
import '../widgets/verein_appbar.dart';

class AddTermineScreen extends StatefulWidget {
  const AddTermineScreen({super.key});
  static const routename = "/add-termine-screen";

  @override
  State<AddTermineScreen> createState() => _AddTermineScreenState();
}

class _AddTermineScreenState extends State<AddTermineScreen> {
  bool _isLoading = false;

  Future<void> importExcelAndSaveToFirebase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Datei auswählen
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        final bytes = file.readAsBytesSync();

        // Excel einlesen
        var excel = Excel.decodeBytes(bytes);
        final List<Map<String, dynamic>> termine = [];

        // Sicherstellen, dass Tabellen vorhanden sind
        if (excel.tables.isNotEmpty) {
          var rows = excel.tables.values.first.rows;

          // Überschrift auslassen, ab Zeile 2 (Index 1) starten
          for (var row in rows.skip(1)) {
            // Sicherstellen, dass die Zeile mindestens 3 Spalten hat
            if (row.length >= 3) {
              // ID als Integer parsen
              final idString = row[0]?.value?.toString();
              final datumString = row[1]?.value?.toString();
              final ereignis = row[2]?.value?.toString() ?? '';

              // Prüfen, ob die Werte gültig sind
              if (idString != null &&
                  datumString != null &&
                  ereignis.isNotEmpty) {
                final id = int.tryParse(idString) ?? -1;
                final datum = DateTime.tryParse(datumString);

                if (id > 0 && datum != null) {
                  termine.add({
                    "id": id,
                    "datum": datum,
                    "ereignis": ereignis,
                  });
                }
              }
            }
          }
        }

        // Daten an den TermineProvider senden
        if (termine.isNotEmpty) {
          await Provider.of<TermineProvider>(context, listen: false)
              .saveTermineToFirebase(termine);

          if (mounted) {
            showSnackBar("Termine erfolgreich hochgeladen!");
          }
        } else {
          if (mounted) {
            showSnackBar("Keine gültigen Termine gefunden.");
          }
        }
      } else {
        if (mounted) {
          showSnackBar("Keine Datei ausgewählt.");
        }
      }
    } catch (error) {
      if (mounted) {
        showSnackBar("Fehler: $error");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

// Define the showSnackBar method to display messages
  void showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
                      "Termine aus Excel importieren",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 30),
                      child: ElevatedButton(
                        onPressed: importExcelAndSaveToFirebase,
                        child: Container(
                          alignment: Alignment.center,
                          width: double.infinity,
                          height: 50,
                          child: const Text(
                            "Excel-Datei importieren",
                            style: TextStyle(fontSize: 20),
                          ),
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
