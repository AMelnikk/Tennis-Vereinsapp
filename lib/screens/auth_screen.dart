import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/verein_appbar.dart';
import '../models/http_exception.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  static const routeName = "/auth-screen";

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  var _isLoading = false;
  final email = TextEditingController();
  final password = TextEditingController();

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
      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VereinAppbar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(color: Colors.white10),
                ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: Colors.grey),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Text(
                          "Anmeldung",
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 10),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 10),
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
                          child: const Text("anmelden"))
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
