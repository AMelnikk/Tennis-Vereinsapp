import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/ligaspiele_provider.dart';
import '../widgets/verein_appbar.dart';

class AddLigaSpieleScreen extends StatefulWidget {
  const AddLigaSpieleScreen({super.key});
  static const routename = "/add-liga-spiele-screen";

  @override
  State<AddLigaSpieleScreen> createState() => _AddLigaSpieleScreenState();
}

class _AddLigaSpieleScreenState extends State<AddLigaSpieleScreen> {
  bool _isLoading = false;

  Future<void> importCsvAndSaveToFirebase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        List<Map<String, dynamic>> spiele = [];

        if (kIsWeb || result.files.single.bytes != null) {
          // Web oder Bytes-Modus
          Uint8List? fileBytes = result.files.single.bytes;
          if (fileBytes != null) {
            // Wenn BOM vorhanden ist, wird es entfernt
            String csvString = utf8.decode(fileBytes, allowMalformed: true);
            if (csvString.startsWith("\u{FEFF}")) {
              // Entferne das BOM (Byte Order Mark)
              csvString = csvString.substring(1);
            }
            spiele = _parseCsv(csvString); // Parse the CSV string
          }
        }

        if (spiele.isNotEmpty) {
          if (mounted) {
            await Provider.of<LigaSpieleProvider>(context, listen: false)
                .saveLigaSpiele(spiele);
            showSnackBar("Spiele erfolgreich hochgeladen!");
          }
        } else {
          showSnackBar("Keine gültigen Spiele gefunden.");
        }
      } else {
        showSnackBar("Keine Datei ausgewählt.");
      }
    } catch (error) {
      showSnackBar("Fehler: $error");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _parseCsv(String csvString) {
    List<Map<String, dynamic>> spiele = [];
    List<String> lines = csvString.split('\n');

    // Loop through the lines and parse each line
    for (var i = 1; i < lines.length; i++) {
      List<String> fields = lines[i].split(';');
      if (fields.length >= 10) {
        spiele.add({
          "id": fields[8],
          "datum": fields[0],
          "uhrzeit": fields[1],
          "altersklasse": fields[2],
          "spielklasse": fields[3],
          "gruppe": fields[5],
          "heim": fields[6],
          "gast": fields[7],
          "spielort": fields[9],
        });
      }
    }

    return spiele;
  }

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
                      "Liga-Spiele aus CSV importieren",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 30),
                      child: ElevatedButton(
                        onPressed: importCsvAndSaveToFirebase,
                        child: Container(
                          alignment: Alignment.center,
                          width: double.infinity,
                          height: 50,
                          child: const Text(
                            "CSV-Datei importieren",
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
