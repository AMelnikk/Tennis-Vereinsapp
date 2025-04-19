import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Importiere das Paket für Datum-Formatierung
import 'package:verein_app/providers/auth_provider.dart';
import 'package:verein_app/providers/user_provider.dart';
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

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // AuthProvider und UserProvider abrufen
    final authProvider =
        Provider.of<AuthorizationProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final getraenkeProvider =
        Provider.of<GetraenkeBuchenProvider>(context, listen: false);
    String? uid = authProvider.userId.toString();

    if (uid.isEmpty) {
      if (kDebugMode) print("Fehler: Keine gültige UID gefunden.");
    }

    // Benutzerinformationen abrufen
    await userProvider.getOwnUserData(uid);

    getraenkeProvider.username =
        "${userProvider.user.nachname} ${userProvider.user.vorname}";
    getraenkeProvider.uid = userProvider.user.uid;
    fetchUserBuchungen();
  }

  Future<void> fetchUserBuchungen() async {
    try {
      final provider =
          Provider.of<GetraenkeBuchenProvider>(context, listen: false);

      final allBuchungen = await provider.fetchUserBuchungen();

      setState(() {
        _buchungen = allBuchungen
          ..sort((a, b) =>
              b['date'].compareTo(a['date'])); // Sortiere nach Datum absteigend
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fehler beim Abrufen der Buchungen: $error")),
        );
      }
    }
  }

  double _calculateOffenerSaldo() {
    return _buchungen
        .where((buchung) => !(buchung['bezahlt'] as bool? ?? false))
        .fold(
            0.0, (sum, buchung) => sum + (buchung['summe'] as num).toDouble());
  }

  Future<void> postGetraenke() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      final provider =
          Provider.of<GetraenkeBuchenProvider>(context, listen: false);
      final statusCode = await provider.postGetraenke(context);

      setState(() {
        _isLoading = false;
      });

      if (statusCode >= 200 && statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erfolgreich gebucht!")),
          );
        }
        await fetchUserBuchungen(); // Liste aktualisieren
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Fehler beim Buchen: $statusCode")),
          );
        }
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ein Fehler ist aufgetreten: $error")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GetraenkeBuchenProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
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
                          "Offener Saldo von ${userProvider.user.vorname}: ${_calculateOffenerSaldo().toStringAsFixed(2)} €",
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _buchungen.length,
                          itemBuilder: (context, index) {
                            final buchung = _buchungen[index];

                            // Parsing der Summe als double, auch wenn sie negativ ist
                            final summe =
                                double.tryParse(buchung['summe'].toString()) ??
                                    0.0;
                            final isEinzahlung = summe < 0;

                            // Formatierung des Datums
                            final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
                            final formattedDate = dateFormat.format(
                              DateTime.parse(buchung['date']),
                            );

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isEinzahlung
                                    ? Colors.green[100]
                                    : // Grün für Einzahlungen
                                    (buchung['bezahlt'] == true
                                        ? Colors.grey[300]
                                        : Colors.white),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.grey,
                                ),
                              ),
                              child: ListTile(
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${isEinzahlung ? "Einzahlung" : "Buchung"} vom $formattedDate",
                                      style: const TextStyle(
                                        fontSize:
                                            20, // Etwas größerer Text für den Titel
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  "${summe.toStringAsFixed(2)} €",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isEinzahlung
                                        ? Colors.green[800]
                                        : Colors
                                            .red, // Grün für Einzahlungen, Rot für normale Buchungen
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if ((buchung['anzWasser'] ?? 0) > 0)
                                      Text(
                                        "Wasser: ${buchung['anzWasser']}",
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    if ((buchung['anzBier'] ?? 0) > 0)
                                      Text(
                                        "Bier: ${buchung['anzBier']}",
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    if ((buchung['anzSoft'] ?? 0) > 0)
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
