import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/providers/user_provider.dart';
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
  Map<String, double> _userSummen = {};

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
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      final fetchedBuchungen = await provider.getAllBuchungen();
      final usersMap = await userProvider.getAllUserNames(); // uid → name

      double gesamtSumme = 0;
      Map<String, double> userSummen = {};

      for (var buchung in fetchedBuchungen) {
        final uid = (buchung['uid'] ?? '').trim();
        final usernameFromBuchung = (buchung['username'] ?? '').trim();
        final name = usersMap[uid] ?? usernameFromBuchung;
        final summe = (buchung['summe'] ?? 0).toDouble();

        gesamtSumme += summe;

        if (userSummen.containsKey(name)) {
          userSummen[name] = userSummen[name]! + summe;
        } else {
          userSummen[name] = summe;
        }
      }

      setState(() {
        _gesamtSumme = gesamtSumme;
        _userSummen = userSummen;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Fehler beim Laden der Buchungen: $error"),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<MapEntry<String, double>> sortedUserSummen = _userSummen.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value) * -1); // Größter zuerst

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gesamt Getränkebuchungen"),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _userSummen.isEmpty
              ? const Center(
                  child: Text(
                    "Keine Buchungen gefunden.",
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gesamtsaldo aller Benutzer: ${_gesamtSumme.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(
                                label: Text(
                                  "Benutzer",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Summe (€)",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            rows: sortedUserSummen.map((entry) {
                              return DataRow(cells: [
                                DataCell(Text(entry.key)),
                                DataCell(Text(entry.value.toStringAsFixed(2))),
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
