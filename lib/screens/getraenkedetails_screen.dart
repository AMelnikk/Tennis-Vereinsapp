import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/getraenkebuchen_provider.dart';
import 'package:intl/intl.dart'; // Für Datumsformatierung

class GetraenkeBuchungenDetailsScreen extends StatefulWidget {
  const GetraenkeBuchungenDetailsScreen({Key? key}) : super(key: key);
  static const routeName = "/getraenkedetails-screen";

  @override
  _GetraenkeBuchungenDetailsScreenState createState() =>
      _GetraenkeBuchungenDetailsScreenState();
}

class _GetraenkeBuchungenDetailsScreenState
    extends State<GetraenkeBuchungenDetailsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _buchungen = [];

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
        _buchungen.sort(
            (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Getränkebuchungen"),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _buchungen.isEmpty
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
                      ],
                      rows: _buchungen.map((buchung) {
                        return DataRow(cells: [
                          DataCell(Text(_formatDate(buchung['date']))),
                          DataCell(Text(_formatTime(buchung['date']))),
                          DataCell(Text(buchung['username'] ?? 'Unbekannt')),
                          DataCell(Text(buchung['anzWasser'].toString())),
                          DataCell(Text(buchung['anzSoft'].toString())),
                          DataCell(Text(buchung['anzBier'].toString())),
                          DataCell(Text(buchung['summe'].toStringAsFixed(2))),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
    );
  }
}
