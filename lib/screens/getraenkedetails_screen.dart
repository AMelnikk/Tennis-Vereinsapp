import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/getraenkebuchen_provider.dart';
import 'package:intl/intl.dart'; // Für Datumsformatierung

class GetraenkeBuchungenDetailsScreen extends StatefulWidget {
  const GetraenkeBuchungenDetailsScreen({super.key});
  static const routeName = "/getraenkedetails-screen";

  @override
  _GetraenkeBuchungenDetailsScreenState createState() =>
      _GetraenkeBuchungenDetailsScreenState();
}

class _GetraenkeBuchungenDetailsScreenState
    extends State<GetraenkeBuchungenDetailsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _buchungen = [];
  List<Map<String, dynamic>> _filteredBuchungen = [];

  // Filterwerte
  String _selectedUser = "Alle";
  String _selectedYear = "Alle";
  bool _onlyUnpaid = false;
  final List<String> _users = ['Alle'];
  final List<String> _years = ['Alle'];

  @override
  void initState() {
    super.initState();
    _loadBuchungen();
  }

  Future<void> _loadBuchungen() async {
    setState(() {
      _isLoading = true;
    });

    final provider =
        Provider.of<GetraenkeBuchenProvider>(context, listen: false);
    try {
      final fetchedBuchungen = await provider.getAllBuchungen();
      setState(() {
        _buchungen = fetchedBuchungen;
        _filteredBuchungen = _buchungen; // Initially show all buchungen
        _extractFilterValues();
        _applyFilters();
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Fehler beim Laden der Buchungen: $error"),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Extrahiert die einzigartigen Werte für Benutzer und Jahr aus den Buchungen
  void _extractFilterValues() {
    Set<String> usersSet = {};
    Set<String> yearsSet = {};

    for (var buchung in _buchungen) {
      // Benutzername
      if (buchung['username'] != null) {
        usersSet.add(buchung['username']);
      }
      // Jahr aus dem Datum extrahieren
      if (buchung['date'] != null) {
        final date = DateTime.tryParse(buchung['date']);
        if (date != null) {
          yearsSet.add(date.year.toString());
        }
      }
    }

    setState(() {
      _users.addAll(usersSet);
      _years.addAll(yearsSet);
    });
  }

  // Filter anwenden
  void _applyFilters() {
    setState(() {
      _filteredBuchungen = _buchungen.where((buchung) {
        // Filter nach Benutzer
        if (_selectedUser != "Alle" && buchung['username'] != _selectedUser) {
          return false;
        }
        // Filter nach Jahr
        if (_selectedYear != "Alle" &&
            _formatDate(buchung['date']).startsWith(_selectedYear) == false) {
          return false;
        }
        // Filter nach unbezahlte Buchungen
        if (_onlyUnpaid && buchung['bezahlt'] == true) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return "Unbekannt";
    final date = DateTime.tryParse(isoDate);
    if (date == null) return "Unbekannt";
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String _formatTime(String? isoDate) {
    if (isoDate == null) return "Unbekannt";
    final date = DateTime.tryParse(isoDate);
    if (date == null) return "Unbekannt";
    return DateFormat('HH:mm:ss').format(date);
  }

  // Funktion zum Umstellen des "bezahlt"-Status
  void _toggleBezahlt(String buchungId, bool bezahlt) {
    setState(() {
      _isLoading = true;
    });
    final provider =
        Provider.of<GetraenkeBuchenProvider>(context, listen: false);
    provider.updateBezahlt(buchungId, !bezahlt).then((status) {
      if (status == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bezahlt-Status geändert.')),
        );
        _loadBuchungen(); // Buchungsliste aktualisieren
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Ändern des Status.')),
        );
      }
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }).whenComplete(() {
      setState(() {
        _isLoading = false;
      });
    });
  }

  // Funktion zum Löschen einer Buchung
  void _deleteBuchung(String buchungId) {
    setState(() {
      _isLoading = true;
    });
    final provider =
        Provider.of<GetraenkeBuchenProvider>(context, listen: false);
    provider.deleteBuchung(buchungId).then((status) {
      if (status == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Buchung gelöscht.')),
        );
        _loadBuchungen(); // Buchungsliste aktualisieren
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Löschen der Buchung.')),
        );
      }
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }).whenComplete(() {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Getränkebuchungen"),
      ),
      body: Column(
        children: [
          // Filter oben hinzufügen
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedUser,
                    onChanged: (value) {
                      setState(() {
                        _selectedUser = value ?? "Alle";
                        _applyFilters();
                      });
                    },
                    items: _users.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedYear,
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value ?? "Alle";
                        _applyFilters();
                      });
                    },
                    items: _years.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SwitchListTile(
                    title: const Text("Nur unbezahlte"),
                    value: _onlyUnpaid,
                    onChanged: (value) {
                      setState(() {
                        _onlyUnpaid = value;
                        _applyFilters();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          // Ladeanzeige oder DataTable
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _filteredBuchungen.isEmpty
                  ? const Center(
                      child: Text("Keine Buchungen verfügbar"),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: SingleChildScrollView(
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
                            DataColumn(label: Text("Bezahlt")),
                            DataColumn(label: Text("Aktionen")),
                          ],
                          rows: _filteredBuchungen.map((buchung) {
                            final String buchungId = buchung['id'];
                            final bool bezahlt = buchung['bezahlt'] ?? false;
                            return DataRow(cells: [
                              DataCell(Text(_formatDate(buchung['date']))),
                              DataCell(Text(_formatTime(buchung['date']))),
                              DataCell(
                                  Text(buchung['username'] ?? 'Unbekannt')),
                              DataCell(Text(buchung['anzWasser'].toString())),
                              DataCell(Text(buchung['anzSoft'].toString())),
                              DataCell(Text(buchung['anzBier'].toString())),
                              DataCell(
                                  Text(buchung['summe'].toStringAsFixed(2))),
                              DataCell(Switch(
                                value: bezahlt,
                                onChanged: (bool value) {
                                  _toggleBezahlt(buchungId, bezahlt);
                                },
                              )),
                              DataCell(IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _deleteBuchung(buchungId);
                                },
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
        ],
      ),
    );
  }
}
