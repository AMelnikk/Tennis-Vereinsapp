// ignore_for_file: unnecessary_type_check, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/models/calendar_event_registration.dart';
import 'package:verein_app/models/user.dart'; // Benötigt für User-Objekt in der Registrierungsliste
import 'package:verein_app/providers/termine_provider.dart';
import 'package:verein_app/providers/user_provider.dart';
import 'package:verein_app/utils/app_utils.dart'; // Angenommen: showConfirmationSnackbar, showErrorSnackbar
import 'package:verein_app/utils/ui_dialog_utils.dart';
import '../models/calendar_event.dart';
import 'package:collection/collection.dart';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:csv/csv.dart';
import 'dart:convert';

class RegistrationActionButtons extends StatelessWidget {
  final BuildContext dialogContext;
  final CalendarEvent event;
  final bool isUserLoggedIn;
  final bool isUserAccepted;
  final int acceptedCount;

  const RegistrationActionButtons({
    super.key,
    required this.dialogContext,
    required this.event,
    required this.isUserLoggedIn,
    required this.isUserAccepted,
    required this.acceptedCount,
  });

  // Funktion: Zeigt einen Dialog an, wenn der Benutzer nicht eingeloggt ist
  // Die Methode, die Sie gesucht haben:
  void _showLoginRequiredDialog(BuildContext context) {
    // context ist der Kontext des RegistrationActionButtons Widgets
    // dialogContext (aus der Klasse) ist der Kontext des showCalendarEventDetails Dialogs

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: buildDialogTitleBar(context, 'Anmeldung erforderlich'),
        content: buildDialogBodyText(
            'Um dich für Veranstaltungen an- oder abzumelden, musst du dich registrieren oder anmelden.'),
        actions: [
          // KORREKTUR: Nutzung des buildButton Helpers für "Zur Registrierung"
          buildButton(
            'Zur Registrierung',
            () {
              // 1. Schließt den aktuellen Login-Dialog (context)
              Navigator.of(context).pop();

              // 2. Schließt den Haupt-Event-Detail-Dialog (dialogContext der Klasse)
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }

              // 3. Navigiert zum AuthScreen.
              Navigator.of(dialogContext).pushNamed(
                  '/auth-screen', // 💡 WICHTIG: Route zu Ihrer Anmelde-Seite anpassen!
                  arguments: {'mode': 'signup'});
            },
          ),

          // KORREKTUR: Nutzung des buildButton Helpers für "Schließen"
          // HINWEIS: Manchmal wird der sekundäre Button in Dialogen als TextButton belassen.
          // Hier wird er als ElevatedButton ausgeführt, um der Anfrage zu entsprechen.
          buildButton(
            'Schließen',
            () => Navigator.of(context).pop(), // Schließt nur den Login-Dialog
          ),
        ],
      ),
    );
  }

  // Funktion: Liefert den Callback für Aktionen (Zusage/Zähler)
  VoidCallback? _getAction(VoidCallback loggedInAction) {
    if (isUserLoggedIn) {
      return loggedInAction;
    }
    // Übergibt den Kontext des Widgets an den Dialog
    return () => _showLoginRequiredDialog(dialogContext);
  }

  // Funktion: Liefert den Callback für die Absage-Aktion
  VoidCallback? _getDeclineAction() {
    if (!isUserLoggedIn) {
      return () =>
          _showLoginRequiredDialog(dialogContext); // Zeigt den Login-Dialog
    }
    // Wenn eingeloggt, aber nicht zugesagt: Keine Aktion (null)
    if (!isUserAccepted) {
      return null;
    }
    // Wenn eingeloggt und zugesagt: Zeige den Abmelde-Dialog
    return () => _showDeclineDialog(dialogContext, event);
  }

  @override
  Widget build(BuildContext context) {
    // Zeigt die Buttons nur an, wenn Registrierung für das Event aktiviert ist
    if (event.query != 'Ja') {
      return const SizedBox
          .shrink(); // Nichts anzeigen, wenn Registrierung deaktiviert
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. ZUSAGE / BEARBEITEN ICON (Nutzt _getAction)
          GestureDetector(
            onTap: _getAction(
              () => _showRegistrationDialog(dialogContext, event),
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUserAccepted ? Icons.edit : Icons.check_circle,
                    color: isUserAccepted ? Colors.blue.shade700 : Colors.green,
                    size: 30,
                  ),
                  Text(
                    isUserAccepted ? 'Bearbeiten' : 'Zusage',
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          isUserAccepted ? Colors.blue.shade700 : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. ABSAGE ICON (Nutzt _getDeclineAction)
          GestureDetector(
            onTap: _getDeclineAction(),
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.close,
                // KORRIGIERTE LOGIK: Rot nur, wenn eingeloggt UND zugesagt
                color:
                    isUserAccepted && isUserLoggedIn ? Colors.red : Colors.grey,
                size: 30,
              ),
            ),
          ),

          // 3. ZÄHLER FÜR GESAMT-ZUSAGEN (Nutzt _getAction)
          TextButton(
            onPressed: _getAction(
              () => _showRegistrationsList(dialogContext, event, 'ALLE'),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  acceptedCount.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.people_alt,
                  color: Colors.red,
                  size: 24,
                ),
                const Icon(
                  Icons.check,
                  color: Colors.red,
                  size: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Funktion für die Anmeldung (JA) mit Dialog
void _showRegistrationDialog(BuildContext context, CalendarEvent event) {
  final terminProvider = Provider.of<TermineProvider>(context, listen: false);
  final userProvider = Provider.of<UserProvider>(context, listen: false);

  final currentUserId = userProvider.user.uid;

  final personController = TextEditingController(text: '1');
  final bringController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: buildDialogTitleBar(context, 'Anmeldung bestätigen'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              buildDialogSubtitleBar(
                  textLeft: 'Für diesen Arbeitseinsatz anmelden:',
                  textRight: ''),

              // Eingabe: Anzahl der Personen (Nutzung der Hilfsklasse)
              // HINWEIS: Padding wurde in der buildTextFormField-Signatur angepasst
              buildTextFormField(
                'Anzahl Personen (inkl. dir)',
                controller: personController,
                keyboardType: TextInputType.number,
                icon: const Icon(Icons.people),
                padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
              ),

              // Eingabe: Bemerkung: Was bringst du mit? (Nutzung der Hilfsklasse)
              buildTextFormField(
                'Bemerkung (Personen, Wir bringen mit...)',
                controller: bringController,
                icon: const Icon(Icons.work),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          // Sekundäre Aktion: Abbrechen (als TextButton beibehalten für UX)
          TextButton(
            child: const Text('Abbrechen'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          // Primäre Aktion: Anmelden (Nutzung der Hilfsklasse buildButton)
          buildButton(
            'Anmelden',
            () async {
              final peopleCount = int.tryParse(personController.text) ?? 1;
              final whatToBring = bringController.text;

              final newRegistration = EventRegistration(
                registrationId: "${event.id}_$currentUserId",
                terminId: event.id,
                userId: currentUserId,
                status: true, // Zusage
                peopleCount: peopleCount,
                itemsBrought: whatToBring.trim().isEmpty ? null : whatToBring,
                timestamp: DateTime.now(),
              );

              final success =
                  await terminProvider.saveRegistration(newRegistration);

              if (!context.mounted) return;

              if (success) {
                // Lokales Event-Objekt für UI-Update aktualisieren
                final updatedRegistrations =
                    List<EventRegistration>.from(event.allRegistrations);

                updatedRegistrations
                    .removeWhere((reg) => reg.userId == currentUserId);
                updatedRegistrations.add(newRegistration);
                event.allRegistrations = updatedRegistrations;
                terminProvider.updateEvent(event);

                // Dialoge schließen (innerer Dialog, dann äußerer Detail-Dialog)
                Navigator.of(context).pop(); // Schließt Anmelde-Dialog
                Navigator.of(context)
                    .pop(); // Schließt den äußeren Dialog (der dieses Widget enthielt)

                // Haupt-Detail-Dialog neu öffnen, um den aktualisierten Status anzuzeigen
                showCalendarEventDetails(dialogContext, event);

                showConfirmation(dialogContext,
                    'Sie sind erfolgreich für ${event.title} angemeldet!');
              } else {
                Navigator.of(context).pop(); // Schließt den inneren Dialog
                showError(dialogContext, event.title);
              }
            },
          ),
        ],
      );
    },
  );
}

// Interne Abmeldefunktion, die die Daten speichert und UI aktualisiert
void _handleDecline(
    BuildContext dialogContext, // 💡 Kontext des Haupt-Detail-Dialogs!
    CalendarEvent event,
    int peopleCount,
    String? comment) async {
  final terminProvider =
      Provider.of<TermineProvider>(dialogContext, listen: false);
  final userProvider = Provider.of<UserProvider>(dialogContext, listen: false);

  final currentUserId = userProvider.user.uid;

  final declineRegistration = EventRegistration(
    registrationId: "${event.id}_$currentUserId",
    terminId: event.id,
    userId: currentUserId,
    status: false, // Wichtig: Status ist 'false' für Ablehnung
    peopleCount: peopleCount,
    itemsBrought: comment,
    timestamp: DateTime.now(),
  );

  final success = await terminProvider.saveRegistration(declineRegistration);

  // Context-Gültigkeit prüfen, bevor er verwendet wird.
  if (!dialogContext.mounted) {
    return;
  }

  if (success) {
    // Event-Objekt im Provider aktualisieren
    final updatedRegistrations =
        List<EventRegistration>.from(event.allRegistrations);

    updatedRegistrations.removeWhere((reg) => reg.userId == currentUserId);
    updatedRegistrations.add(declineRegistration);

    event.allRegistrations = updatedRegistrations;
    terminProvider.updateEvent(event);

    // Feedback geben
    ScaffoldMessenger.of(dialogContext).showSnackBar(
      SnackBar(
        content: Text('Sie haben den Termin ${event.title} abgemeldet.'),
        backgroundColor: Colors.orange,
      ),
    );

    // Den Haupt-Detail-Dialog schließen
    Navigator.of(dialogContext).pop();

    final mainContext =
        dialogContext; // Dies ist der Kontext des Widgets, das den Dialog gestartet hat.

    if (mainContext.mounted) {
      showCalendarEventDetails(
          mainContext, event); // Nutzt den Kontext der Hauptseite
    }

    // Den Haupt-Detail-Dialog neu öffnen, um die aktualisierten Zähler/Status zu zeigen
    showCalendarEventDetails(dialogContext, event);
  } else {
    // Fehlerbehandlung
    showError(dialogContext, event.title);
  }
}

// Dialog für die Absage (NEIN)
void _showDeclineDialog(BuildContext context, CalendarEvent event) {
  final dialogContext = context;

  final peopleController = TextEditingController(text: '1');
  final commentController = TextEditingController();

  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final currentUserId = userProvider.user.uid;
  final currentRegistration = event.allRegistrations.firstWhere(
    (reg) => reg.userId == currentUserId,
    // Fallback für den Fall, dass keine Registrierung gefunden wird
    orElse: () => EventRegistration(
        registrationId: '',
        terminId: event.id,
        userId: currentUserId,
        status: false,
        peopleCount: 1,
        itemsBrought: null,
        timestamp: DateTime.now()),
  );

  // Setze die Controller-Werte basierend auf der letzten Zusage
  peopleController.text = (currentRegistration.peopleCount ?? 1).toString();
  commentController.text = currentRegistration.itemsBrought ?? '';

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: buildDialogTitleBar(context, 'Termin absagen'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              buildDialogBodyText(
                  'Bitte bestätigen Sie die Angaben für die Absage:'),

              // ANZAHL PERSONEN
              buildTextFormField(
                'Anzahl Personen (abgemeldet)',
                controller: peopleController,
                keyboardType: TextInputType.number,
                icon: const Icon(Icons.people_alt_outlined),
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              ),

              // BEMERKUNG
              buildTextFormField(
                'Bemerkung (optional)',
                controller: commentController,
                icon: const Icon(Icons.comment),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          // KORREKTUR: buildButton für Abbrechen verwenden (mit neutraler Farbe)
          buildButton(
            'Abbrechen',
            () {
              Navigator.of(dialogContext).pop(); // Schließt den inneren Dialog
            },
          ),
          // KORREKTUR: buildButton verwenden (mit roter Farbe)
          buildButton(
            'Abmelden',
            () {
              // Validierung
              final peopleCount = int.tryParse(peopleController.text) ?? 0;
              final comment = commentController.text.trim().isEmpty
                  ? null
                  : commentController.text.trim();

              if (peopleCount < 1) {
                // KORREKTUR: Snackbar für Fehlermeldung
                showWarning(
                    context, 'Die Anzahl der Personen muss mindestens 1 sein.');
                return;
              }

              // Den inneren Dialog schließen, bevor die asynchrone Speicherung beginnt
              Navigator.of(context).pop();

              // Die asynchrone Logik ausführen
              _handleDecline(dialogContext, event, peopleCount, comment);
            },
          ),
        ],
      );
    },
  );
}

/// Öffnet einen Dialog, der alle Anmeldungen für das Event anzeigt.
void _showRegistrationsList(
    BuildContext context, CalendarEvent event, String filterStatus) async {
  final List<EventRegistration> allRegistrations = event.allRegistrations;
  final userProvider = Provider.of<UserProvider>(context, listen: false);

  // 1. Ladehinweis anzeigen
  final OverlayEntry loadingEntry = showLoadingOverlay(context);

  // 2. Alle benötigten UIDs identifizieren
  final Set<String> uidsToFetch =
      allRegistrations.map((reg) => reg.userId).toSet();

  // 3. Alle User-Daten asynchron abrufen und in einer lokalen Map speichern
  final Map<String, User> userMap = {};

  // Parallel alle User-Daten abrufen
  final futures = uidsToFetch.map((uid) async {
    final User? user = await userProvider.getUserData(uid);
    if (user != null) {
      userMap[uid] = user;
    }
  }).toList();

  await Future.wait(futures);

  // 4. Ladehinweis entfernen
  loadingEntry.remove();

  // 5. Filtern und Sortieren (Zusagen vor Absagen)
  final List<EventRegistration> sortedRegistrations =
      allRegistrations.where((reg) => reg.status is bool).toList()
        ..sort((a, b) {
          if (a.status == true && b.status == false) return -1;
          if (a.status == false && b.status == true) return 1;
          return 0;
        });

  // Gesamtzahl der zugesagten Personen berechnen
  final int acceptedPeopleCount = sortedRegistrations
      .where((r) => r.status)
      .fold(0, (sum, r) => sum + (r.peopleCount ?? 0));

  // 6. Dialog synchron anzeigen und die gefüllte Map übergeben
  showDialog(
    context: context,
    builder: (listDialogContext) {
      return AlertDialog(
        title: buildDialogTitleBar(
            listDialogContext, 'Anmeldungen für: ${event.title}'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: sortedRegistrations.isEmpty
              ? buildDialogSubtitleBar(
                  textLeft: 'Keine Anmeldungen vorhanden.', textRight: '')
              : ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Header mit Zusammenfassung
                    buildDialogSubtitleBar(
                        textLeft: 'Angemeldete Personen:',
                        textRight: '$acceptedPeopleCount'),
                    const Divider(height: 1),
                    // Liste der Anmeldungen
                    ..._buildRegistrationContent(sortedRegistrations, userMap),
                  ],
                ),
        ),
        actions: <Widget>[
          // Export Button (Syntax korrigiert)
          buildButton(
            'CSV Export',
            () {
              // Den aktuellen Anmeldungs-Dialog schließen
              Navigator.of(listDialogContext).pop();

              _exportRegistrationsToCsv(
                  context, event, sortedRegistrations, userMap);
            },
            icon: const Icon(Icons.download), // Icon übergeben
          ),
          // Schließen Button
          buildButton(
            'Schließen',
            () => Navigator.of(listDialogContext).pop(),
          ),
        ],
      );
    },
  );
}

/// Erzeugt den kompletten Inhalt der Liste inklusive Überschriften und Trennlinien.
List<Widget> _buildRegistrationContent(
    List<EventRegistration> registrations, Map<String, User> userMap) {
  final List<Widget> listItems = [];
  bool isShowingAccepts = true;

  // Starte mit der Überschrift "Zusagen"
  listItems.add(_buildSectionHeader('Zusagen'));
  listItems.add(_buildTableHeader());

  for (final reg in registrations) {
    if (isShowingAccepts && reg.status == false) {
      listItems.add(const Divider(height: 20, thickness: 2));
      listItems.add(_buildSectionHeader('Absagen'));
      listItems.add(_buildTableHeader());
      isShowingAccepts = false;
    }

    final User? user = userMap[reg.userId];
    final String userName;
    if (user != null && user.nachname.isNotEmpty) {
      userName = '${user.nachname}, ${user.vorname}';
    } else {
      userName = 'User ID: ${reg.userId}';
    }

    listItems.add(_buildTableRow(userName, reg));
  }

  return listItems;
}

/// Generiert die Sektionen-Überschrift ("Zusagen" / "Absagen")
Widget _buildSectionHeader(String title) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    color: Colors.grey[300],
    alignment: Alignment.center,
    child: Text(
      title,
      style: const TextStyle(
          fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
    ),
  );
}

/// Generiert die Kopfzeile der Tabelle ("Name", "Anzahl Personen", "Bemerkung")
Widget _buildTableHeader() {
  return const Padding(
    padding: EdgeInsets.only(top: 8.0, bottom: 4.0, left: 16.0, right: 16.0),
    child: Row(
      children: [
        Expanded(
            flex: 4,
            child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(
            flex: 2,
            child: Text('Anzahl Personen',
                style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(
            flex: 3,
            child: Text('Bemerkung',
                style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    ),
  );
}

/// Generiert eine Datenzeile der Tabelle
Widget _buildTableRow(String name, EventRegistration reg) {
  final String peopleCount = (reg.peopleCount ?? 1).toString();
  final String note =
      reg.itemsBrought?.isNotEmpty == true ? reg.itemsBrought! : '-';

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    child: DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(name)),
          Expanded(flex: 2, child: Text(peopleCount)),
          Expanded(flex: 3, child: Text(note)),
        ],
      ),
    ),
  );
}

Future<void> _exportRegistrationsToCsv(
    BuildContext context,
    CalendarEvent event,
    List<EventRegistration> registrations,
    Map<String, User> userMap) async {
  // 1. Daten für CSV-Tabelle vorbereiten
  List<List<dynamic>> rows = [];
  // Wichtig: Nutzen des Semikolons (';') als Trennzeichen für europäische Excel-Kompatibilität
  rows.add(['Status', 'Nachname', 'Vorname', 'Anzahl Personen', 'Bemerkung']);
  for (final reg in registrations) {
    final User? user = userMap[reg.userId];
    final String nachname = user?.nachname ?? 'Unbekannt';
    final String vorname = user?.vorname ?? 'User';
    final String status = reg.status == true ? 'Zusage' : 'Absage';
    final int peopleCount = reg.peopleCount ?? 1;
    final String comment = reg.itemsBrought ?? '-';
    rows.add([status, nachname, vorname, peopleCount, comment]);
  }

  // 2. CSV-String generieren (Semikolon als Trennzeichen)
  final String csvString = const ListToCsvConverter(
    fieldDelimiter: ';',
    textDelimiter: '"',
    eol: '\n',
  ).convert(rows);

  final String filename = 'Anmeldungen_${event.title.replaceAll(' ', '_')}.csv';

  // 3. Speichern über das file_saver Paket
  try {
    // Hinzufügen des BOM (Byte Order Mark) für korrekte Excel-Darstellung von UTF-8
    final List<int> utf8Bytes = utf8.encode(csvString);
    const List<int> bom = [0xEF, 0xBB, 0xBF];
    final Uint8List bytesWithBom = Uint8List.fromList([...bom, ...utf8Bytes]);

    await FileSaver.instance.saveFile(
      name: filename,
      bytes: bytesWithBom,
      ext: 'csv',
      mimeType: MimeType.csv,
    );

    // Feedback
    if (context.mounted) {
      // 💡 VERBESSERTES FEEDBACK: Sagt dem Benutzer, wo er auf Android suchen muss
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Anmeldeliste erfolgreich als CSV exportiert. Bitte suchen Sie die Datei im Downloads-Ordner (oder in den Benachrichtigungen).'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  } catch (e) {
    debugPrint('Exportfehler: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Fehler beim Export: $e'),
            backgroundColor: Colors.red),
      );
    }
  }
}

// =========================================================================
// 3. HAUPTFUNKTION: showCalendarEventDetails
// =========================================================================

/// Zeigt ein modales Dialogfenster mit allen Details eines Kalenderereignisses an.
void showCalendarEventDetails(BuildContext context, CalendarEvent event) {
  // Helfer, um ein ReadOnly-Feld für die Details zu erstellen
  Widget buildDetailField(String label, String value, {int maxLines = 1}) {
    // Verwendet die definierte buildTextFormField
    return buildTextFormField(
      label,
      controller: TextEditingController(text: value),
      readOnly: true,
      maxLines: maxLines,
      padding: const EdgeInsets.only(bottom: 8.0),
    );
  }

  final String formattedDate = DateFormat('dd.MM.yyyy').format(event.date);

  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final isUserLoggedIn = userProvider.user.uid.isNotEmpty;
  final int acceptedCount = event.allRegistrations
      .where((reg) => reg.status == true)
      .map((reg) =>
          reg.peopleCount ??
          1) // Nimm 1 als Standardwert, falls peopleCount null ist
      .fold(0, (sum, count) => sum + count); // Summiere die Werte

  // 1. REGISTRIERUNGSSTATUS DES AKTUELLEN USERS PRÜFEN
  final EventRegistration? currentUserRegistration =
      event.allRegistrations.firstWhereOrNull(
    (reg) => reg.userId == userProvider.user.uid,
  );

  // Prüft, ob der User registriert ist und zugesagt hat
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
              // 1. TITEL: Nutzung der vereinbarten HELFERFUNKTION
              buildDialogTitleBar(dialogContext, event.title),

              // 2. UNTERTITEL: Nutzung der vereinbarten HELFERFUNKTION
              buildDialogSubtitleBar(
                textLeft: event.category,
                textRight: formattedDate,
              ),

              const Divider(height: 1, thickness: 1, color: Colors.black12),
              const SizedBox(height: 12),

              // 3. Scrollbarer Detailbereich
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

              // --- 4. Aktion (RegistrationActionButtons) ---
              RegistrationActionButtons(
                dialogContext: dialogContext,
                event: event,
                isUserLoggedIn: isUserLoggedIn,
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
