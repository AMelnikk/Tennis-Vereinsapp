import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:verein_app/providers/user_provider.dart';
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
  didChangeDependencies() async {
    Uri placeBookingLink = Provider.of<UserProvider>(context)
                .user
                .platzbuchungLink ==
            null
        ? Uri.parse("https://teamup.com/ksz3fbg12qqbtpsm5o")
        : Uri.parse(
            Provider.of<UserProvider>(context).user.platzbuchungLink as String);
    if (kDebugMode) print(placeBookingLink);
    try {
      if (placeBookingLink.isAbsolute &&
          placeBookingLink.toString().startsWith("https://teamup.com")) {
        launchUrl(placeBookingLink);
      } else {
        launchUrl(Uri.parse("https://teamup.com/ksz3fbg12qqbtpsm5o"));
      }
    } catch (error) {
      if (kDebugMode) print(error);
    }

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
