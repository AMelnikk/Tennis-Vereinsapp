import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/providers/auth_provider.dart';
import 'package:verein_app/utils/app_utils.dart';
import '../providers/user_provider.dart';
import '../widgets/verein_appbar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});
  static const routename = "/user-profile-screen";

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final TextEditingController _vornameController = TextEditingController();
  final TextEditingController _nachnameController = TextEditingController();
  final TextEditingController _platzbuchungController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _selectedRole = "Mitglied";
  String _uid = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => loadData());
  }

  void loadData() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
    final authProvider =
        Provider.of<AuthorizationProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      // Hole Benutzerdaten und die E-Mail-Adresse
      await userProvider.getOwnUserData(authProvider.userId.toString());
      final email = await userProvider.fetchOwnEmail();

      setState(() {
        _uid = userProvider.user.uid;
        _vornameController.text = userProvider.user.vorname;
        _nachnameController.text = userProvider.user.nachname;
        _platzbuchungController.text = userProvider.user.platzbuchungLink;
        _emailController.text = email.toString(); // Setze die E-Mail korrekt
        _selectedRole = userProvider.user.role;
      });
    } catch (error) {
      // Fehlerbehandlung, z.B. anzeigen einer Fehlermeldung
      appError(messenger, 'Fehler beim Laden der Daten: $error');
    }

    setState(() => _isLoading = false);
  }

  void _saveUser() async {
    final messenger = ScaffoldMessenger.of(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider =
        Provider.of<AuthorizationProvider>(context, listen: false);

    userProvider.user.uid = _uid.toString();
    userProvider.user.vorname = _vornameController.text.toString();
    userProvider.user.nachname = _nachnameController.text.toString();
    userProvider.user.platzbuchungLink =
        _platzbuchungController.text.toString();
    userProvider.user.role = _selectedRole.toString();

    try {
      userProvider.postUser(
          context, userProvider.user, authProvider.writeToken.toString());
      appError(messenger, "Daten erfolgreich gespeichert.");
    } catch (error) {
      appError(messenger, "Fehler beim Speichern: $error");
    }
  }

  void _resetPassword() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider =
        Provider.of<AuthorizationProvider>(context, listen: false);

    // 1. Asynchrone Operation, die einen await erfordert:
    // Hier könnte der Kontext ungültig werden.
    await authProvider.resetPassword(context, userProvider.user.email);

    // 2. WICHTIGE KORREKTUR: mounted Check
    // Prüfen Sie, ob das Widget noch aktiv ist, bevor Sie den Kontext verwenden.
    // Dies setzt voraus, dass sich diese Methode in einem State-Objekt befindet.
    if (!context.mounted) return;
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Passwort-Reset-E-Mail gesendet.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return Scaffold(
      appBar: VereinAppbar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: "UID"),
                    controller: TextEditingController(text: _uid),
                    enabled: false,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: "E-Mail"),
                    controller: _emailController,
                    enabled: false,
                  ),
                  TextField(
                    controller: _vornameController,
                    decoration: const InputDecoration(labelText: "Vorname"),
                  ),
                  TextField(
                    controller: _nachnameController,
                    decoration: const InputDecoration(labelText: "Nachname"),
                  ),
                  TextField(
                    controller: _platzbuchungController,
                    decoration:
                        const InputDecoration(labelText: "Platzbuchungslink"),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _saveUser,
                        child: const Text("Speichern"),
                      ),
                      const SizedBox(width: 10),
                      if (userProvider.user.email.isNotEmpty) ...[
                        ElevatedButton(
                          onPressed: _resetPassword,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text("Passwort zurücksetzen"),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              //                             final result = await sendMail(
                              //                                 to: "fefef",
                              //                                 subject: "efefeff",
                              //                                 text: "3434");
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text("Unbekannter Fehler: $e"),
                                ),
                              );
                            }
                          },
                          child: const Text("Getränkebuchung per Mail senden"),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> sendMail({
    required String to,
    required String subject,
    required String text,
  }) async {
    final url = Uri.parse(
        'https://us-central1-tennis-vereinsapp.cloudfunctions.net/sendMail');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'to': to,
        'subject': subject,
        'text': text,
      }),
    );

    if (response.statusCode == 200) {
      debugPrint('Mail erfolgreich gesendet!');
    } else {
      debugPrint('Fehler beim Senden der Mail: ${response.body}');
    }
  }
}
