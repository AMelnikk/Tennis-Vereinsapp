import 'package:flutter/material.dart';
import 'package:verein_app/providers/getraenkebuchen_provider.dart';
import '../widgets/verein_appbar.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

class GetraenkeBuchenScreen extends StatefulWidget {
  const GetraenkeBuchenScreen({super.key});
  static const routename = "/getraenkebuchen-screen";

  @override
  State<GetraenkeBuchenScreen> createState() => _GetraenkeBuchenState();
}

class _GetraenkeBuchenState extends State<GetraenkeBuchenScreen> {
  bool _isLoading = false;

  // Methode zum Getränkebuchen
  Future<void> postGetraenke() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Aufruf der Post-Methode im Provider
      int statusCode =
          await Provider.of<GetraenkeBuchenProvider>(context, listen: false)
              .postGetraenke();

      setState(() {
        _isLoading = false;
      });

      // Erfolgs- oder Fehlernachricht basierend auf Statuscode anzeigen
      if (statusCode >= 200 && statusCode < 300) {
        showSnackBar("Erfolg! Die Getränke wurden verbucht");
      } else {
        showSnackBar("Fehler beim Buchen der Getränke: $statusCode");
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      showSnackBar("Ein unerwarteter Fehler ist aufgetreten: $error");
    }
  }

  // Methode zum Anzeigen der SnackBar
  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // Methode zum Zurücksetzen des Providers
  void resetProvider() {
    Provider.of<GetraenkeBuchenProvider>(context, listen: false).resetData();
  }

  // Widget zum Erstellen einer Getränkereihe
  Widget buildBeverageRow(String label, double price, int count,
      VoidCallback increment, VoidCallback decrement) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "$label (${price.toStringAsFixed(2)} €)",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: count > 0 ? decrement : null,
            ),
            Text(
              "$count",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
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
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              buildBeverageRow(
                "Wasser",
                1.00,
                anzWasser,
                () => provider.updateWasser(anzWasser + 1),
                () => provider.updateWasser(anzWasser - 1),
              ),
              const SizedBox(height: 20),
              buildBeverageRow(
                "Apfelschorle, Iso, Limo, Spezi",
                1.50,
                anzSoft,
                () => provider.updateSoft(anzSoft + 1),
                () => provider.updateSoft(anzSoft - 1),
              ),
              const SizedBox(height: 20),
              buildBeverageRow(
                "Weizen, Bier, Radler",
                2.00,
                anzBier,
                () => provider.updateBier(anzBier + 1),
                () => provider.updateBier(anzBier - 1),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: ElevatedButton(
                  onPressed: _isLoading || summe == 0 ? null : postGetraenke,
                  child: Container(
                    alignment: Alignment.center,
                    width: double.infinity,
                    height: 50,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Getränke buchen",
                            style: TextStyle(fontSize: 20),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
