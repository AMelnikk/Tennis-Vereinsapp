import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class MfSelectionDialog extends StatefulWidget {
  final Map<String, String> userMap;

  // ✅ KORREKTUR: Verwendung des Super-Parameters 'super.key'
  const MfSelectionDialog({
    super.key, // Ersetzt Key? key und die Zuweisung : super(key: key)
    required this.userMap,
  });
  @override
  MfSelectionDialogState createState() => MfSelectionDialogState();
}

class MfSelectionDialogState extends State<MfSelectionDialog> {
  String? _selectedUid;

  @override
  void initState() {
    super.initState();
    // Setzt den 'Keine Auswahl'-Platzhalter als Standard (wird als key='' gespeichert)
    _selectedUid = widget.userMap.keys.firstWhereOrNull((key) => key.isEmpty) ??
        widget.userMap.keys.first;
  }

  @override
  Widget build(BuildContext context) {
    // Sortiere Benutzer nach Namen für bessere Übersichtlichkeit
    final sortedEntries = widget.userMap.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Den 'Manuell eingeben'-Eintrag (key='') nach vorne verschieben
    final placeholder = sortedEntries.firstWhereOrNull((e) => e.key == '');
    if (placeholder != null) {
      sortedEntries.remove(placeholder);
      sortedEntries.insert(0, placeholder);
    }

    return AlertDialog(
      title: const Text('Mannschaftsführer auswählen'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        // Höhenbeschränkung, damit es nicht den gesamten Bildschirm einnimmt
        height: MediaQuery.of(context).size.height * 0.6,
        child: ListView.builder(
          itemCount: sortedEntries.length,
          itemBuilder: (context, index) {
            final entry = sortedEntries[index];
            final isSelected = _selectedUid == entry.key;

            return ListTile(
              title: Text(
                entry.value,
                style: TextStyle(
                    fontWeight: entry.key.isEmpty
                        ? FontWeight.bold
                        : FontWeight.normal),
              ),
              // Zeigt die UID nur an, wenn es kein Platzhalter ist
              subtitle: entry.key.isNotEmpty ? Text('UID: ${entry.key}') : null,
              selected: isSelected,
              onTap: () {
                setState(() {
                  _selectedUid = entry.key;
                });
              },
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(), // Schließen ohne Auswahl
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _selectedUid == null
              ? null
              : () {
                  final selectedEntry =
                      sortedEntries.firstWhere((e) => e.key == _selectedUid);
                  // Rückgabe des MapEntry (UID, Name) an den aufrufenden Dialog
                  Navigator.of(context).pop(selectedEntry);
                },
          child: const Text('Übernehmen'),
        ),
      ],
    );
  }
}
