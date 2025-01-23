import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/getraenkebuchen_provider.dart';

class GetraenkeSummenScreen extends StatefulWidget {
  const GetraenkeSummenScreen({super.key});
  static const routename = "/getraenkesummen-screen";

  @override
  State<GetraenkeSummenScreen> createState() => _GetraenkeSummenScreenState();
}

class _GetraenkeSummenScreenState extends State<GetraenkeSummenScreen> {
  bool _isLoading = false;
  double _gesamtSumme = 0;
  Map<String, double> _userSummen = {}; // Speichert die Summe pro Benutzer

  @override
  void initState() {
    super.initState();
    _loadGesamtBuchungen();
  }

  Future<void> _loadGesamtBuchungen() async {
    setState(() {
      _isLoading = true;
    });

    final provider =
        Provider.of<GetraenkeBuchenProvider>(context, listen: false);
    try {
      final fetchedBuchungen = await provider.getAllBuchungen();
      double gesamtSumme = 0;

      // Berechne die Summe pro User und die Gesamtsumme
      Map<String, double> userSummen = {};

      for (var buchung in fetchedBuchungen) {
        final username = buchung['username'] ?? 'Unbekannt';
        final summe = buchung['summe'] ?? 0.0;

        gesamtSumme += summe;

        if (userSummen.containsKey(username)) {
          userSummen[username] = userSummen[username]! + summe;
        } else {
          userSummen[username] = summe;
        }
      }

      setState(() {
        _gesamtSumme = gesamtSumme;
        _userSummen = userSummen;
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

  @override
  Widget build(BuildContext context) {
    // Sortiere User nach Summe, größter Saldo zuerst
    List<MapEntry<String, double>> sortedUserSummen = _userSummen.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gesamt Getränkebuchungen"),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  // Gesamtsaldo anzeigen
                  Text(
                    'Gesamtsaldo aller Benutzer: ${_gesamtSumme.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Tabelle der Salden pro User
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text("Benutzer")),
                          DataColumn(label: Text("Jahr")),
                          DataColumn(label: Text("Summe (€)")),
                        ],
                        rows: sortedUserSummen.map((entry) {
                          final username = entry.key;
                          final summe = entry.value;

                          // Nehme das Jahr aus dem ersten Buchungseintrag des Users
                          // final firstBuchung = _userSummen.entries
                          //     .firstWhere((element) => element.key == username);

                          final date = DateTime.now();
                          final year = date.year;

                          return DataRow(cells: [
                            DataCell(Text(username)),
                            DataCell(Text(year.toString())),
                            DataCell(Text(summe.toStringAsFixed(2))),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
