import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:verein_app/models/chat_member.dart';
import '../models/chat_message.dart'; // Sie müssen dieses Modell erstellen oder anpassen

// Konstanten für die Firestore-Pfade (Bleiben unverändert)
const String _groupId = 'verein_team_a';
const String _memberDocPathBase =
    'artifacts/YOUR_APP_ID/public/data/groups_members/$_groupId';
const String _messagesCollectionPathBase =
    'artifacts/YOUR_APP_ID/public/data/group_chat/$_groupId/messages';

class TeamChatProvider with ChangeNotifier {
  // Typ-Änderung: Mitglieder-Map speichert nun die geparsten Objekte
  // Map<UID, TeamMemberDetail>
  // Die doppelte Deklaration und der alte Typ wurden entfernt.
  Map<String, TeamMemberDetail> _members = {};
  List<ChatMessage> _messages = [];

  // Der Getter muss auch auf den neuen Typ umgestellt werden
  Map<String, TeamMemberDetail> get members => _members;
  List<ChatMessage> get messages => _messages;

  // Die restlichen Status-Variablen bleiben
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  final String? _writeToken;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _membersSubscription;
  StreamSubscription? _messagesSubscription;

  // Pfade werden beim Erstellen des Providers initialisiert
  late final String _memberDocPath;
  late final String _messagesCollectionPath;

  TeamChatProvider(this._writeToken, String _appId) {
    _memberDocPath = _memberDocPathBase.replaceFirst('YOUR_APP_ID', _appId);
    _messagesCollectionPath =
        _messagesCollectionPathBase.replaceFirst('YOUR_APP_ID', _appId);

    _listenToMembers();
    _listenToMessages();
  }

  // --- Realtime Listeners ---

  void _listenToMembers() {
    _membersSubscription?.cancel();
    _membersSubscription =
        _firestore.doc(_memberDocPath).snapshots().listen((docSnap) {
      if (docSnap.exists && docSnap.data() != null) {
        final Map<String, dynamic> data = docSnap.data()!;
        // Gehen Sie davon aus, dass die Mitglieder-Daten direkt auf der obersten Ebene
        // des Dokuments oder unter einem spezifischen Schlüssel liegen.
        // Falls die Struktur so aussieht: { 'members': { 'uid1': { ... }, 'uid2': { ... } } }
        final Map<String, dynamic> membersData =
            Map<String, dynamic>.from(data['members'] ?? {});

        final Map<String, TeamMemberDetail> parsedMembers = {};

        // Iterieren Sie über die denormalisierte Map und parsen Sie jeden Eintrag
        membersData.forEach((userId, memberJson) {
          // Sicherstellen, dass memberJson eine Map ist (für den Fall, dass es null ist)
          if (memberJson is Map<String, dynamic>) {
            // Wir verwenden den Factory-Constructor
            parsedMembers[userId] = TeamMemberDetail.fromDenormalizedJson(
              userId,
              memberJson,
            );
          }
        });

        _members = parsedMembers;
      } else {
        _members = {};
      }

      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      debugPrint("❌ Firestore Fehler bei Mitglieder-Stream: $error");
      _isLoading = false;
      notifyListeners();
    });
  }

  void _listenToMessages() {
    _messagesSubscription?.cancel();
    // Sortierung nach Zeitstempel
    final q = _firestore
        .collection(_messagesCollectionPath)
        .orderBy('timestamp', descending: true)
        .limit(50);

    _messagesSubscription = q.snapshots().listen((snapshot) {
      _messages = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return ChatMessage(
              id: doc.id,
              userId: data['userId'] ?? '',
              userName: data['userName'] ?? 'Unbekannt',
              text: data['text'] ?? 'Nachricht fehlt',
              timestamp:
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          })
          .toList()
          .reversed
          .toList(); // Neueste Nachrichten unten

      if (_messages.isNotEmpty) _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      debugPrint("❌ Firestore Fehler bei Chat-Stream: $error");
      _messages = [];
      notifyListeners();
    });
  }

  Future<void> updateGroupMember(TeamMemberDetail member, bool isAdding) async {
    // 1. Hole die userId aus dem übergebenen Objekt
    final String userId = member.userId;

    // Optional: Logging zum Debuggen
    debugPrint(
        '➡️ Starte updateGroupMember für User: $userId, Aktion: ${isAdding ? "Hinzufügen" : "Entfernen"}');

    // Autorisierungsprüfung
    if (_writeToken == null) {
      debugPrint('❌ Fehler: Fehlendes Token.');
      throw Exception("Nicht autorisiert: Fehlendes Token.");
    }

    if (userId.isEmpty) {
      debugPrint('❌ Fehler: UID ist leer.');
      throw Exception("UID darf nicht leer sein.");
    }

    final memberDocRef = _firestore.doc(_memberDocPath);

    // ***************************************************************
    // 🚨 KORREKTUR: Der gesamte Transaktions-Block muss HIER beginnen
    // ***************************************************************
    return _firestore.runTransaction((transaction) async {
      debugPrint('   [TX] Transaktion gestartet/neu gestartet.');
      debugPrint('   [TX] Prüfe Dokumentpfad: ${memberDocRef.path}');

      // ⬇️ Wichtigster Punkt: Dokument innerhalb der Transaktion lesen ⬇️
      final docSnap = await transaction.get(memberDocRef);

      debugPrint(
          '   [TX] Dokument ERFOLGREICH gelesen. Existiert: ${docSnap.exists}');

      // Die gelesene Map muss vom Typ <String, dynamic> sein
      Map<String, dynamic> membersData = docSnap.exists
          ? Map<String, dynamic>.from(docSnap.data()?['members'] ?? {})
          : {};

      debugPrint(
          '   [TX] Aktuelle Mitglieder-Anzahl vor Änderung: ${membersData.length}');

      if (isAdding) {
        // Hinzufügen/Aktivieren:
        final Map<String, dynamic> memberJson = {
          'displayName': member.displayName,
          'active': true, // explizit auf true beim Hinzufügen
        };

        // Der gesamte Eintrag wird unter der userId in die membersData Map gesetzt
        membersData[userId] = memberJson;
        debugPrint(
            '   [TX] Mitglied $userId (${member.displayName}) wird HINZUGEFÜGT/AKTIVIERT.');
      } else {
        // Entfernen: Hard-Delete des Eintrags
        membersData.remove(userId);
        debugPrint('   [TX] Mitglied $userId wird ENTFERNT.');
      }

      // Speichern der aktualisierten Mitglieder-Map als serialisierte JSON-Struktur
      transaction.set(memberDocRef, {'members': membersData});

      debugPrint(
          '   [TX] Transaktion erfolgreich abgeschlossen. Neue Anzahl: ${membersData.length}');
      // 🚨 KORREKTUR: Hier schließt die runTransaction-Methode ab.
    });
// 🚨 KORREKTUR: Hier schließt die updateGroupMember-Methode ab.
  }

  bool isMember(String userId) {
    // 1. Prüfe, ob der Schlüssel (userId) in der _members Map existiert.
    // 2. Prüfe, ob das Mitglied-Objekt (TeamMemberDetail) aktiv ist.
    return _members.containsKey(userId) && _members[userId]!.active;
  }

  Future<void> sendMessage(TeamMemberDetail member, String text) async {
    // Stellen Sie sicher, dass dieser Getter im Provider korrekt ist
    // und den Mitgliedsstatus des aktuellen Benutzers überprüft.

    if (text.trim().isEmpty) return;

    final messagesColRef = _firestore.collection(_messagesCollectionPath);

    // Wichtige Annahme: Der aktuelle Benutzer (`_currentUserId`) und der Anzeigename
    // müssen beim Senden der Nachricht in Firestore gespeichert werden.
    // Der Anzeigename wird hier noch nicht dynamisch geholt, daher verwenden wir
    // den in _listenToMessages definierten Fallback, falls er in Firestore nicht da ist.
    // Optimal wäre es, wenn der UserProvider den displayName hält.

    await messagesColRef.add({
      'userId': member.userId,
      'text': text.trim(),
      'userName': member.displayName, // Fügt den Anzeigenamen hinzu
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
