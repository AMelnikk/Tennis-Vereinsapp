// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/models/chat_member.dart';
import 'package:verein_app/providers/user_provider.dart';
import '../providers/team_chat_provider.dart';
import '../models/chat_message.dart';

class TeamChatScreen extends StatelessWidget {
  static const routename = '/team-chat';
  const TeamChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sicherstellen, dass der Provider für Änderungen beobachtet wird (listen: true)
    final chatProvider = Provider.of<TeamChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team A Chat & Admin'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: chatProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                // Responsive Layout: Nebeneinander auf großen Bildschirmen, untereinander auf Mobile
                if (constraints.maxWidth > 800) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          flex: 1,
                          child: _buildMemberManagementPanel(
                              context, chatProvider)),
                      Expanded(
                          flex: 2,
                          child: _buildGroupChatPanel(context, chatProvider)),
                    ],
                  );
                } else {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildMemberManagementPanel(context, chatProvider),
                        SizedBox(
                          height: MediaQuery.of(context).size.height *
                              0.6, // Chat nimmt den größten Teil ein
                          child: _buildGroupChatPanel(context, chatProvider),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
    );
  }

  // 1. --- Widget: Mitgliederverwaltung ---
  Widget _buildMemberManagementPanel(
      BuildContext context, TeamChatProvider provider) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final TextEditingController uidController = TextEditingController();
    // NEU: Controller für den DisplayNamen, da wir diesen nun speichern können
    final TextEditingController displayNameController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Mitgliederverwaltung',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: theme.primaryColor)),
              const Divider(),
              Text('Ihre UID: ${userProvider.user.uid}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),

              const SizedBox(height: 16),
              // Eingabe UID
              TextField(
                controller: uidController,
                decoration: const InputDecoration(
                  labelText: 'Mitglied UID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              // NEU: Eingabe DisplayName (optional)
              TextField(
                controller: displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Anzeigename (für Hinzufügen)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      onPressed: () => _handleMemberAction(
                          context,
                          provider,
                          uidController.text,
                          displayNameController
                              .text, // NEU: Übergabe des DisplayNames
                          true),
                      child: const Text('Hinzufügen',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => _handleMemberAction(
                          context,
                          provider,
                          uidController.text,
                          '', // DisplayName ist beim Entfernen irrelevant
                          false),
                      child: const Text('Entfernen',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // NEU: Iteration über TeamMemberDetail-Objekte
              Text('Aktive Mitglieder (${provider.members.length}):',
                  style: theme.textTheme.titleMedium),
              const Divider(height: 10),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: provider.members.values
                      // Filtern nach 'active' Status (optional, da der Provider
                      // in listenToMembers standardmäßig alle Einträge liefert)
                      .where((member) => member.active)
                      .map((member) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        // Anzeige des DisplayName und der UID
                        '${member.displayName} (${member.userId})',
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.black87),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. --- Widget: Gruppen-Chat ---
  Widget _buildGroupChatPanel(BuildContext context, TeamChatProvider provider) {
    final theme = Theme.of(context);
    final TextEditingController messageController = TextEditingController();
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    bool isMember = true; //!provider.isMember(userProvider.user.uid);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('Team A Gruppen-Chat',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: theme.primaryColor)),
              const Divider(),
              // Chat-Nachrichten Liste
              Expanded(
                child: ListView.builder(
                  // Liste ist im Provider bereits von alt nach neu sortiert
                  reverse: false,
                  itemCount: provider.messages.length,
                  itemBuilder: (ctx, i) {
                    final message = provider.messages[i];
                    return _buildChatBubble(
                        context, message, userProvider.user.uid);
                  },
                ),
              ),

              // Nachrichteneingabe
              if (isMember)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                      'Sie sind kein Mitglied und können nicht chatten.',
                      style: TextStyle(color: Colors.red)),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      enabled: (isMember),
                      decoration: InputDecoration(
                        hintText: isMember
                            ? 'Nachricht eingeben...'
                            : 'Kein Chat-Zugriff',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      onSubmitted: isMember
                          ? (_) => _handleSendMessage(
                              context, provider, messageController)
                          : null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: theme.primaryColor,
                    onPressed: isMember
                        ? () => _handleSendMessage(
                            context, provider, messageController)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. --- UI Helfer: Chat Bubble ---
  // NEU: Kontext als erster Parameter hinzugefügt, um Theme korrekt zu laden
  Widget _buildChatBubble(
      BuildContext context, ChatMessage message, String currentUserId) {
    final isSender = message.userId == currentUserId;
    // KORRIGIERT: Theme korrekt aus dem Kontext geladen
    final theme = Theme.of(context);

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSender ? theme.primaryColor : Colors.grey.shade300,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft:
                isSender ? const Radius.circular(15) : const Radius.circular(5),
            bottomRight:
                isSender ? const Radius.circular(5) : const Radius.circular(15),
          ),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isSender)
              Text(
                // KORRIGIERT: Anzeigename statt UID für bessere UX
                message.userName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Colors.black54),
              ),
            Text(
              message.text,
              style: TextStyle(color: isSender ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                  fontSize: 9,
                  color: isSender ? Colors.white70 : Colors.black45),
            ),
          ],
        ),
      ),
    );
  }

  // 4. --- Controller Logik ---

  void _handleMemberAction(BuildContext context, TeamChatProvider provider,
      String uid, String displayName, bool isAdding) async {
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bitte geben Sie eine UID ein.'),
          backgroundColor: Colors.orange));
      return;
    }

    // KORRIGIERT: Erstellen des TeamMemberDetail-Objekts für den Provider-Aufruf
    final memberToUpdate = TeamMemberDetail(
      userId: uid,
      // Verwenden des übergebenen DisplayName oder einen Fallback,
      // da der Provider ihn zum Speichern benötigt.
      displayName: displayName.isNotEmpty ? displayName : 'Admin User',
      // Der Status 'active' wird im Provider überschrieben (true beim Hinzufügen,
      // der Eintrag wird beim Entfernen gelöscht)
      active: isAdding,
    );

    try {
      // KORRIGIERT: Übergabe des TeamMemberDetail-Objekts
      await provider.updateGroupMember(memberToUpdate, isAdding);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Mitglied ${memberToUpdate.displayName} ${uid} erfolgreich ${isAdding ? 'hinzugefügt' : 'entfernt'}.'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      debugPrint('Member Action Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Fehler bei der Mitglieder-Aktion: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _handleSendMessage(BuildContext context, TeamChatProvider provider,
      TextEditingController controller) async {
    // 1. UserProvider (Muss listen: false sein, da wir nur die Daten abrufen)
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final String messageText = controller.text.trim();

    if (messageText.isEmpty) return;

    // Prüfen auf notwendige User-Daten
    final String currentUserId = userProvider.user.uid;
    final String currentUserName = userProvider.user.vorname;

    if (currentUserId == null) {
      // Optional: Fehlerbehandlung, falls der Benutzer nicht authentifiziert ist
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Fehler: Benutzer-ID nicht verfügbar.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // 2. ERSTELLUNG des TeamMemberDetail-Objekts
    final memberDetail = TeamMemberDetail(
      userId: currentUserId,
      displayName: currentUserName,
      // Der 'active' Status ist für das Senden unwichtig, wird aber vom Modell benötigt.
      active: true,
    );

    try {
      // 3. Aufruf der sendMessage Methode mit dem erstellten Objekt
      await provider.sendMessage(memberDetail, messageText);

      controller.clear();
    } catch (e) {
      debugPrint('Senden fehlgeschlagen: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Fehler beim Senden: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    }
  }
}
