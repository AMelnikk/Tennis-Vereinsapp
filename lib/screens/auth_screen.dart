// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/models/user.dart';
import 'package:verein_app/providers/user_provider.dart';
import 'package:verein_app/utils/app_utils.dart';
import '../providers/auth_provider.dart';
import '../widgets/verein_appbar.dart'; // 💡 Import des echten Appbar-Widgets
import '../models/http_exception.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.pop});
  static const routeName = "/auth-screen";

  final bool pop;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // 💡 Die Variablen zur Steuerung und Verwaltung des Zustands
  bool registrieren =
      false; // Steuert, was angezeigt wird (Login=false, SignUp=true)
  var _isLoading = false;

  final email = TextEditingController();
  final password = TextEditingController();
  final platzbuchungLink = TextEditingController();
  final nachname = TextEditingController();
  final vorname = TextEditingController();

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Es ist ein Fehler aufgetreten"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // ⚠️ WICHTIG: Die Argumente der Route sind nicht sofort in initState verfügbar.
    // Wir verwenden addPostFrameCallback, um auf den Context zugreifen zu können.

    // Wir rufen die Logik auf, um zu prüfen, ob ein Argument übergeben wurde,
    // das uns zwingt, direkt zum Registrieren-Modus zu springen.
    _checkInitialRouteArguments();
  }

  void _checkInitialRouteArguments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Hole die Routen-Einstellungen.
      final settings = ModalRoute.of(context)?.settings;

      // 2. Extrahiere die übergebenen Argumente als Map.
      final arguments = settings?.arguments;

      // 3. Prüfe, ob das 'mode' Argument existiert und 'signup' ist.
      if (arguments is Map<String, dynamic> && arguments['mode'] == 'signup') {
        // Nur updaten, wenn es nötig ist.
        if (registrieren == false) {
          setState(() {
            registrieren = true; // Setze den Status auf Registrieren (SignUp)
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      // 💡 Nutzung des importierten VereinAppbar-Widgets
      appBar: VereinAppbar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(color: Colors.white10),
                ),
                // Zeigt 'signUpWidget' (Registrierung), wenn registrieren=true ist.
                // Dieser Zustand wird durch _checkInitialRouteArguments gesetzt.
                registrieren ? signUpWidget() : logInWidget(),
              ],
            ),
    );
  }

  Future<void> signIn() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isLoading = true;
    });
    try {
      await Provider.of<AuthorizationProvider>(context, listen: false)
          .signIn(context, email.text, password.text);
      Future.delayed(const Duration(milliseconds: 500));
      if (mounted && widget.pop) {
        if (Navigator.canPop(context)) {
          Navigator.of(context)
              .pop(); // Nur schließen, wenn ein Dialog/Overlay geöffnet ist
        } else {
          debugPrint('Kein Dialog zum Schließen.');
        }
      }
    } on HttpException catch (error) {
      var errorMessage = "Sie können nicht authentifiziert werden";
      if (error.toString().contains("INVALID_EMAIL")) {
        errorMessage = "Email ist falsch";
      } else if (error.toString().contains("INVALID_LOGIN_CREDENTIALS")) {
        errorMessage = "Email oder Passwort sind falsch";
      }
      _showErrorDialog(errorMessage);
    } catch (error) {
      const errorMessage =
          "Sie können nicht authentifiziert werden. Bitte versuchen sie es später";
      appError(messenger, errorMessage);
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> signUp() async {
    setState(() {
      _isLoading = true;
    });
    User newUSer = User.empty();
    String idToken = "";
    try {
      AuthorizationProvider aP =
          Provider.of<AuthorizationProvider>(context, listen: false);

      if (nachname.text.isEmpty) {
        newUSer.nachname = email.text;
      } else {
        newUSer.nachname = nachname.text;
      }
      newUSer.vorname = vorname.text;
      newUSer.role = "Mitglied";
      Map rData = await aP.signUp(email.text, password.text);
      idToken = rData["idToken"];
      newUSer.uid = rData["localId"];
      if (!context.mounted) return;

      Future.delayed(const Duration(milliseconds: 500));
      if (mounted && widget.pop) {
        Navigator.of(context).pop();
      }
    } on HttpException catch (error) {
      if (kDebugMode) print("error: ${error.toString()}");
      var errorMessage =
          "Sie könnten nicht registriert werden. Ist ihr Passwort mindestens 6 Zeichen lang?";
      if (error.toString().contains("INVALID_EMAIL")) {
        errorMessage = "Email ist falsch";
      } else if (error.toString().contains("EMAIL_EXISTS")) {
        errorMessage =
            "Email-Adresse schon vorhanden. Bitte nutzen Sie den Passwort Reset";
      } else if (error.toString().contains("MISSING_PASSWORD")) {
        errorMessage = "Passwort fehlt";
      } else if (error.toString().contains("WEAK_PASSWORD") ||
          error.toString().contains("INVALID_LOGIN_CREDENTIALS")) {
        errorMessage =
            "Passwort ist zu kurz: Es muss wenigstens 6 Zeichen erhalten";
      } else if (error.toString().contains("NAME_FEHLT")) {
        errorMessage = "Name fehlt";
      }
      _showErrorDialog(errorMessage);
    } catch (error) {
      const errorMessage =
          "Sie können nicht authentifiziert werden. Bitte versuchen sie es später";
      _showErrorDialog(errorMessage);
    }
    UserProvider uP = Provider.of<UserProvider>(context, listen: false);
    uP.postUser(context, newUSer, idToken);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showResetPasswordDialog(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    AuthorizationProvider aP =
        Provider.of<AuthorizationProvider>(context, listen: false);
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Passwort zurücksetzen"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "E-Mail-Adresse"),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dialog schließen
            },
            child: const Text("Abbrechen"),
          ),
          TextButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                appError(messenger, "Bitte geben Sie eine E-Mail-Adresse ein.");
                return;
              }

              try {
                await aP.resetPassword(context, email);
                if (mounted) {
                  if (!context.mounted) return;
                  // Check if the widget is still mounted

                  Navigator.of(context).pop(); // Dialog schließen nach Erfolg
                }
              } catch (error) {
                if (mounted) {
                  if (!context.mounted) return;
                  // Check if the widget is still mounted
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fehler: $error')),
                  );
                }
              }
            },
            child: const Text("Zurücksetzen"),
          ),
        ],
      ),
    );
  }

  Widget logInWidget() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.grey),
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.spaceBetween; <--- ENTFERNT,
        // damit die Elemente nicht an den Rand geschoben werden
        children: [
          // --- ANMELDUNG BLOCK ---
          const Padding(
            padding: EdgeInsets.only(top: 20, bottom: 20), // Mehr Abstand oben
            child: Text(
              "Anmeldung",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
          // ... (Email und Passwort Textfelder bleiben hier) ...

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: TextFormField(
              controller: email,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Email (= Anmeldename)",
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: TextFormField(
              obscureText: true,
              controller: password,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Passwort",
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ),

          const SizedBox(height: 20), // Abstand hinzufügen

          // 1. ANMELDEN BUTTON (Hauptaktion)
          ElevatedButton(
            onPressed: () async {
              await signIn();
            },
            child: const Text("anmelden"),
          ),

          // 2. PASSWORT VERGESSEN BUTTON (Sekundäre Aktion)
          TextButton(
            onPressed: () => _showResetPasswordDialog(context),
            child: const Text(
              "Passwort vergessen?",
              style: TextStyle(color: Colors.white),
            ),
          ),

          const SizedBox(height: 40), // Deutlicher Trenner

          // 3. REGISTRIEREN BUTTON (Hervorgehoben und oben platziert)
          // Wir verwenden einen OutlinedButton, um ihn hervorzuheben
          OutlinedButton(
            onPressed: () {
              setState(() {
                registrieren = true;
              });
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                  color: Colors.white, width: 2), // Weiße Umrandung
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text(
              "Jetzt registrieren",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),

          // Füllbereich, falls nötig, um den Container auszufüllen
          const Spacer(),
        ],
      ),
    );
  }

  Widget signUpWidget() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.grey),
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.spaceBetween, <--- ENTFERNT
        children: [
          // --- REGISTRIERUNGS-FELDER ---
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  "Registrierung",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
              // Vorname / Nachname
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: vorname,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Vorname",
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: nachname,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Nachname",
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Email, Passwort, Link (unverändert)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: TextFormField(
                  controller: email,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Email (= Anmeldename)",
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: TextFormField(
                  obscureText: true,
                  controller: password,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Passwort",
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: TextFormField(
                  controller: platzbuchungLink,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Link für TeamUp",
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ),

              const SizedBox(height: 20), // Abstand für den Haupt-Button

              // 1. REGISTRIEREN BUTTON (Hauptaktion)
              ElevatedButton(
                onPressed: () async {
                  await signUp();
                },
                child: const Text("registrieren"),
              ),

              const SizedBox(height: 40), // Deutlicher Trenner
            ],
          ),

          // 2. ZURÜCK ZUR ANMELDUNG BUTTON (Hervorgehoben und sichtbar platziert)
          OutlinedButton(
            // Verwenden Sie OutlinedButton für bessere Sichtbarkeit
            onPressed: () {
              setState(() {
                registrieren = false;
              });
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                  color: Colors.white, width: 2), // Weiße Umrandung
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text(
              "Zurück zur Anmeldung",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),

          const Spacer(), // Füllt den restlichen Platz aus
        ],
      ),
    );
  }
}
