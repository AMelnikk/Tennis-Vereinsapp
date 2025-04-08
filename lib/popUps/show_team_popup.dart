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
  MyTeamDialogState createState() => MyTeamDialogState();
}

class MyTeamDialogState extends State<MyTeamDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _pdfPath;
  Uint8List? _pdfBlob;
  // ignore: unused_field
  String _editID = '';
  bool _isLoading = false;
  List<String> _photoBlob = [];
  String _selectedSaisonKey = '';
  // ignore: unused_field
  String _selectedPdfPath = '';

  final _controllers = <String, TextEditingController>{
    'url': TextEditingController(),
    'gruppe': TextEditingController(),
    'matchbilanz': TextEditingController(),
    'mannschaft': TextEditingController(),
    'liga': TextEditingController(),
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
      _editID = widget.teamData!.mannschaft;
      _selectedSaisonKey = widget.teamData!.saison;
      _controllers['mannschaft']?.text = widget.teamData!.mannschaft;
      _controllers['liga']?.text = widget.teamData!.liga;
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(0)), // Ecken eckig
      ),
      child: Container(
        width:
            MediaQuery.of(context).size.width * 0.9, // 90% der Bildschirmbreite
        height:
            MediaQuery.of(context).size.height * 0.9, // 90% der Bildschirmhöhe
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Mannschaft",
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
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
                      buildTextFormField('URL',
                          controller: _controllers['url']),
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
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  void _saveEntry() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true); // Blockieren erneuter Klicks

    final messenger = ScaffoldMessenger.of(context);

    try {
      final provider = Provider.of<TeamProvider>(context, listen: false);
      final newEntry = Team(
        url: _controllers['url']?.text ?? '',
        saison: _selectedSaisonKey,
        mannschaft: _controllers['mannschaft']?.text ?? '',
        liga: _controllers['liga']?.text ?? '',
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

      await provider.addOrUpdateTeams(messenger, newEntry.saison, {newEntry});
      appError(messenger, "Speichern erfolgreich!");

      if (mounted) {
        Navigator.of(context)
            .pop(); // Schließen nur, wenn Widget noch existiert
      }
    } catch (error) {
      appError(messenger, "Fehler beim Speichern: ${error.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          child: buildTextFormField(
            'Mannschaft',
            controller: _controllers['mannschaft'],
          ),
        ),
      ],
    );
  }

  Widget _buildLigaUndGruppe() {
    return Row(
      children: [
        Expanded(
          child: buildTextFormField(
            'Liga',
            controller: _controllers['liga'],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bitte die Liga eingeben';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: buildTextFormField(
            'Gruppe',
            controller: _controllers['gruppe'],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bitte die Gruppe eingeben';
              }
              return null;
            },
          ),
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
