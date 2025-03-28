import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/termine_provider.dart';
import '../widgets/verein_appbar.dart';
import '../models/termin.dart';

class TerminDetailScreen extends StatefulWidget {
  static const routename = '/termin-detail';

  const TerminDetailScreen({super.key});

  @override
  TerminDetailScreenState createState() => TerminDetailScreenState();
}

class TerminDetailScreenState extends State<TerminDetailScreen> {
  Termin? curTermin;
  bool? _isAdmin;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final terminID = ModalRoute.of(context)?.settings.arguments as String?;
    if (terminID != null && terminID.isNotEmpty) {
      Provider.of<TermineProvider>(context, listen: false)
          .loadTerminForYear(2025, terminID)
          .then((termin) {
        if (mounted) {
          setState(() {
            curTermin = termin;
          });
        }
      }).catchError((error) {
        // print("Fehler beim Laden des Termins: $error");
      });
    }

    _loadAdminStatus();
  }

  Future<void> _loadAdminStatus() async {
    bool isAdmin = await Provider.of<UserProvider>(context, listen: false)
        .isAdmin(context);
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (curTermin == null) {
      return Scaffold(
        appBar: VereinAppbar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: VereinAppbar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${curTermin!.date.day}.${curTermin!.date.month}.${curTermin!.date.year}",
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          curTermin!.title,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          curTermin!.description,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 20),
                        if (_isAdmin == true)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                onPressed: () {
                                  // Hier könnte die Bearbeitungslogik für Termine integriert werden
                                },
                                icon: const Icon(Icons.edit_rounded),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
