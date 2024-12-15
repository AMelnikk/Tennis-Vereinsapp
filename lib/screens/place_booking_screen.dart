import 'package:flutter/material.dart';
import '../widgets/verein_appbar.dart';

class PlaceBookingScreen extends StatelessWidget {
  const PlaceBookingScreen({super.key});

  static const routename = "/place-booking-screen";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VereinAppbar(),
      body: const Center(
        child: Text("Platzbuchung"),
      ),
    );
  }
}
