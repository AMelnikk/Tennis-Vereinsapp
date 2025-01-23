import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Importiere das Paket für Datum-Formatierung
import '../providers/getraenkebuchen_provider.dart';
import '../widgets/verein_appbar.dart';

class GetraenkeBuchenScreen extends StatefulWidget {
  const GetraenkeBuchenScreen({super.key});
  static const routename = "/getraenkebuchen-screen";

  @override
  State<GetraenkeBuchenScreen> createState() => _GetraenkeBuchenScreenState();
}

class _GetraenkeBuchenScreenState extends State<GetraenkeBuchenScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _buchungen = [];

  @override
  void initState() {
    super.initState();
    fetchUserBuchungen();
  }

  Future<void> fetchUserBuchungen() async {
    try {
      final provider =
          Provider.of<GetraenkeBuchenProvider>(context, listen: false);
      const userId = 'Oli'; // Benutzer-ID anpassen
      final allBuchungen = await provider.fetchUserBuchungen(userId);

      setState(() {
        _buchungen = allBuchungen
          ..sort((a, b) =>
              b['date'].compareTo(a['date'])); // Sortiere nach Datum absteigend
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fehler beim Abrufen der Buchungen: $error")),
      );
    }
  }

  double _calculateOffenerSaldo() {
    return _buchungen
        .where((buchung) => !(buchung['bezahlt'] as bool? ?? false))
        .fold(0.0, (sum, buchung) => sum + (buchung['summe'] as double));
  }

  Future<void> postGetraenke() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final provider =
          Provider.of<GetraenkeBuchenProvider>(context, listen: false);
      final statusCode = await provider.postGetraenke();

      setState(() {
        _isLoading = false;
      });

      if (statusCode >= 200 && statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erfolgreich gebucht!")),
        );
        await fetchUserBuchungen(); // Liste aktualisieren
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fehler beim Buchen: $statusCode")),
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ein Fehler ist aufgetreten: $error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GetraenkeBuchenProvider>(context);
    final anzWasser = provider.anzWasser;
    final anzSoft = provider.anzSoft;
    final anzBier = provider.anzBier;
    final summe = provider.summe;

    return Scaffold(
      appBar: VereinAppbar(),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Getränke buchen: ${summe.toStringAsFixed(2)} €",
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Getränkereihen
              buildBeverageRow(
                "Wasser",
                1.00,
                anzWasser,
                () => provider.updateWasser(anzWasser + 1),
                () => provider.updateWasser(anzWasser - 1),
              ),
              const SizedBox(height: 24),
              buildBeverageRow(
                "Apfelschorle, Iso, Limo, Spezi",
                1.50,
                anzSoft,
                () => provider.updateSoft(anzSoft + 1),
                () => provider.updateSoft(anzSoft - 1),
              ),
              const SizedBox(height: 24),
              buildBeverageRow(
                "Weizen, Bier, Radler",
                2.00,
                anzBier,
                () => provider.updateBier(anzBier + 1),
                () => provider.updateBier(anzBier - 1),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading || summe == 0 ? null : postGetraenke,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Buchen"),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        Text(
                          "Offener Saldo: ${_calculateOffenerSaldo().toStringAsFixed(2)} €",
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: _buchungen.length,
                          itemBuilder: (context, index) {
                            final buchung = _buchungen[index];

                            // Formatierte Datumsausgabe
                            final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
                            final formattedDate = dateFormat.format(
                              DateTime.parse(buchung['date']),
                            );

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: buchung['bezahlt'] == true
                                    ? Colors.grey[300]
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.grey,
                                ),
                              ),
                              child: ListTile(
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Buchung vom $formattedDate",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      "${buchung['summe']} €",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Wasser: ${buchung['anzWasser']}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      "Bier: ${buchung['anzBier']}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      "Softgetränke: ${buchung['anzSoft']}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Die Buttons "+" und "-" in eine eigene Zeile packen
  Column buildBeverageRow(String label, double price, int amount,
      VoidCallback increment, VoidCallback decrement) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "$label: ${price.toStringAsFixed(2)} €",
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: amount > 0 ? decrement : null,
            ),
            Text(
              amount.toString(),
              style: const TextStyle(fontSize: 18),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: increment,
            ),
          ],
        ),
      ],
    );
  }
}
