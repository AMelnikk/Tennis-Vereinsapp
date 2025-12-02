// ignore_for_file: use_build_context_synchronously, unnecessary_brace_in_string_interps, unnecessary_type_check

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/models/calendar_event_registration.dart';
import 'package:verein_app/providers/user_provider.dart';
import 'package:verein_app/utils/app_utils.dart';
import 'package:verein_app/utils/ui_dialog_utils.dart';
import '../models/calendar_event.dart';
import 'package:collection/collection.dart';
import '../widgets/registration_action_buttons.dart';

/// Zeigt ein modales Dialogfenster mit allen Details eines Kalenderereignisses an.
void showCalendarEventDetails(BuildContext context, CalendarEvent event) {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final int acceptedCount = event.allRegistrations
      .where((reg) => reg.status == true)
      .map((reg) =>
          reg.peopleCount ??
          1) // Nimm 1 als Standardwert, falls peopleCount null ist
      .fold(0, (sum, count) => sum + count); // Summiere die Werte

  // final int declinedCount =
  //    event.allRegistrations.where((reg) => reg.status == false).length;

  // 1. REGISTRIERUNGSSTATUS DES AKTUELLEN USERS PRÜFEN
  final EventRegistration? currentUserRegistration =
      event.allRegistrations.firstWhereOrNull(
    (reg) => reg.userId == userProvider.user.uid,
  );

  // Prüft, ob der User überhaupt registriert ist (unabhängig von status: true/false)
  final bool isUserAccepted = currentUserRegistration?.status == true;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 360,
          constraints: const BoxConstraints(maxHeight: 650),
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 💡 AUFRUF 1: Titel und Schließen-Button
              buildDialogTitleBar(dialogContext, event.title),

              // 💡 AUFRUF 2: Untertitel (Kategorie & Datum)
              buildDialogSubtitleBar(
                textLeft: event.category,
                textRight: DateFormat('dd.MM.yyyy').format(event.date),
              ),
              const Divider(height: 1, thickness: 1, color: Colors.black12),
              const SizedBox(height: 12),
              // 2. Scrollbarer Detailbereich (mit _buildDetailField)
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Anzeige des Zeitraums
                      buildDetailField(
                          "Zeitraum", "${event.von} - ${event.bis}"),

                      // Anzeige der Beschreibung
                      if (event.description.isNotEmpty)
                        buildDetailField("Details", event.description,
                            maxLines: 5),

                      // Anzeige des Ortes
                      if (event.ort.isNotEmpty)
                        buildDetailField("Ort", event.ort),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- 3. Aktion (NEU: Nur Icons & Zähler wie auf der Karte) ---
              RegistrationActionButtons(
                dialogContext: dialogContext,
                event: event,
                isUserLoggedIn: userProvider.user.uid.isNotEmpty,
                isUserAccepted: isUserAccepted,
                acceptedCount: acceptedCount,
              ),
            ],
          ),
        ),
      );
    },
  );
}
