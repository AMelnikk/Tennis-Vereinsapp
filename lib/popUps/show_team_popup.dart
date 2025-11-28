import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/providers/season_provider.dart';
import 'package:verein_app/providers/user_provider.dart';
import 'package:verein_app/widgets/mf_selection_dialog.dart';
import '../models/season.dart';
import '../models/team.dart';
import '../providers/team_provider.dart';
import '../utils/app_utils.dart';
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

  List<Uint8List> _pdfBlob = [];
  final List<String> _pdfPaths = [];
  // ignore: unused_field
  String _editID = '';
  bool _isLoading = false;
  List<String> _photoBlob = [];
  String _selectedSaisonKey = '';
  // ignore: unused_field
  final String _selectedPdfPath = '';
  String _selectedMfUid = '';
  Map<String, String> _allUsers = {};
  bool _isUserLoading = true;
  bool _isCurrentUserAdmin = false;

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
      _pdfBlob = widget.teamData!.pdfBlob ?? [];
      _photoBlob = widget.teamData!.photoBlob;
    }

    if (widget.teamData != null) {
      // Laden der bestehenden UID, falls ein Team bearbeitet wird
      _selectedMfUid = widget.teamData!.mfUID;
    }

    // ✅ HIER WIRD DIE DATENLADUNG GESTARTET
    _loadUserNames();
    _checkAdminStatus;
  }

  void _checkAdminStatus() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final isAdmin = await userProvider.isAdmin(context); // Ruft die Methode auf

    if (mounted) {
      setState(() {
        _isCurrentUserAdmin = isAdmin;
      });
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
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildSaisonUndMannschaft(context, widget.seasons),

                        const SizedBox(height: 5),
                        _buildMannschaftsfuehrer(),

                        // ✅ KORRIGIERTE SYNTAX: If-Anweisung ohne geschweifte Klammern in der Liste
                        if (_isCurrentUserAdmin) const SizedBox(height: 5),
                        if (_isCurrentUserAdmin)
                          buildTextFormField('URL',
                              controller: _controllers['url']),
                        if (_isCurrentUserAdmin) const SizedBox(height: 5),

                        buildTextFormField('Kommentar',
                            controller: _controllers['kommentar']),
                        const SizedBox(height: 5),
                        _buildMatchbilanzUndPosition(),
                        const SizedBox(height: 5),
                        PhotoSelector(
                          onImagesSelected: (List<String> photoBlob) {
                            setState(() {
                              _photoBlob = photoBlob;
                            });
                          },
                          initialPhotoList: _photoBlob,
                        ),
                        const SizedBox(height: 5),
                        _buildPdfSelector(),
                      ],
                    )),
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfSelector() {
    // Wenn Sie den Button und die Liste in einer Column wollen,
    // muss der gesamte Inhalt in eine äußere Column:
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Button zum Hinzufügen einer PDF
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: TextButton(
            onPressed: () async {
              _pickPdfFile();

              setState(() {});
            },
            child: const Text('PDF(s) auswählen'),
          ),
        ),

        const SizedBox(height: 10),

        // 2. Liste der ausgewählten PDFs (iterieren über _pdfPaths)
        if (_pdfPaths.isNotEmpty)
          ..._pdfPaths.asMap().entries.map((entry) {
            final index = entry.key;
            final fileName = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Text zur Anzeige des Dateinamens
                  Expanded(
                    child: Text(
                      'PDF ${index + 1}: $fileName',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),

                  // Löschen-Button für DIESE EINE Datei
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                    onPressed: () {
                      // ✅ LÖSCHEN DER EINZELNEN DATEI ÜBER DEN INDEX
                      setState(() {
                        _pdfPaths.removeAt(index);
                        _pdfBlob.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
            );
          })
      ],
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
        mfUID: _selectedMfUid,
        matchbilanz: _controllers['matchbilanz']?.text ?? '',
        satzbilanz: _controllers['satzbilanz']?.text ?? '',
        position: _controllers['position']?.text ?? '',
        kommentar: _controllers['kommentar']?.text ?? '',
        pdfBlob: _pdfBlob,
        photoBlob: _photoBlob,
      );

      await provider.addOrUpdateTeams(messenger, newEntry.saison, {newEntry});
      appError(messenger, "Speichern erfolgreich!");

      if (mounted) {
        Navigator.of(context)
            .pop(newEntry); // Schließen nur, wenn Widget noch existiert
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
    final SaisonProvider saisonP =
        Provider.of<SaisonProvider>(context, listen: false);

    if (widget.teamData == null) {
      return const Text('Keine Teamdaten verfügbar.',
          style: TextStyle(fontSize: 16));
    }

    final team = widget.teamData!;

    final String saisonName = saisonP.getSaisonTextFromKey(team.saison);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        // ✅ KORREKTUR: Ausrichtung auf zentriert ändern
        crossAxisAlignment: CrossAxisAlignment.center,

        // ✅ ZUSÄTZLICH: Fügen wir die MainAxisSize hinzu,
        // damit die Column nur so viel Breite einnimmt, wie ihre Kinder benötigen.
        // Dies ist oft notwendig, damit CrossAxisAlignment.center funktioniert.
        mainAxisSize: MainAxisSize.min,

        children: [
          // 1. Große Anzeige: Saison und Mannschaft
          Text(
            "Saison: $saisonName - ${team.mannschaft}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign
                .center, // Optional: Textausrichtung für sehr lange Zeilen
          ),

          const SizedBox(height: 4),

          // 2. Kleine Anzeige: Liga und Gruppe
          Text(
            "${team.liga} - ${team.gruppe}",
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            textAlign: TextAlign
                .center, // Optional: Textausrichtung für sehr lange Zeilen
          ),
        ],
      ),
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
    // Flag für die grüne Hinterlegung (UID ist ausgewählt)
    final isUidSelected = _selectedMfUid.isNotEmpty;

    // Bestimmt, ob das Feld schreibgeschützt sein soll
    // Es ist readOnly, wenn:
    // 1. Eine UID gewählt ist UND
    // 2. Der aktuelle Benutzer KEIN Admin ist.
    final bool isReadOnly = isUidSelected && !_isCurrentUserAdmin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. MF Name
            Expanded(
              flex: 3,
              child: buildTextFormField(
                'Mannschaftsführer Name',
                controller: _controllers['mannschaftsführerName'],

                // ✅ KORRIGIERTES readOnly-Flag
                readOnly: isReadOnly,

                decoration: InputDecoration(
                  labelText: 'Mannschaftsführer Name',
                  // Hintergrundfarbe bleibt hellgrün, wenn UID gesetzt ist
                  fillColor: isUidSelected ? Colors.green.shade50 : null,
                  filled: isUidSelected,
                ),
              ),
            ),

            // 2. Edit Button / Auswahl-Button
            // ... (Rest des Widgets bleibt unverändert)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: IconButton(
                icon: Icon(
                  Icons.edit,
                  size: 18.0, // <-- Größe reduziert (z.B. auf 18)
                  color: Theme.of(context)
                      .colorScheme
                      .primary, // <-- Nur Primärfarbe (kein Grün)
                  // ODER eine weniger auffällige Farbe verwenden:
                  // color: Colors.black54,
                ),
                onPressed: _isUserLoading ? null : _openMfSelectionDialog,
              ),
            ),

            // ... (Telefonnummer)
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: buildTextFormField(
                'Telefonnummer',
                controller: _controllers['mannschaftsführerTel'],
                decoration: const InputDecoration(
                  labelText: 'Telefonnummer',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
      ],
    );
  }

  void _openMfSelectionDialog() async {
    // Wenn die Benutzerdaten noch geladen werden, warten wir oder brechen ab
    if (_isUserLoading) return;

    final selectedEntry = await showDialog<MapEntry<String, String>>(
      context: context,
      builder: (context) {
        // ✅ Wrapper-Korrektur
        return Dialog(
          // Verwenden Sie Dialog als Wrapper
          child: MfSelectionDialog(
            // Platzieren Sie Ihr Widget im Child
            userMap: _allUsers,
          ),
        );
      },
    );

    if (selectedEntry != null) {
      setState(() {
        // Die UID speichern
        _selectedMfUid = selectedEntry.key;

        if (_selectedMfUid.isNotEmpty) {
          // Wenn ein registrierter Benutzer gewählt wurde, Name übernehmen
          _controllers['mannschaftsführerName']!.text = selectedEntry.value;
          // Optional: Telefonnummer leeren, da diese oft separat gehandhabt wird
          _controllers['mannschaftsführerTel']!.clear();
        } else {
          // Wenn 'Manuell eingeben' gewählt wurde, Felder leeren
          _controllers['mannschaftsführerName']!.clear();
          _controllers['mannschaftsführerTel']!.clear();
        }
      });
    }
  }

  void _pickPdfFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true, // ✅ NEU: Mehrfachauswahl erlauben
    );

    if (result != null) {
      setState(() {
        for (var file in result.files) {
          if (file.bytes != null && file.name.isNotEmpty) {
            _pdfBlob.add(file.bytes!);
            _pdfPaths.add(file.name); // Speichere den Dateinamen
          }
        }
      });
    }
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
          // 1. Speichern Button (unverändert)
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

          // 2. SCHLIESSEN Button (ersetzt Zurücksetzen)
          ElevatedButton(
            // 💡 NEU: Schließt das aktuelle Fenster oder den Dialog
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'), // 💡 NEU: Text geändert
          ),
        ],
      ),
    );
  }

  void _loadUserNames() async {
    // Stellen Sie sicher, dass Sie den UserProvider hier korrekt instanziieren können.
    // Das funktioniert nur, wenn ein Provider über dem MyTeamDialog im Baum liegt.
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      // Annahme: getAllUserNames() gibt Future<Map<String, String>> (UID -> Name) zurück
      final userMap = await userProvider.getAllMFandAdminUserNames();

      // Optional: Fügen Sie einen 'Manuell eingeben'-Eintrag hinzu, der key='' speichert
      userMap[''] = '--- Manuell eingeben (Keine Auswahl) ---';

      if (mounted) {
        setState(() {
          _allUsers = userMap;

          // ✅ HIER WIRD _isUserLoading auf FALSE gesetzt
          _isUserLoading = false;

          // Sicherstellen, dass _selectedMfUid einen gültigen Wert hat, falls noch nicht gesetzt
          if (_selectedMfUid.isEmpty && userMap.isNotEmpty) {
            // Setzt den Standardwert (den 'Manuell eingeben'-Eintrag oder den ersten Eintrag)
            _selectedMfUid = userMap.keys.firstWhere((key) => key.isEmpty,
                orElse: () => userMap.keys.first);
          }
        });
      }
    } catch (e) {
      // Fehlerbehandlung, falls das Laden fehlschlägt
      if (mounted) {
        setState(() {
          _allUsers = {'': 'Fehler beim Laden der Benutzer'};
          _isUserLoading = false; // Lade-Status beenden, auch bei Fehler
        });
      }

      // Beachten Sie, dass appError und ScaffoldMessenger möglicherweise nicht direkt hier verfügbar sind,
      // je nachdem, wo _loadUserNames aufgerufen wird.
      debugPrint("Fehler beim Laden der Benutzer: $e");
    }
  }
}
