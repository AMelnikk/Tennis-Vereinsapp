import 'package:flutter/foundation.dart';
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        var bytes = result.files.single.bytes;

        if (bytes != null) {
          var excel = Excel.decodeBytes(bytes);
          final List<Map<String, dynamic>> termine = [];

          if (excel.tables.isNotEmpty) {
            var rows = excel.tables.values.first.rows;

            for (var row in rows.skip(1)) {
              if (row.length >= 3) {
                final idString = row[0]?.value?.toString();
                final datumString = row[1]?.value?.toString();
                final ereignis = row[2]?.value?.toString() ?? '';
                final kategorie = row[3]?.value?.toString() ?? '';
                final details = row[4]?.value?.toString() ?? '';
                final abfrage = row[5]?.value?.toString() ?? '';

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
                      "kategorie": kategorie,
                      "details": details,
                      "abfrage": abfrage,
                    });
                  }
                }
              }
            }
          }

          if (termine.isNotEmpty) {
            if (mounted) {
              await Provider.of<TermineProvider>(context, listen: false)
                  .saveTermineToFirebase(termine);
              showSnackBar("Termine erfolgreich hochgeladen!");
            }
          } else {
            showSnackBar("Keine gültigen Termine gefunden.");
          }
        } else {
          showSnackBar("Fehler beim Lesen der Datei.");
        }
      } else {
        showSnackBar("Keine Datei ausgewählt.");
      }
    } catch (error, stackTrace) {
      if (kDebugMode) print("Error: $error");
      if (kDebugMode) print("StackTrace: $stackTrace");
      showSnackBar("Fehler: $error");
    } finally {
      setState(() {
        _isLoading = false;
      });
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
