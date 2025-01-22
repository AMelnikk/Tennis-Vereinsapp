import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdfrx/pdfrx.dart';
import '../widgets/verein_appbar.dart';

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

  Future<String> downloadPdf() async {
    try {
      ByteData bytes = await rootBundle.load(widget.assetPath);
      Uint8List list = bytes.buffer.asUint8List();
      var directory = io.Directory("/storage/emulated/0/Download");
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

    exists = await io.File("/storage/emulated/0/Download/${widget.name}.pdf")
        .exists();
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
                            OpenFilex.open(
                                "/storage/emulated/0/Download/${widget.name}.pdf",
                                type: "application/pdf");
                          },
                          child: const Icon(Icons.open_in_new),
                        )
                      : FloatingActionButton(
                          onPressed: () {
                            downloadPdf().then(
                              (String path) {
                                setState(() {
                                  exists = true;
                                });
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    content: const Text(
                                        "Datei wurde erfolgreich in Downloads Ordner heruntergeladen"),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text("Ok"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          OpenFilex.open(path,
                                              type: "application/pdf");
                                        },
                                        child: const Text("Öffnen"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          child: const Icon(Icons.download),
                        ),
                )
              ],
            ),
    );
  }
}
