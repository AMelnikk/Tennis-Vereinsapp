import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:verein_app/utils/app_utils.dart';
import '../models/calendar_event.dart';
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
    final messenger = ScaffoldMessenger.of(context); // Vorher speichern
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
          final List<CalendarEvent> termine = []; // Liste vom Typ CalendarEvent

          if (excel.tables.isNotEmpty) {
            var rows = excel.tables.values.first.rows;

            for (var row in rows.skip(1)) {
              // Erste Zeile überspringen (Überschriften)
              if (row.length >= 5) {
                // Überprüfen, ob genügend Spalten vorhanden sind
                final datumString = row[0]?.value?.toString() as String;
                final title = row[1]?.value?.toString() ?? '';
                final category = row[2]?.value?.toString() ?? '';
                final details = row[3]?.value?.toString() ?? '';
                final query = row[4]?.value?.toString() ?? '';

                final datum = DateTime.tryParse(datumString);

                if (datum != null) {
                  // Umwandeln in CalendarEvent
                  termine.add(CalendarEvent(
                    id: 0,
                    date: datum,
                    title: title,
                    description: details,
                    category: category,
                    query: query,
                  ));
                } else {
                  appError(
                      messenger, "Ungültige ID oder Datum in der Zeile: $row");
                }
              } else {
                appError(messenger,
                    "Ungültige Zeile: Es werden die Spalten Datum, Titel, Kategorie, Details und Abfrage (ja/nein) erwartet.");
              }
            }
          }

          if (termine.isNotEmpty) {
            // Termine werden hier gespeichert
            if (mounted) {
              await Provider.of<TermineProvider>(context, listen: false)
                  .saveTermineToFirebase(termine);
            }
            appError(messenger, "Termine erfolgreich hochgeladen!");
          } else {
            appError(messenger, "Keine gültigen Termine gefunden.");
          }
        } else {
          appError(messenger, "Fehler beim Lesen der Datei.");
        }
      } else {
        appError(messenger, "Keine Datei ausgewählt.");
      }
    } catch (error, stackTrace) {
      debugPrint("Error: $error");
      debugPrint("StackTrace: $stackTrace");
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
