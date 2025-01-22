import 'package:flutter/material.dart';
import 'package:verein_app/providers/getraenkebuchen_provider.dart';
import '../widgets/verein_appbar.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

class GetraenkeBuchenScreen extends StatefulWidget {
  GetraenkeBuchenScreen({super.key});
  static const routename = "/getraenkebuchen-screen";

  @override
  State<GetraenkeBuchenScreen> createState() => _GetraenkeBuchenState();
}

class _GetraenkeBuchenState extends State<GetraenkeBuchenScreen> {
  int _anzWasser = 0;
  int _anzSoft = 0;
  int _anzBier = 0;
  double _summe = 0;
  bool _isLoading = false;

  Future<void> postGetraenke() async {
    try {
      setState(() {
        _isLoading = true;
      });
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

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        duration:
            const Duration(seconds: 5), // Snackbar bleibt 5 Sekunden sichtbar
      ),
    );
  }

  void resetProvider() {
    setState(() {
      _anzWasser = 0;
      _anzSoft = 0;
      _anzBier = 0;
      _summe = 0;
    });
  }

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
    return Scaffold(
      appBar: VereinAppbar(),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Getränke buchen: ${_summe.toStringAsFixed(2)} €",
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              buildBeverageRow(
                "Wasser",
                1.00,
                _anzWasser,
                () => setState(() {
                  _anzWasser++;
                  _summe += 1.00;
                }),
                () => setState(() {
                  _anzWasser--;
                  _summe -= 1.00;
                }),
              ),
              const SizedBox(height: 20),
              buildBeverageRow(
                "Apfelschorle, Iso, Limo, Spezi",
                1.50,
                _anzSoft,
                () => setState(() {
                  _anzSoft++;
                  _summe += 1.50;
                }),
                () => setState(() {
                  _anzSoft--;
                  _summe -= 1.50;
                }),
              ),
              const SizedBox(height: 20),
              buildBeverageRow(
                "Weizen, Bier, Radler",
                2.00,
                _anzBier,
                () => setState(() {
                  _anzBier++;
                  _summe += 2.00;
                }),
                () => setState(() {
                  _anzBier--;
                  _summe -= 2.00;
                }),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: ElevatedButton(
                  onPressed: _isLoading || _summe == 0 ? null : postGetraenke,
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
