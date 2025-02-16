import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/season.dart';
import '../models/team.dart';
import '../providers/team_provider.dart';
import '../utils/app_utils.dart';
import '../utils/pdf_helper.dart';
import '../widgets/build_photo_selector.dart';

class MyTeamDialog extends StatefulWidget {
  final List<SaisonData> seasons;
  final Team? teamData;

  const MyTeamDialog({super.key, required this.seasons, this.teamData});

  @override
  _MyTeamDialogState createState() => _MyTeamDialogState();
}

class _MyTeamDialogState extends State<MyTeamDialog> {
  final _formKey = GlobalKey<FormState>();

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
    "Junioren 18",
    "Junioren 18 II",
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

  String? _pdfPath;
  Uint8List? _pdfBlob;
  String _editingId = '';
  String _selectedMannschaft = "";
  String _selectedLiga = "";
  bool _isLoading = false;
  List<String> _photoBlob = [];
  String _selectedSaisonKey = '';
  String _selectedPdfPath = '';

  final _controllers = <String, TextEditingController>{
    'url': TextEditingController(),
    'gruppe': TextEditingController(),
    'matchbilanz': TextEditingController(),
    'mannschaftsführerName': TextEditingController(),
    'mannschaftsführerTel': TextEditingController(),
    'satzbilanz': TextEditingController(),
    'position': TextEditingController(),
    'kommentar': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    if (widget.teamData != null) {
      _editingId = widget.teamData!.mannschaft;
      _selectedSaisonKey = widget.teamData!.saison;
      _selectedMannschaft = widget.teamData!.mannschaft;
      _selectedLiga = widget.teamData!.liga;
      _controllers['url']?.text = widget.teamData!.url;
      _controllers['gruppe']?.text = widget.teamData!.gruppe;
      _controllers['matchbilanz']?.text = widget.teamData!.matchbilanz;
      _controllers['satzbilanz']?.text = widget.teamData!.satzbilanz;
      _controllers['position']?.text = widget.teamData!.position;
      _controllers['kommentar']?.text = widget.teamData!.kommentar;
      _controllers['mannschaftsführerName']?.text = widget.teamData!.mfName;
      _controllers['mannschaftsführerTel']?.text = widget.teamData!.mfTel;
      _pdfBlob = widget.teamData!.pdfBlob;
      _photoBlob = widget.teamData!.photoBlob;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Mannschaft bearbeiten"),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(0)), // Ecken eckig
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildSaisonUndMannschaft(context, widget.seasons),
              const SizedBox(height: 5),
              _buildLigaUndGruppe(),
              const SizedBox(height: 5),
              _buildMatchbilanzUndPosition(),
              const SizedBox(height: 5),
              _buildMannschaftsfuehrer(),
              const SizedBox(height: 5),
              buildTextFormField('URL', controller: _controllers['url']),
              const SizedBox(height: 5),
              buildTextFormField('Kommentar',
                  controller: _controllers['kommentar']),
              const SizedBox(height: 5),
              PhotoSelector(
                onImagesSelected: (List<String> photoBlob) {},
                initialPhotoList: _photoBlob,
              ),
              const SizedBox(height: 5),
              _buildPdfSelector(),
            ],
          ),
        ),
      ),
      actions: [
        _buildActionButtons(),
      ],
    );
  }

  void _saveEntry() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!_formKey.currentState!.validate() || _isLoading) return;

    try {
      final provider = Provider.of<TeamProvider>(context, listen: false);
      final newEntry = Team(
        url: _controllers['url']?.text ?? '',
        saison: _selectedSaisonKey,
        mannschaft: _selectedMannschaft,
        liga: _selectedLiga,
        gruppe: _controllers['gruppe']?.text ?? '',
        mfName: _controllers['mannschaftsführerName']?.text ?? '',
        mfTel: _controllers['mannschaftsführerTel']?.text ?? '',
        matchbilanz: _controllers['matchbilanz']?.text ?? '',
        satzbilanz: _controllers['satzbilanz']?.text ?? '',
        position: _controllers['position']?.text ?? '',
        kommentar: _controllers['kommentar']?.text ?? '',
        pdfBlob: _pdfPath != null ? await readPdfFile() : null,
        photoBlob: _photoBlob,
      );

      Set<Team> newTeamsSet = {newEntry};

      await provider.addOrUpdateTeams(messenger, newEntry.saison, newTeamsSet);
      appError(messenger, "Speichern erfolgreich!");
      // Wenn erfolgreich gespeichert, UI neu laden
      setState(() {
        // Hier kannst du zusätzliche logische Updates nach dem Speichern hinzufügen
      });
      Navigator.of(context).pop(); // Dialog nach dem Speichern schließen
    } catch (error) {
      appError(messenger, "Fehler beim Speichern: ${error.toString()}");
    } finally {
      _isLoading = false;
    }
  }

  Widget _buildSaisonUndMannschaft(
      BuildContext context, List<SaisonData> seasons) {
    if (seasons.isEmpty) {
      return const Text('Keine Saisons verfügbar');
    }

    return Row(
      children: [
        Expanded(
          child: buildDropdownField(
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
          child: buildDropdownField(
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
  }

  Widget _buildLigaUndGruppe() {
    return Row(
      children: [
        Expanded(
          child: buildDropdownField(
            label: 'Liga',
            value: _selectedLiga,
            items: _ligen,
            onChanged: (value) => setState(() => _selectedLiga = value ?? ""),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: buildTextFormField('Gruppe',
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

  Widget _buildMatchbilanzUndPosition() {
    return Row(
      children: [
        Expanded(
            child: buildTextFormField('Matchbilanz',
                controller: _controllers['matchbilanz'])),
        const SizedBox(width: 10),
        Expanded(
            child: buildTextFormField('Satzbilanz',
                controller: _controllers['satzbilanz'])),
        const SizedBox(width: 10),
        Expanded(
            child: buildTextFormField('Position',
                controller: _controllers['position'])),
      ],
    );
  }

  Widget _buildMannschaftsfuehrer() {
    return Row(
      children: [
        Expanded(
            child: buildTextFormField('Mannschaftsführer Name',
                controller: _controllers['mannschaftsführerName'])),
        const SizedBox(width: 10),
        Expanded(
            child: buildTextFormField('Mannschaftsführer Telefonnummer',
                controller: _controllers['mannschaftsführerTel'])),
      ],
    );
  }

  Widget _buildPdfSelector() {
    return Padding(
      padding: const EdgeInsets.only(top: 0.0),
      child: Row(
        children: [
          TextButton(
            onPressed: () async {
              _pickPdfFile();
              setState(() {});
            },
            child: const Text('PDF auswählen'),
          ),
          const SizedBox(width: 10),
          if (_pdfBlob != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'PDF ausgewählt: ${_pdfPath!.split('/').last}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _pdfBlob = null;
                      _pdfPath = null;
                    });
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _pickPdfFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.bytes != null) {
      final fileBytes = result.files.single.bytes;

      setState(() {
        _pdfBlob = fileBytes;
        _pdfPath = result.files.single.path;
      });
    }
  }

  void _clearForm() {
    _controllers['url']?.clear();
    _controllers['gruppe']?.clear();
    _controllers['matchbilanz']?.clear();
    _controllers['mannschaftsführerName']?.clear();
    _controllers['mannschaftsführerTel']?.clear();
    _controllers['satzbilanz']?.clear();
    _controllers['position']?.clear();
    _controllers['kommentar']?.clear();

    setState(() {
      _selectedMannschaft = '';
      _selectedLiga = '';
      _selectedSaisonKey = '';
      _photoBlob = [];
      _selectedPdfPath = '';
      _pdfBlob = null;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _isLoading ? null : _saveEntry,
            child: _isLoading
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2.0,
                  )
                : const Text('Speichern'),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _clearForm,
            child: const Text('Zurücksetzen'),
          ),
        ],
      ),
    );
  }
}
