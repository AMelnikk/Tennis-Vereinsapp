import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:verein_app/popUps/pdf_download_popup.dart';
//import 'package:share_plus/share_plus.dart';
import '../widgets/verein_appbar.dart';
import 'package:open_filex/open_filex.dart';

class PdfScreen extends StatefulWidget {
  const PdfScreen({super.key, required this.assetPath, required this.name});
  static const routename = "/pdf-view-screen";

  final String name;
  final String assetPath;

  @override
  State<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen> {
  late bool exists;
  bool _isLoading = false;
  late String downloadPath;

  Future<String> downloadPdf() async {
    try {
      ByteData bytes = await rootBundle.load(widget.assetPath);
      Uint8List list = bytes.buffer.asUint8List();
      io.Directory? directory;
      if (io.Platform.isAndroid) {
        directory = io.Directory("/storage/emulated/0/Download");
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      var path = "${directory.path}/${widget.name}.pdf";
      final file = io.File(path);
      file.writeAsBytes(list);
      if (kDebugMode) {
        print(
            "succesfully downloaded the file ${widget.name}.pdf to ${directory.path}");
      }
      return path;
    } catch (e) {
      if (kDebugMode) print(e);
      return "";
    }
  }

  Future<void> fileExists() async {
    setState(() {
      _isLoading = true;
    });

    // Hinzufügen der Plattformprüfung für Web
    if (kIsWeb) {
      // Im Web existieren lokale Dateien dieser Art nicht.
      // Wir setzen exists auf false und beenden die Funktion.
      exists = false;
      downloadPath = '';
      setState(() {
        _isLoading = false;
      });
      return; // WICHTIG: Hier verlassen wir die Funktion.
    }

    // --- NATIVE PLATTFORM LOGIK (Android, iOS) ---
    if (io.Platform.isAndroid) {
      exists = await io.File("/storage/emulated/0/Download/${widget.name}.pdf")
          .exists();
      downloadPath = "/storage/emulated/0/Download/${widget.name}.pdf";
      // print('android pdf exist path: /storage/emulated/0/Download/${widget.name}.pdf');
    } else {
      // Dies deckt iOS und andere Native OS ab
      var dir = await getApplicationDocumentsDirectory();
      exists = await io.File("${dir.path}/${widget.name}.pdf").exists();
      downloadPath = "${dir.path}/${widget.name}.pdf";
      // print('ios pdf exist path: ${dir.path}/${widget.name}.pdf');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    fileExists();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VereinAppbar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                PdfViewer.asset(widget.assetPath),
                Container(
                  margin: const EdgeInsets.all(5),
                  alignment: Alignment.bottomRight,
                  child: exists
                      ? FloatingActionButton(
                          onPressed: () {
                            OpenFilex.open(downloadPath,
                                type: "application/pdf");
                          },
                          child: const Icon(Icons.open_in_new),
                        )
                      : FloatingActionButton(
                          onPressed: () async {
                            String path = await downloadPdf();
                            setState(() {
                              exists = true;
                            });

                            // Nun sicherstellen, dass der BuildContext noch verfügbar ist, bevor er verwendet wird
                            if (mounted) {
                              if (!context.mounted) return;
                              // Hier prüfen wir explizit, ob der Navigator noch verwendet werden kann
                              if (!Navigator.canPop(context)) return;

                              // Zeige Dialog nur, wenn der Widget-Context noch verfügbar ist
                              showDownloadDialog(
                                  context, path); // Dialog sicher anzeigen
                            }
                          },
                          child: const Icon(Icons.download),
                        ),
                )
              ],
            ),
    );
  }
}
