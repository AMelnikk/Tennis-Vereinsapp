import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/models/user.dart';
import 'package:verein_app/utils/mail.dart';
import '../providers/getraenkebuchen_provider.dart';
import '../providers/user_provider.dart'; // <-- dein eigener Provider für Benutzerdaten

class GetraenkeBuchungenDetailsScreen extends StatefulWidget {
  const GetraenkeBuchungenDetailsScreen({super.key});
  static const routename = "/getraenkedetails-screen";

  @override
  State<GetraenkeBuchungenDetailsScreen> createState() =>
      _GetraenkeBuchungenDetailsScreenState();
}

class _GetraenkeBuchungenDetailsScreenState
    extends State<GetraenkeBuchungenDetailsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _buchungen = [];
  List<Map<String, dynamic>> _filteredBuchungen = [];

  String _selectedUser = "Alle";
  String _selectedYear = "Alle";

  final Map<String, String> _users = {
    'Alle': 'Alle'
  }; // UID → Vollständiger Name
  List<String> _years = [];

  @override
  void initState() {
    super.initState();
    _loadBuchungen();
  }

  Future<void> _loadBuchungen() async {
    setState(() => _isLoading = true);

    final provider =
        Provider.of<GetraenkeBuchenProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      final fetchedBuchungen = await provider.getAllBuchungen();
      final usersMap =
          await userProvider.getAllUserNames(); // UID → "Nachname Vorname"

      // UID ggf. aktualisieren
      final updatedBuchungen =
          await Future.wait(fetchedBuchungen.map((b) async {
        final uid = (b['uid'] ?? '').trim();
        final originalName = (b['username'] ?? '').trim();

        // Nur wenn UID leer oder 'unbekannt'
        if (uid.isEmpty || uid == 'unbekannt') {
          // Suche UID anhand des Namens
          final matchedEntry = usersMap.entries.firstWhere(
            (entry) => entry.value == originalName,
            orElse: () => const MapEntry('', ''),
          );

          if (matchedEntry.key.isNotEmpty) {
            // UID in DB updaten
            await provider.updateBuchungUid(b['id'], matchedEntry.key);

            // Rückgabe mit aktualisierter UID
            return {
              ...b,
              'uid': matchedEntry.key,
            };
          } else {
            // Kein Treffer, (*) markieren
            return {
              ...b,
              'uid': 'unbekannt',
              'username': '$originalName (*)',
            };
          }
        } else {
          // UID bereits vorhanden, Buchung bleibt unverändert
          return b;
        }
      }).toList());

      // Jetzt setState
      if (mounted) {
        setState(() {
          _users.clear();
          _users['Alle'] = 'Alle';
          _users.addAll(usersMap);
          _buchungen = updatedBuchungen;
          _extractYears();
          _applyFilters();
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fehler beim Laden der Buchungen: $error")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _extractYears() {
    final yearsSet = <String>{};
    for (var buchung in _buchungen) {
      final date = DateTime.tryParse(buchung['date'] ?? '');
      if (date != null) yearsSet.add(date.year.toString());
    }
    _years = yearsSet.toList()..sort();
  }

  void _applyFilters() {
    setState(() {
      _filteredBuchungen = _buchungen.where((b) {
        if (_selectedUser != "Alle" && b['uid'] != _selectedUser) return false;
        if (_selectedYear != "Alle" &&
            !_formatDate(b['date']).startsWith(_selectedYear)) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  String _formatDate(String? isoDate) {
    final date = DateTime.tryParse(isoDate ?? '');
    return date != null ? DateFormat('dd.MM.yyyy').format(date) : "Unbekannt";
  }

  String _formatTime(String? isoDate) {
    final date = DateTime.tryParse(isoDate ?? '');
    return date != null ? DateFormat('HH:mm:ss').format(date) : "Unbekannt";
  }

  void _deleteBuchung(String id) async {
    setState(() => _isLoading = true);
    final provider =
        Provider.of<GetraenkeBuchenProvider>(context, listen: false);
    final status = await provider.deleteBuchung(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(status == 200
                ? 'Buchung gelöscht.'
                : 'Fehler beim Löschen der Buchung.')),
      );
    }
    await _loadBuchungen();
    setState(() => _isLoading = false);
  }

  Future<void> _sendUserBuchungenEmail() async {
    final userBuchungen =
        _buchungen.where((b) => b['uid'] == _selectedUser).toList();
    final username = _users[_selectedUser] ?? 'Unbekannt';

    if (userBuchungen.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Keine Buchungen für diesen Benutzer.")),
      );
      return;
    }

    final body = StringBuffer("<h2>Buchungen für $username</h2><ul>");
    for (var b in userBuchungen) {
      final date = _formatDate(b['date']);
      final time = _formatTime(b['date']);
      final summe = b['summe'].toStringAsFixed(2);
      body.writeln("<li>$date $time – €$summe</li>");
    }
    body.writeln("</ul>");

    final success = await MailService.sendEmail(
      to: "oliver@stroebel-home.de",
      subject: "Buchungen für $username",
      htmlContent: body.toString(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                success ? "E-Mail versendet." : "Fehler beim E-Mail-Versand.")),
      );
    }
  }

  void _openEinzahlungDialog(String uid) {
    double betrag = 0.0;
    final name = _users[uid] ?? "Unbekannt";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Einzahlung für $name"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                  labelText:
                      "Betrag in € (negativ und mit Komma als Cent Trenner)"),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final sanitized = v.replaceAll('.', '').replaceAll(',', '.');
                betrag = double.tryParse(sanitized) ?? 0.0;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Abbrechen"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            child: const Text("Buchen"),
            onPressed: () async {
              if (betrag < 0) {
                final provider = Provider.of<GetraenkeBuchenProvider>(context,
                    listen: false);
                final userProvider =
                    Provider.of<UserProvider>(context, listen: false);

                User selectedUser = await userProvider.getUserDataWithUid(uid);

                await provider.bucheEinzahlung(
                    '${selectedUser.nachname.trim()} ${selectedUser.vorname.trim()}',
                    uid,
                    userProvider.user.uid,
                    betrag);
                Navigator.pop(ctx);
                _loadBuchungen();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          "Bitte einen gültigen Betrag eingeben. Einzahlungen sind negativ!!!")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Getränkebuchungen")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildFilterSection(),
            _buildBuchungenTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    // Benutzer alphabetisch nach Nachname, dann Vorname sortieren
    final sortedUsers = Map.fromEntries(
      _users.entries.toList()
        ..sort((a, b) {
          final aParts = a.value.trim().split(RegExp(r'\s+'));
          final bParts = b.value.trim().split(RegExp(r'\s+'));

          final aNachname = aParts.isNotEmpty ? aParts[0].toLowerCase() : '';
          final bNachname = bParts.isNotEmpty ? bParts[0].toLowerCase() : '';

          final cmpNachname = aNachname.compareTo(bNachname);
          if (cmpNachname != 0) return cmpNachname;

          final aVorname = aParts.length > 1 ? aParts[1].toLowerCase() : '';
          final bVorname = bParts.length > 1 ? bParts[1].toLowerCase() : '';
          return aVorname.compareTo(bVorname);
        }),
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              const Text("Benutzer: "),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownSearch<String>(
                  items: sortedUsers.keys.toList(),
                  selectedItem: _selectedUser,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedUser = value;
                        _applyFilters();
                      });
                    }
                  },
                  // Diese Methode sagt, was in der Liste und für die Suche angezeigt wird
                  itemAsString: (key) => sortedUsers[key] ?? '',
                  dropdownBuilder: (context, selectedItem) {
                    return Text(sortedUsers[selectedItem] ?? '');
                  },
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    itemBuilder: (context, item, isSelected) {
                      return ListTile(
                        title: Text(sortedUsers[item] ?? ''),
                      );
                    },
                    searchFieldProps: TextFieldProps(
                      decoration: const InputDecoration(
                        labelText: "Benutzer suchen",
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text("Jahr: "),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownSearch<String>(
                  items: ["Alle", ..._years],
                  selectedItem: _selectedYear,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedYear = value;
                        _applyFilters();
                      });
                    }
                  },
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: const InputDecoration(
                        labelText: "Jahr suchen",
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_selectedUser != "Alle")
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _sendUserBuchungenEmail,
                    icon: const Icon(Icons.email),
                    label: const Text("Getränkeliste senden"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _openEinzahlungDialog(_selectedUser),
                    icon: const Icon(Icons.add),
                    label: const Text("Einzahlung buchen"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBuchungenTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredBuchungen.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("Keine Buchungen verfügbar"),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text("Datum")),
          DataColumn(label: Text("Uhrzeit")),
          DataColumn(label: Text("Benutzer")),
          DataColumn(label: Text("Wasser")),
          DataColumn(label: Text("Softdrinks")),
          DataColumn(label: Text("Bier")),
          DataColumn(label: Text("Summe (€)")),
          DataColumn(label: Text("Aktionen")),
        ],
        rows: _filteredBuchungen.map((b) {
          final id = b['id'];
          return DataRow(cells: [
            DataCell(Text(_formatDate(b['date']))),
            DataCell(Text(_formatTime(b['date']))),
            DataCell(Text(b['username'] ?? 'Unbekannt')),
            DataCell(Text(b['anzWasser'].toString())),
            DataCell(Text(b['anzSoft'].toString())),
            DataCell(Text(b['anzBier'].toString())),
            DataCell(Text(b['summe'].toStringAsFixed(2))),
            DataCell(IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteBuchung(id),
            )),
          ]);
        }).toList(),
      ),
    );
  }
}
