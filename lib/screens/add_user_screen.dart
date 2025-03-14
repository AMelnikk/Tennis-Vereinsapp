import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/models/user.dart';
import 'package:verein_app/providers/auth_provider.dart';
import 'package:verein_app/utils/app_utils.dart';
import '../providers/user_provider.dart';
import '../widgets/verein_appbar.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});
  static const routename = "/add-user-screen";

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final TextEditingController _vornameController = TextEditingController();
  final TextEditingController _nachnameController = TextEditingController();
  final TextEditingController _platzbuchungController = TextEditingController();
  final TextEditingController _nameFilter = TextEditingController();
  final TextEditingController _uid = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _selectedRole = "Mitglied";
  String _selectedFilterRole = "Alle";
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      loadData();
    });
  }

  void loadData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider =
        Provider.of<AuthorizationProvider>(context, listen: false);
    userProvider.setToken(authProvider.writeToken.toString());
    await userProvider.getUserData(authProvider.userId.toString());
    userProvider.getAllUsers();
    setState(() {}); // UI wird aktualisiert
  }

  void _saveUser() async {
    final messenger = ScaffoldMessenger.of(context); // Vorher speichern
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider =
        Provider.of<AuthorizationProvider>(context, listen: false);

    // Benutzerdaten setzen
    User newUser = User.empty();

    newUser.uid = _uid.text;
    newUser.vorname = _vornameController.text;
    newUser.nachname = _nachnameController.text;
    newUser.platzbuchungLink = _platzbuchungController.text;
    newUser.role = _selectedRole;

    try {
      // **Warten, bis signUp abgeschlossen ist**
      if (newUser.uid.isEmpty) {
        if (newUser.nachname.isEmpty || newUser.vorname.isEmpty) {
          appError(messenger, "Vorname und Nachname müssen ausgefüllt sein.");
          return;
        }

        Map rData = await authProvider.signUp(
            "${newUser.nachname}_${newUser.vorname}@example.com", 'User@1234');
        newUser.uid = rData["localId"];
        userProvider.postUser(context, newUser, rData["idToken"]);
      } else {
        userProvider.postUser(
            context, newUser, authProvider.writeToken.toString());
      }
      // **Benutzer neu laden**
      userProvider.getAllUsers();
      setState(() {}); // UI wird aktualisiert
    } catch (error) {
      appError(messenger, "Fehler beim Anlegen des Users: $error");
    }
  }

  void _applyFilters() {
    Provider.of<UserProvider>(context, listen: false).getFilteredUsers(
        _selectedFilterRole == "Alle" ? "" : _selectedFilterRole,
        _nameFilter.text);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: VereinAppbar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                buildUserForm(userProvider),
                const SizedBox(height: 10),
                buildFilterSection(),
                const SizedBox(height: 10),
                buildUserList(userProvider),
              ],
            ),
    );
  }

  Widget buildUserForm(UserProvider userProvider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(labelText: "UID"),
            controller: _uid,
            enabled: false,
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _vornameController,
                  decoration: const InputDecoration(labelText: "Vorname"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _nachnameController,
                  decoration: const InputDecoration(labelText: "Nachname"),
                ),
              ),
            ],
          ),
          TextField(
            controller: _platzbuchungController,
            decoration: const InputDecoration(labelText: "Platzbuchungslink"),
          ),
          DropdownButton<String>(
            value: _selectedRole,
            items: [
              "Mitglied",
              "Mannschaftsführer",
              "Abteilungsleitung",
              "Admin"
            ]
                .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                .toList(),
            onChanged: (value) => setState(() => _selectedRole = value!),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton(
                onPressed: _saveUser,
                child: Text(_uid.text.isNotEmpty
                    ? "Update User"
                    : "Neuen User anlegen"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _uid.clear();
                    _vornameController.clear();
                    _nachnameController.clear();
                    _platzbuchungController.clear();
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                child: const Text("Reset"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nameFilter,
              decoration: const InputDecoration(labelText: "Filter by name"),
              onChanged: (_) => _applyFilters(), // Aufruf bei Änderung
            ),
          ),
          const SizedBox(width: 10),
          DropdownButton<String>(
            value: _selectedFilterRole,
            items: [
              "Alle",
              "Mitglied",
              "Mannschaftsführer",
              "Abteilungsleitung",
              "Admin"
            ]
                .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                .toList(),
            onChanged: (value) {
              setState(() => _selectedFilterRole = value!);
              _applyFilters(); // Aufruf nach Änderung
            },
          ),
          const SizedBox(width: 10),
          ElevatedButton(onPressed: _applyFilters, child: const Text("Filter")),
        ],
      ),
    );
  }

  Widget buildUserList(UserProvider userProvider) {
    return Expanded(
      child: ListView.builder(
        itemCount: userProvider.filteredUsers.length,
        itemBuilder: (ctx, index) {
          final line_user = userProvider.filteredUsers[index];
          return ListTile(
            title: Text('${line_user.vorname} ${line_user.nachname}'),
            subtitle: Text('Berechtigung: ${line_user.role}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    setState(() {
                      _uid.text = line_user.uid;
                      _vornameController.text = line_user.vorname;
                      _nachnameController.text = line_user.nachname;
                      _platzbuchungController.text = line_user.platzbuchungLink;

                      if ([
                        "Mitglied",
                        "Admin",
                        "Abteilungsleitung",
                        "Mannschaftsführer"
                      ].contains(line_user.role)) {
                        _selectedRole = line_user.role;
                      } else {
                        _selectedRole = "Mitglied"; // Fallback-Wert
                        print(
                            "⚠️ Unbekannte Rolle: ${line_user.role}, Standardwert 'Mitglied' gesetzt.");
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    bool confirm = await showDialog(
                      context: ctx,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Benutzer löschen"),
                        content: const Text(
                            "Möchtest du diesen Benutzer wirklich löschen?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text("Abbrechen"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text("Löschen",
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirm) {
                      await userProvider.deleteUser(ctx, line_user.uid);
                      await userProvider.getAllUsers(); // Liste aktualisieren
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
