import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/season.dart';
import '../providers/season_provider.dart';
import '../providers/team_provider.dart';
import '../models/team.dart';

class AddMannschaftScreen extends StatefulWidget {
  static const routename = "/add_mannschaft_screen";

  const AddMannschaftScreen({super.key});

  @override
  State<AddMannschaftScreen> createState() => _AddMannschaftScreenState();
}

class _AddMannschaftScreenState extends State<AddMannschaftScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _pdfPath;
  Uint8List? _pdfBlob;
  String? _editingId;
  String _selectedMannschaft = "";
  String _selectedLiga = "";
  bool _isLoading = false;
  File? _selectedPhoto; // Die Variable, die das ausgewählte Foto speichert
  String _selectedSaisonKey = '';
  SaisonData? _selectedSaison;
  List<SaisonData> filterSeasons = [];

  final _controllers = <String, TextEditingController>{
    'url': TextEditingController(),
    'gruppe': TextEditingController(),
    'matchbilanz': TextEditingController(),
    'satzbilanz': TextEditingController(),
    'position': TextEditingController(),
    'kommentar': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSeasons();
    });
  }

  Future<void> _loadSeasons() async {
    final saisonProvider = Provider.of<SaisonProvider>(context, listen: false);
    try {
      final saisons = await saisonProvider.getAllSeasons();
      if (saisons.isNotEmpty) {
        setState(() {
          filterSeasons = saisons;
          _selectedSaisonKey = saisons.first.key;
          _selectedSaison = saisons.first;
        });
      }
    } catch (e) {
      _showWarning('Error loading seasons: $e');
    }
  }

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

    try {
      final provider = Provider.of<TeamProvider>(context, listen: false);

      final newEntry = Team(
        url: _controllers['url']?.text ?? '',
        saison: _selectedSaisonKey,
        mannschaft: _selectedMannschaft,
        liga: _selectedLiga,
        gruppe: _controllers['gruppe']?.text ?? '',
        matchbilanz: _controllers['matchbilanz']?.text ?? '',
        satzbilanz: _controllers['satzbilanz']?.text ?? '',
        position: _controllers['position']?.text ?? '',
        kommentar: _controllers['kommentar']?.text ?? '',
        pdfBlob: _pdfPath != null ? await _readPdfFile() : null,
      );

      await provider.addTeam(newEntry);
      await provider.getData(newEntry.saison); // Aktualisierte Daten abrufen
    } catch (error) {
      // Fehlerbehandlung: z.B. eine Snackbar anzeigen
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Fehler beim Speichern: ${error.toString()}')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
      _pdfBlob = null;
      _pdfPath = "";
      _selectedMannschaft = "";
      _selectedLiga = "";
    });
  }

  void _editEntry(Team entry) {
    if (_editingId != null) {
      _showWarning("Ein anderer Eintrag wird bereits bearbeitet.");
      return;
    }

    setState(() {
      _editingId = entry.mannschaft;
      _selectedSaisonKey = entry.saison;
      _selectedMannschaft = entry.mannschaft;
      _selectedLiga = entry.liga;
      _controllers['url']?.text = entry.url;
      _controllers['gruppe']?.text = entry.gruppe;
      _controllers['matchbilanz']?.text = entry.matchbilanz;
      _controllers['satzbilanz']?.text = entry.satzbilanz;
      _controllers['position']?.text = entry.position;
      _controllers['kommentar']?.text = entry.kommentar;
      _pdfBlob = null;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mannschaften verwalten"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Consumer2<TeamProvider, SaisonProvider>(
          builder: (context, provider, saisonProvider, child) {
            return FutureBuilder<List<SaisonData>>(
              future: saisonProvider.getAllSeasons(), // This returns a Future
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (!snapshot.hasData) {
                  return const Text('No seasons available');
                }

                return Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSaisonUndMannschaft(context),
                      const SizedBox(height: 5),
                      _buildLigaUndGruppe(),
                      const SizedBox(height: 5),
                      _buildMatchbilanzUndPosition(),
                      const SizedBox(height: 5),
                      _buildMannschaftsfuehrer(),
                      const SizedBox(height: 5),
                      _buildTextFormField('URL',
                          controller: _controllers['url']),
                      const SizedBox(height: 5),
                      _buildTextFormField('Kommentar',
                          controller: _controllers['kommentar']),
                      const SizedBox(height: 5),
                      _buildPhotoSelector(),
                      const SizedBox(height: 5),
                      _buildActionButtons(),
                      const SizedBox(height: 5),
                      // Wrap the table in a scrollable widget
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: _buildGameResultsTable(provider),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSaisonUndMannschaft(BuildContext context) {
    return FutureBuilder<List<SaisonData>>(
      future:
          Provider.of<SaisonProvider>(context, listen: false).getAllSeasons(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Ladeindikator
        }

        if (snapshot.hasError) {
          return Text('Fehler beim Laden der Saisons: ${snapshot.error}');
        }

        final List<SaisonData> seasons = snapshot.data ?? [];

        if (seasons.isEmpty) {
          return const Text('Keine Saisons verfügbar');
        }

        return Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: 'Saison',
                value: seasons.any((season) => season.key == _selectedSaisonKey)
                    ? _selectedSaisonKey
                    : seasons.first.key,
                items: seasons.map((season) => season.key).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSaisonKey = value);
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDropdownField(
                label: 'Mannschaft',
                value: _selectedMannschaft,
                items: _mannschaften,
                onChanged: (value) {
                  setState(() => _selectedMannschaft = value ?? '');
                },
              ),
            ),
          ],
        );
      },
    );
  }

// Methode für Liga & Gruppe Eingabe
  Widget _buildLigaUndGruppe() {
    return Row(
      children: [
        Expanded(
          child: _buildDropdownField(
            label: 'Liga',
            value: _selectedLiga,
            items: _ligen,
            onChanged: (value) => setState(() => _selectedLiga = value ?? ""),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildTextFormField('Gruppe',
              controller: _controllers['gruppe'], validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bitte die Gruppe eingeben';
            }
            return null;
          }),
        ),
      ],
    );
  }

// Methode für Matchbilanz, Satzbilanz & Position
  Widget _buildMatchbilanzUndPosition() {
    return Row(
      children: [
        Expanded(
            child: _buildTextFormField('Matchbilanz',
                controller: _controllers['matchbilanz'])),
        const SizedBox(width: 10),
        Expanded(
            child: _buildTextFormField('Satzbilanz',
                controller: _controllers['satzbilanz'])),
        const SizedBox(width: 10),
        Expanded(
            child: _buildTextFormField('Position',
                controller: _controllers['position'])),
      ],
    );
  }

// Methode für Mannschaftsführer Name & Telefonnummer
  Widget _buildMannschaftsfuehrer() {
    return Row(
      children: [
        Expanded(
            child: _buildTextFormField('Mannschaftsführer Name',
                controller: _controllers['mannschaftsführerName'])),
        const SizedBox(width: 10),
        Expanded(
            child: _buildTextFormField('Mannschaftsführer Telefonnummer',
                controller: _controllers['mannschaftsführerTel'])),
      ],
    );
  }

// Statische Listen für Dropdowns
  final List<String> _mannschaften = [
    "Herren",
    "Herren II",
    "Herren III",
    "Herren 30",
    "Herren 30 II",
    "Herren 40",
    "Herren 40 II",
    "Herren 50",
    "Damen",
    "Junioren",
    "Junioren II",
    "Knaben",
    "Knaben II",
    "Bambini",
    "Bambini II",
    "Bambini III",
    "Bambini IV",
    "U10",
    "U10 II",
    "U10 III",
    "U10 IV",
    "U9",
    "U9 II"
  ];

  final List<String> _ligen = [
    "Nordliga 4",
    "Nordliga 3",
    "Nordliga 2",
    "Nordliga 1",
    "Landesliga 2",
    "Landesliga 1"
  ];

  Widget _buildPhotoSelector() {
    return ElevatedButton(
      onPressed: () async {
        final ImagePicker picker = ImagePicker();
        final XFile? photo =
            await picker.pickImage(source: ImageSource.gallery);
        if (photo != null) {
          setState(() {
            _selectedPhoto = File(photo.path); // Hier wird das Bild gespeichert
          });
        }
      },
      child: const Text('Foto auswählen'),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 14), // Kleinere Schrift für das Label
        contentPadding: const EdgeInsets.symmetric(
            vertical: 0, horizontal: 0), // Weniger Padding
      ),
      value: value.isNotEmpty
          ? value
          : null, // Sicherstellen, dass null nicht zu Fehlern führt
      items: items.map<DropdownMenuItem<String>>((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(
                fontSize: 14), // Kleinere Schrift für Dropdown-Text
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Bitte eine Auswahl treffen';
        }
        return null;
      },
    );
  }

  Widget _buildTextFormField(
    String label, {
    required TextEditingController? controller,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 14), // Kleinere Schrift für das Label
      ),
      validator: validator,
    );
  }

  // Dein bereits definiertes Widget
  Widget _buildPdfSelector() {
    return Padding(
      padding: const EdgeInsets.only(top: 0.0),
      child: Row(
        children: [
          TextButton(
            onPressed: _pickPdfFile, // Hier rufst du _pickPdfFile auf
            child: const Text('PDF auswählen'),
          ),
          if (_pdfBlob != null) ...[
            Text(
              'PDF ausgewählt: ${_pdfPath!.split('/').last}', // Zeige den Dateinamen an
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // Diese Methode wird beim Drücken des Buttons aufgerufen
  void _pickPdfFile() async {
    // Wähle eine PDF-Datei aus
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // Nur PDF-Dateien erlauben
    );

    if (result != null && result.files.single.bytes != null) {
      // Lese die Datei als Uint8List (Blob)
      final fileBytes = result.files.single.bytes;

      setState(() {
        _pdfBlob = fileBytes; // Speichere das Blob
        // Optional: Speichere auch den Pfad, wenn du ihn benötigst
        _pdfPath = result.files.single.path;
      });
    } else {
      // Hier kannst du Fehlerbehandlung hinzufügen, falls keine Datei ausgewählt wurde
      print('Keine Datei ausgewählt oder Fehler beim Laden der Datei');
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

  Widget _buildGameResultsTable(TeamProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection:
            Axis.horizontal, // Horizontales Scrollen für kleine Geräte
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical, // Vertikales Scrollen hinzufügen
          child: FutureBuilder<List<Team>>(
            future: provider.getData(_selectedSaisonKey), // Daten abrufen
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
                        onPressed: () => provider
                            .getData(_selectedSaisonKey), // Daten erneut laden
                        child: const Text('Erneut versuchen'),
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Keine Einträge vorhanden.'));
              }

              final gameResults = snapshot.data!;
              return DataTable(
                columnSpacing:
                    15, // Reduzierte Spaltenabstände für kompaktere Darstellung
                columns: const [
                  DataColumn(
                      label: Text('Saison', style: TextStyle(fontSize: 16))),
                  DataColumn(
                      label:
                          Text('Mannschaft', style: TextStyle(fontSize: 16))),
                  DataColumn(
                      label: Text('Liga', style: TextStyle(fontSize: 16))),
                  DataColumn(
                      label: Text('Gruppe', style: TextStyle(fontSize: 16))),
                  DataColumn(
                      label:
                          Text('Matchbilanz', style: TextStyle(fontSize: 16))),
                  DataColumn(
                      label:
                          Text('Satzbilanz', style: TextStyle(fontSize: 16))),
                  DataColumn(
                      label: Text('Link', style: TextStyle(fontSize: 16))),
                  DataColumn(
                      label: Text('Aktionen', style: TextStyle(fontSize: 16))),
                ],
                rows: gameResults.map((entry) {
                  return DataRow(
                    cells: [
                      DataCell(Text(entry.saison,
                          style: const TextStyle(fontSize: 14))),
                      DataCell(Text(entry.mannschaft,
                          style: const TextStyle(fontSize: 14))),
                      DataCell(Text(entry.liga,
                          style: const TextStyle(fontSize: 14))),
                      DataCell(Text(entry.gruppe,
                          style: const TextStyle(fontSize: 14))),
                      DataCell(Text(entry.matchbilanz,
                          style: const TextStyle(fontSize: 14))),
                      DataCell(Text(entry.satzbilanz,
                          style: const TextStyle(fontSize: 14))),
                      DataCell(
                        GestureDetector(
                          onTap: () => _launchURL(entry.url), // URL öffnen
                          child: const Text(
                            'Link öffnen',
                            style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                fontSize: 12),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  size: 18), // Kleinere Icons
                              onPressed: () => _editEntry(entry), // Bearbeiten
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              onPressed: () async {
                                final confirmed =
                                    await _showDeleteConfirmation(context);

                                if (!mounted) {
                                  return; // Guard against async gaps
                                }

                                if (confirmed) {
                                  await provider.deleteTeam(entry.saison,
                                      entry.mannschaft); // Löschen
                                  if (!mounted) return; // Nochmal prüfen
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Eintrag gelöscht.'),
                                        backgroundColor: Colors.green),
                                  );
                                }
                                setState(() {
                                  provider
                                      .getData(entry.saison); // Daten neu laden
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
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
    } else {}
  }
}
