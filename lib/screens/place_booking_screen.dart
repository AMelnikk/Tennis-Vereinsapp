import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../widgets/verein_appbar.dart';

class PlaceBookingScreen extends StatefulWidget {
  const PlaceBookingScreen({super.key});

  static const routename = "/place-booking-screen";

  @override
  State<PlaceBookingScreen> createState() => _PlaceBookingScreenState();
}

class _PlaceBookingScreenState extends State<PlaceBookingScreen> {
  @override
  didChangeDependencies() {
    Uri placeBookingLink = Provider.of<AuthProvider>(context)
                .placeBookingLink ==
            null
        ? Uri.parse("https://teamup.com/ksz3fbg12qqbtpsm5o")
        : Uri.parse(
            Provider.of<AuthProvider>(context).placeBookingLink as String);
            print(placeBookingLink);
    launchUrl(placeBookingLink);
    Navigator.of(context).pop();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VereinAppbar(),
      body: Scaffold(
        appBar: VereinAppbar(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
