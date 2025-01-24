import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/game_results_provider.dart';
import '../models/game_result.dart';

class AddMannschaftScreen extends StatefulWidget {
  static const routename = "/add_mannschaft_screen";

  const AddMannschaftScreen({super.key});

  @override
  State<AddMannschaftScreen> createState() => _AddMannschaftScreenState();
}

class _AddMannschaftScreenState extends State<AddMannschaftScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{
    'url': TextEditingController(),
    'gruppe': TextEditingController(),
    'matchbilanz': TextEditingController(),
    'satzbilanz': TextEditingController(),
    'position': TextEditingController(),
    'kommentar': TextEditingController(),
  };

  String? _pdfPath;
  String? _editingId;
  String _selectedSaison = "Sommer 2024";
  String _selectedMannschaft = "Herren I";
  String _selectedLiga = "Nordliga 4";
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveEntry() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<GameResultsProvider>(context, listen: false);
    final newEntry = GameResult(
      id: _editingId ?? DateTime.now().toIso8601String(),
      url: _controllers['url']?.text ?? '',
      saison: _selectedSaison,
      mannschaft: _selectedMannschaft,
      liga: _selectedLiga,
      gruppe: _controllers['gruppe']?.text ?? '',
      matchbilanz: _controllers['matchbilanz']?.text ?? '',
      satzbilanz: _controllers['satzbilanz']?.text ?? '',
      position: _controllers['position']?.text ?? '',
      kommentar: _controllers['kommentar']?.text ?? '',
      pdfBlob: _pdfPath != null ? await _readPdfFile() : null,
    );

    await provider.addGameResult(newEntry); // Daten hinzufügen

    setState(() {
      _isLoading = false;
    });

    // Nachdem das Ergebnis hinzugefügt wurde, rufe `getData` erneut auf.
    await provider.getData(); // Manuelles Laden der neuen Daten
  }

  Future<Uint8List?> _readPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    return result.files.single.bytes;
  }

  void _clearForm() {
    setState(() {
      _editingId = null;
      _controllers.forEach((key, controller) => controller.clear());
      _pdfPath = null;
      _selectedSaison = "Sommer 2024";
      _selectedMannschaft = "Herren I";
      _selectedLiga = "Nordliga 4";
    });
  }

  void _editEntry(GameResult entry) {
    if (_editingId != null) {
      _showWarning("Ein anderer Eintrag wird bereits bearbeitet.");
      return;
    }

    setState(() {
      _editingId = entry.id;
      _selectedSaison = entry.saison;
      _selectedMannschaft = entry.mannschaft;
      _selectedLiga = entry.liga;
      _controllers['url']?.text = entry.url;
      _controllers['gruppe']?.text = entry.gruppe;
      _controllers['matchbilanz']?.text = entry.matchbilanz;
      _controllers['satzbilanz']?.text = entry.satzbilanz;
      _controllers['position']?.text = entry.position;
      _controllers['kommentar']?.text = entry.kommentar;
      _pdfPath = null;
    });
  }

  void _showWarning(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Warnung"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameResultsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mannschaften verwalten"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDropdownField(
                label: 'Saison',
                value: _selectedSaison,
                items: ["Sommer 2024", "Winter 24/25", "Sommer 2025"],
                onChanged: (value) => setState(() => _selectedSaison = value!),
              ),
              _buildDropdownField(
                label: 'Mannschaft',
                value: _selectedMannschaft,
                items: [
                  "Herren I",
                  "Herren II",
                  "Herren III",
                  "Herren 30 I",
                  "Herren 30 II",
                  "Herren 40 I",
                  "Herren 40 II",
                  "Herren 50 I",
                  "Damen I",
                  "Junioren I",
                  "Junioren II",
                  "Knaben I",
                  "Knaben II",
                  "Bambini I",
                  "Bambini II",
                  "Bambini III",
                  "Bambini IV",
                  "U10 I",
                  "U10 II",
                  "U10 III",
                  "U10 IV",
                  "U9 I",
                  "U9 II"
                ],
                onChanged: (value) =>
                    setState(() => _selectedMannschaft = value!),
              ),
              _buildDropdownField(
                label: 'Liga',
                value: _selectedLiga,
                items: [
                  "Nordliga 4",
                  "Nordliga 3",
                  "Nordliga 2",
                  "Nordliga 1",
                  "Landesliga 2",
                  "Landesliga 1"
                ],
                onChanged: (value) => setState(() => _selectedLiga = value!),
              ),
              _buildTextFormField('URL', controller: _controllers['url']),
              _buildTextFormField('Gruppe', controller: _controllers['gruppe'],
                  validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bitte die Gruppe eingeben';
                }
                return null;
              }),
              _buildTextFormField('Matchbilanz',
                  controller: _controllers['matchbilanz']),
              _buildTextFormField('Satzbilanz',
                  controller: _controllers['satzbilanz']),
              _buildTextFormField('Position',
                  controller: _controllers['position']),
              _buildTextFormField('Kommentar',
                  controller: _controllers['kommentar']),
              _buildPdfSelector(),
              _buildActionButtons(),
              _buildGameResultsTable(provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTextFormField(
    String label, {
    required TextEditingController? controller,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: validator,
    );
  }

  Widget _buildPdfSelector() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Row(
        children: [
          TextButton(
            onPressed: _pickPdfFile,
            child: const Text('PDF auswählen'),
          ),
          if (_pdfPath != null) ...[
            Text(
              'PDF ausgewählt: ${_pdfPath!.split('/').last}',
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _pdfPath = result.files.single.path;
      });
    }
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _isLoading ? null : _saveEntry,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Speichern'),
          ),
          ElevatedButton(
            onPressed: _clearForm,
            child: const Text('Zurücksetzen'),
          ),
        ],
      ),
    );
  }

  Widget _buildGameResultsTable(GameResultsProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection:
            Axis.horizontal, // Horizontales Scrollen für kleine Geräte
        child: FutureBuilder<List<GameResult>>(
          future: provider.getData(), // Daten abrufen
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator()); // Ladeindikator
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Fehler: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => provider.getData(), // Daten erneut laden
                      child: const Text('Erneut versuchen'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Keine Einträge vorhanden.'));
            } else {
              final gameResults = snapshot.data!;
              return DataTable(
                columns: const [
                  DataColumn(label: Text('Saison')),
                  DataColumn(label: Text('Mannschaft')),
                  DataColumn(label: Text('Gruppe')),
                  DataColumn(label: Text('Matchbilanz')),
                  DataColumn(label: Text('Satzbilanz')),
                  DataColumn(label: Text('Link')),
                  DataColumn(label: Text('Aktionen')),
                ],
                rows: gameResults.map((entry) {
                  return DataRow(
                    cells: [
                      DataCell(Text(entry.saison)),
                      DataCell(Text(entry.mannschaft)),
                      DataCell(Text(entry.gruppe)),
                      DataCell(Text(entry.matchbilanz)),
                      DataCell(Text(entry.satzbilanz)),
                      DataCell(
                        GestureDetector(
                          onTap: () => _launchURL(entry.url), // URL öffnen
                          child: Text(
                            'Link öffnen',
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editEntry(entry), // Bearbeiten
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final confirmed =
                                    await _showDeleteConfirmation(ctx);
                                if (confirmed) {
                                  provider
                                      .deleteGameResult(entry.id); // Löschen
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text('Eintrag gelöscht.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              );
            }
          },
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Eintrag löschen'),
            content: const Text('Möchten Sie diesen Eintrag wirklich löschen?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Löschen'),
              ),
            ],
          ),
        ) ??
        false; // Default false, falls Dialog abgebrochen wird
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print('Fehler: URL konnte nicht geöffnet werden: $url');
    }
  }
}
