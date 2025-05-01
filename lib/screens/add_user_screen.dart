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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => loadData());
  }

  void loadData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider =
        Provider.of<AuthorizationProvider>(context, listen: false);
    userProvider.setToken(authProvider.writeToken.toString());
    await userProvider.getOwnUserData(authProvider.userId.toString());
    await userProvider.getAllUsers();
    setState(() {});
  }

  void _saveUser() async {
    final messenger = ScaffoldMessenger.of(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider =
        Provider.of<AuthorizationProvider>(context, listen: false);

    User newUser = User.empty();
    newUser.uid = _uid.text;
    newUser.vorname = _vornameController.text;
    newUser.nachname = _nachnameController.text;
    newUser.platzbuchungLink = _platzbuchungController.text;
    newUser.role = _selectedRole;

    setState(() => _isLoading = true);

    try {
      if (newUser.uid.isEmpty) {
        if (newUser.nachname.isEmpty || newUser.vorname.isEmpty) {
          appError(messenger, "Vorname und Nachname müssen ausgefüllt sein.");
          setState(() => _isLoading = false);
          return;
        }

        Map rData = await authProvider.signUp(
            "${newUser.nachname}_${newUser.vorname}@example.com", 'User@1234');
        newUser.uid = rData["localId"];
        _emailController.text =
            "${newUser.nachname}_${newUser.vorname}@example.com";
        await userProvider.postUser(context, newUser, rData["idToken"]);
      } else {
        await userProvider.postUser(
            context, newUser, authProvider.writeToken.toString());
      }

      await userProvider.getAllUsers();
      messenger
          .showSnackBar(const SnackBar(content: Text("Benutzer gespeichert")));
    } catch (error) {
      appError(messenger, "Fehler beim Anlegen des Users: $error");
    }

    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    final roleFilter = _selectedFilterRole;
    final nameFilter = _nameFilter.text;
    Provider.of<UserProvider>(context, listen: false)
        .getFilteredUsers(roleFilter, nameFilter);
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
          items: ["Mitglied", "Mannschaftsführer", "Abteilungsleitung", "Admin"]
              .map((role) => DropdownMenuItem(value: role, child: Text(role)))
              .toList(),
          onChanged: (value) => setState(() => _selectedRole = value!),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            ElevatedButton(
              onPressed: _saveUser,
              child: Text(
                  _uid.text.isNotEmpty ? "Update User" : "Neuen User anlegen"),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _uid.clear();
                  _emailController.clear();
                  _vornameController.clear();
                  _nachnameController.clear();
                  _platzbuchungController.clear();
                  _selectedRole = "Mitglied";
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: const Text("Reset"),
            ),
          ],
        ),
      ]),
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
              decoration: const InputDecoration(labelText: "Filter nach Name"),
              onChanged: (_) => _applyFilters(),
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
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget buildUserList(UserProvider userProvider) {
    // Benutzer alphabetisch nach Nachname, dann Vorname sortieren
    final users = userProvider.filteredUsers;

    // Sortieren nach Nachname und Vorname
    users.sort((a, b) {
      final aNachname = a.nachname.toLowerCase();
      final bNachname = b.nachname.toLowerCase();
      final nachnameCompare = aNachname.compareTo(bNachname);

      if (nachnameCompare != 0) {
        return nachnameCompare;
      } else {
        final aVorname = a.vorname.toLowerCase();
        final bVorname = b.vorname.toLowerCase();
        return aVorname.compareTo(bVorname);
      }
    });

    if (users.isEmpty) {
      return const Expanded(
        child: Center(child: Text("Keine Benutzer gefunden.")),
      );
    }

    return Expanded(
      child: ListView.separated(
        itemCount: users.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, index) {
          final user = users[index];
          return ListTile(
            title:
                Text('${user.nachname}, ${user.vorname}'), // Nachname, Vorname
            subtitle: Text('Berechtigung: ${user.role}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _uid.text = user.uid;
                      _vornameController.text = user.vorname;
                      _nachnameController.text = user.nachname;
                      _platzbuchungController.text = user.platzbuchungLink;
                      _emailController.text = user.email;
                      _selectedRole = [
                        "Mitglied",
                        "Admin",
                        "Abteilungsleitung",
                        "Mannschaftsführer"
                      ].contains(user.role)
                          ? user.role
                          : "Mitglied";
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
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

                    if (confirm == true) {
                      await userProvider.deleteUser(ctx, user.uid);
                      await userProvider.getAllUsers();
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
