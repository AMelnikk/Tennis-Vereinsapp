import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/verein_appbar.dart';
import '../models/http_exception.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.pop});
  static const routeName = "/auth-screen";

  final bool pop;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool registrieren = false;
  var _isLoading = false;
  final email = TextEditingController();
  final password = TextEditingController();
  final platzbuchungLink = TextEditingController();
  final name = TextEditingController();

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

  Future<void> signIn() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .signIn(email.text, password.text);
      Future.delayed(const Duration(milliseconds: 500));
      if (mounted && widget.pop) {
        Navigator.of(context).pop();
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
      _showErrorDialog(errorMessage);
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
    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .signUp(email.text, password.text, platzbuchungLink.text, name.text);
      Future.delayed(const Duration(milliseconds: 500));
      if (mounted && widget.pop) {
        Navigator.of(context).pop();
      }
    } on HttpException catch (error) {
      if(kDebugMode) print(error.toString());
      var errorMessage = "Sie können nicht authentifiziert werden";
      if (error.toString().contains("INVALID_EMAIL")) {
        errorMessage = "Email ist falsch";
      } else if (error.toString().contains("MISSING_PASSWORD")) {
        errorMessage = "Passwort fehlt";
      } else if (error.toString().contains("WEAK_PASSWORD")) {
        errorMessage =
            "Passwort ist zu kurz: Es muss wenigstens 6 Zeichen erhalten";
      } else if (error.toString().contains("NAME_FEHLT")) {
        errorMessage =
            "Name fehlt";
      }
      _showErrorDialog(errorMessage);
    } catch (error) {
      const errorMessage =
          "Sie können nicht authentifiziert werden. Bitte versuchen sie es später";
      _showErrorDialog(errorMessage);
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget logInWidget() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.grey),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  "Anmeldung",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: TextFormField(
                  controller: email,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Email",
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
              ElevatedButton(
                  onPressed: () async {
                    await signIn();
                  },
                  child: const Text("anmelden")),
            ],
          ),
          TextButton(
            onPressed: () {
              setState(() {
                registrieren = true;
              });
            },
            child: const Text(
              "Kein konto noch? Registrieren",
              style: TextStyle(color: Colors.white),
            ),
          ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  "Registrierung",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: TextFormField(
                  controller: name,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Name",
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: TextFormField(
                  controller: email,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Email",
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
                  // obscureText: true,
                  controller: platzbuchungLink,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Link für TeamUp",
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              ElevatedButton(
                  onPressed: () async {
                    await signUp();
                  },
                  child: const Text("registrieren")),
            ],
          ),
          TextButton(
            onPressed: () {
              setState(() {
                registrieren = false;
              });
            },
            child: const Text(
              "Zurück zur Anmeldung",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: VereinAppbar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(color: Colors.white10),
                ),
                registrieren ? signUpWidget() : logInWidget(),
              ],
            ),
    );
  }
}
