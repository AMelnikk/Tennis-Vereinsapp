import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/providers/auth_provider.dart';
import 'package:verein_app/widgets/verein_appbar.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  static const routeName = "/auth-screen";

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

enum AuthMode { signIn, signUp }

class _AuthScreenState extends State<AuthScreen> {
  var authMode = AuthMode.signIn;

  Future<void> signup() async {
    await Provider.of<AuthProvider>(context, listen: false)
        .signup("fagerst9@gmail.com", "1412412214");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VereinAppbar(),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(color: Colors.white10),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Colors.lightBlue),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      authMode == AuthMode.signIn
                          ? "Anmeldung"
                          : "Registration",
                      style: const TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
