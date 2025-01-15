import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/verein_appbar.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  static const routename = "/add-user-screen";

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  bool _isLoading = false;

  void showSnackBar(int responseStatusCode) {
    if (responseStatusCode < 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Erfolg! Die Neuigkeit wurde gepostet",
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Schade! Die Neuigkeit könnte nicht gepostet werden",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VereinAppbar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "Nutzer hinzufügen",
                      style: TextStyle(fontSize: 20),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: TextFormField(
                        decoration: const InputDecoration(
                          label: Text("User id"),
                        ),
                        controller: Provider.of<UserProvider>(context).uid,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: TextFormField(
                        decoration: const InputDecoration(
                          label: Text("Link für Platzbuchung"),
                        ),
                        controller: Provider.of<UserProvider>(context)
                            .platzbuchungLink,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: TextFormField(
                        decoration: const InputDecoration(
                          label: Text("Name"),
                        ),
                        controller: Provider.of<UserProvider>(context).name,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 30),
                      child: ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            _isLoading = true;
                          });

                          final responseStatusCode =
                              await Provider.of<UserProvider>(context,
                                      listen: false)
                                  .postUser();
                          setState(() {
                            _isLoading = false;
                          });

                          showSnackBar(responseStatusCode);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          width: double.infinity,
                          height: 50,
                          child: const Text(
                            "Nutzer hinzufügen",
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
