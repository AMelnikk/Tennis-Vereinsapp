import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Eigene Imports
import 'package:verein_app/providers/auth_provider.dart';
import 'package:verein_app/providers/getraenkebuchen_provider.dart';
import 'package:verein_app/utils/app_utils.dart';
import '../providers/user_provider.dart';
import '../widgets/verein_appbar.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});
  static const routename = "/user-profile-screen";

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // -------------------------
  // 1. Controller & State Variablen
  // -------------------------
  final TextEditingController _vornameController = TextEditingController();
  final TextEditingController _nachnameController = TextEditingController();
  final TextEditingController _platzbuchungController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _selectedRole = "Mitglied";
  String _uid = "";

  // Allgemeiner Ladezustand für die gesamte Seite
  bool _isLoading = true;
  // Separater Ladezustand für Aktionen (Speichern, Senden, Reset)
  bool _isActionLoading = false;

  double _getraenkeSaldo = 0.0; // Anzeige des aktuellen Saldos

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData());
  }

  @override
  void dispose() {
    _vornameController.dispose();
    _nachnameController.dispose();
    _platzbuchungController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // -------------------------
  // 2. Daten laden (_loadData)
  // -------------------------
  void _loadData() async {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isLoading = true;
      _isActionLoading = false;
    });

    final authProvider = context.read<AuthorizationProvider>();
    final userProvider = context.read<UserProvider>();
    final getraenkeProvider = context.read<GetraenkeBuchenProvider>(); // Neu

    try {
      // 1. Benutzerdaten holen
      await userProvider.getOwnUserData(authProvider.userId.toString());
      final String? email = await userProvider.fetchOwnEmail();

      // 2. Getränke-Saldo holen
      // Setze die UID im Getränke-Provider, da dieser sie für die Filterung braucht
      getraenkeProvider.uid = userProvider.user.uid;
      getraenkeProvider.username =
          "${userProvider.user.vorname} ${userProvider.user.nachname}";
      final saldo = await getraenkeProvider.calculateUserSaldo();

      if (!mounted) return;
      // UI-Update
      setState(() {
        _uid = userProvider.user.uid;
        _vornameController.text = userProvider.user.vorname;
        _nachnameController.text = userProvider.user.nachname;
        _platzbuchungController.text = userProvider.user.platzbuchungLink;
        _emailController.text = email ?? '';
        _selectedRole = userProvider.user.role;
        _getraenkeSaldo = saldo; // Saldo zuweisen
      });
    } catch (error) {
      if (!mounted) return;
      appError(messenger, 'Fehler beim Laden der Daten: $error');
    }

    setState(() => _isLoading = false);
  }

  // -------------------------
  // 3. Benutzerdaten speichern (_saveUser)
  // -------------------------
  void _saveUser() async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final userProvider = context.read<UserProvider>();
    final authProvider = context.read<AuthorizationProvider>();

    setState(() => _isActionLoading = true);

    // Update der Daten im UserProvider-Objekt
    userProvider.user.uid = _uid;
    userProvider.user.vorname = _vornameController.text;
    userProvider.user.nachname = _nachnameController.text;
    userProvider.user.platzbuchungLink = _platzbuchungController.text;
    userProvider.user.role = _selectedRole;

    try {
      await userProvider.postUser(
          context, userProvider.user, authProvider.writeToken.toString());

      if (!mounted) return;
      appError(messenger, "Daten erfolgreich gespeichert.");
    } catch (error) {
      if (!mounted) return;
      appError(messenger, "Fehler beim Speichern: $error");
    }

    setState(() => _isActionLoading = false);
  }

  // -------------------------
  // 4. Passwort zurücksetzen (_resetPassword)
  // -------------------------
  void _resetPassword() async {
    if (!mounted) return;
    final authProvider = context.read<AuthorizationProvider>();
    final userProvider = context.read<UserProvider>();

    setState(() => _isActionLoading = true);

    // Prüfen, ob die E-Mail verfügbar ist
    if (userProvider.user.email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("E-Mail-Adresse fehlt.")),
      );
      setState(() => _isActionLoading = false);
      return;
    }

    await authProvider.resetPassword(context, userProvider.user.email);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Passwort-Reset-E-Mail gesendet.")),
    );

    setState(() => _isActionLoading = false);
  }

  // -------------------------
  // 5. Getränkebuchung per Mail senden (_sendGetraenkeMail)
  // -------------------------
  void _sendGetraenkeMail() async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final userProvider = context.read<UserProvider>();

    setState(() => _isActionLoading = true);

    // Vorbereitung der Daten
    final recipient = _emailController.text;
    final name = "${userProvider.user.vorname} ${userProvider.user.nachname}";
    final saldoText = '${_getraenkeSaldo.toStringAsFixed(2)} €';

    final subject = "Abrechnungsanfrage Getränkesaldo für $name";
    final textBody =
        "Hallo,\n\nhiermit bitte ich um die Abrechnung des aktuellen Getränkesaldos von $saldoText für $name.\n\nViele Grüße,\n${userProvider.user.vorname}";

    if (recipient.isEmpty) {
      if (!mounted) return;
      appError(messenger, "E-Mail-Adresse fehlt für den Versand.");
      setState(() => _isActionLoading = false);
      return;
    }

    try {
      await _sendMail(
        to: recipient,
        subject: subject,
        text: textBody,
      );
      if (!mounted) return;
      appError(messenger, "Abrechnungs-E-Mail erfolgreich gesendet.");
    } catch (e) {
      if (!mounted) return;
      appError(messenger, "Fehler beim Senden der E-Mail: $e");
    }

    setState(() => _isActionLoading = false);
  }

  // -------------------------
  // 6. API-Aufruf (_sendMail) - bleibt unverändert
  // -------------------------
  Future<void> _sendMail({
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

    if (response.statusCode != 200) {
      throw Exception(
          'Serverfehler (${response.statusCode}): ${response.body}');
    }
  }

  // -------------------------
  // 7. BUILD METHODE (UI)
  // -------------------------
  @override
  Widget build(BuildContext context) {
    // Lesen des Providers hier nur für die Bedingung in der UI (z.B. user.email.isNotEmpty)
    // Es ist besser, wenn wir die State-Variablen _emailController.text verwenden.

    return Scaffold(
      appBar: VereinAppbar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              // ✅ Äußere Stack hat die Größe des gesamten Bildschirms
              children: [
                // 1. Der gesamte scrollbare Inhalt (fängt den Platz)
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- Basisdaten ---
                        _buildHeader("Basisinformationen 👤"),
                        buildTextFormField(
                          "E-Mail",
                          controller: _emailController,
                          readOnly: true,
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0), // Padding reduziert
                        ),

                        // --- Bearbeitbare Felder: Vorname und Nachname nebeneinander ---
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: buildTextFormField(
                                "Vorname",
                                controller: _vornameController,
                                readOnly: false,
                                padding: const EdgeInsets.only(
                                    right: 4.0,
                                    top: 4.0,
                                    bottom: 4.0), // Padding reduziert
                              ),
                            ),
                            Expanded(
                              child: buildTextFormField(
                                "Nachname",
                                controller: _nachnameController,
                                readOnly: false,
                                padding: const EdgeInsets.only(
                                    left: 4.0,
                                    top: 4.0,
                                    bottom: 4.0), // Padding reduziert
                              ),
                            ),
                          ],
                        ),

                        // --- Platzbuchungslink mit Info ---
                        buildTextFormField(
                          "Platzbuchungslink - TeamUp Link wird vom Admin bereitgestellt",
                          controller: _platzbuchungController,
                          readOnly: false,
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0), // Padding reduziert
                        ),

                        // --- Rollen-Anzeige ---
                        buildTextFormField(
                          "Rolle",
                          controller:
                              TextEditingController(text: _selectedRole),
                          readOnly: true,
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0), // Padding reduziert
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isActionLoading ? null : _saveUser,
                                icon: const Icon(Icons.save),
                                label: const Text("Speichern"),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // --- Getränkesumme Sektion ---
                        _buildHeader("Getränke-Saldo 🍺"),
                        _buildSaldoCard(context),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isActionLoading || _getraenkeSaldo > 0
                                        ? null
                                        : _sendGetraenkeMail,
                                icon: const Icon(Icons.email),
                                label: const Text("Abrechnung senden"),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Passwort-Reset-Button (nur anzeigen, wenn eine E-Mail verfügbar ist)
                        if (_emailController.text.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: _isActionLoading ? null : _resetPassword,
                            icon: const Icon(Icons.lock_reset),
                            label: const Text("Passwort zurücksetzen"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),

                // 2. Lade-Overlay über die gesamte UI (muss außerhalb der Column sein)
                if (_isActionLoading)
                  Positioned.fill(
                    // ✅ Positioned.fill füllt den gesamten Stack
                    child: Opacity(
                      opacity: 0.8,
                      child: ModalBarrier(
                          dismissible: false, color: Colors.black12),
                    ),
                  ),
                if (_isActionLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }

  // -------------------------
  // 8. Hilfswidgets für die UI
  // -------------------------
  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 15.0, 0, 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  // Widget für die Saldo-Anzeige
  Widget _buildSaldoCard(BuildContext context) {
    // Farbe basierend auf dem Saldo
    Color saldoColor = _getraenkeSaldo < 0
        ? Colors.red.shade700
        : (_getraenkeSaldo > 0 ? Colors.green.shade700 : Colors.black87);
    String saldoLabel = _getraenkeSaldo < 0 ? "Schulden:" : "Guthaben:";

    // Saldo in positive Zahl umwandeln, wenn es Schulden sind
    double displaySaldo = _getraenkeSaldo.abs();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(saldoLabel,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 5),
            Text(
              '${displaySaldo.toStringAsFixed(2)} €',
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: saldoColor),
            ),
            const Divider(height: 20),
            Text(
              _getraenkeSaldo < 0
                  ? 'Bitte begleichen Sie Ihren negativen Saldo.'
                  : (_getraenkeSaldo > 0
                      ? 'Sie haben ein Guthaben auf Ihrem Getränkekonto.'
                      : 'Ihr Saldo ist ausgeglichen.'),
              style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600),
            )
          ],
        ),
      ),
    );
  }
}
