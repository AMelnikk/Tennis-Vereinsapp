import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/admin_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: GridView(
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        children: [
          (Provider.of<AuthProvider>(context).userId ==
                  "G3cqTNYQNIQLbc3tXB0VDuDaon13")
              ? ClipRRect(
                borderRadius: BorderRadius.circular(5),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pushNamed(AdminScreen.routename);
                    },
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      child: const Text(
                        "Neuigkeiten hnzufügen",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                )
              : const Placeholder(),
        ],
      ),
    );
  }
}
