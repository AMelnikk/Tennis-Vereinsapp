import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

void showDownloadDialog(BuildContext context, String path) {
  // Guard für den BuildContext
  if (Navigator.canPop(context)) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Text("Datei wurde erfolgreich heruntergeladen"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text("Ok"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              OpenFilex.open(path, type: "application/pdf");
            },
            child: const Text("Öffnen"),
          ),
        ],
      ),
    );
  }
}
