import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import '../models/notification.dart';
import '../screens/news_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _listenersInitialized = false;
  bool isDebug = false;

  // Statischer NavigatorKey
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  RemoteMessage? _pendingMessage; // Neue Zeile: gepufferte Nachricht

  Future initialize() async {
    // ---------------------------
    // 1. Berechtigungen anfordern
    // ---------------------------
    await _requestPermissions();

    // ---------------------------
    // 2. Lokale Notifications initialisieren
    // ---------------------------
    await _initializeLocalNotifications();

    // ---------------------------
    // 3. Foreground-Listener aktivieren
    // ---------------------------
    _listenForegroundMessages();

    // ---------------------------
    // 4. Realtime Database Listener starten
    // ---------------------------
    startDatabaseListener();

    // ---------------------------
    // 5. Topic nur auf NATIVE abonnieren
    // ---------------------------
    if (!kIsWeb) {
      await _firebaseMessaging.subscribeToTopic('notifications');
    }

    // ---------------------------
    // 6. Firebase Messaging Setup
    // ---------------------------
    setupFirebaseMessaging();

    // ---------------------------
    // 7. Falls eine Pending Notification existiert
    // ---------------------------
    processPendingMessage();
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) {
      // Web: Berechtigung anfordern. Kann fehlschlagen, wenn dauerhaft blockiert.
      try {
        await _firebaseMessaging.requestPermission();
      } on FirebaseException catch (e) {
        if (e.code == 'permission-blocked') {
          // Logik zur Benutzerführung auf der Webplattform
          if (kDebugMode) {
            print(
                '⚠️ Web Notification Permission BLOCKED. User must enable manually.');
          }
          // Zeige einen Dialog/Snackbar, um den Benutzer über die manuelle Freigabe zu informieren.
        } else {
          if (kDebugMode) {
            print('Fehler bei FCM Permission Request: ${e.code}');
          }
        }
      } catch (e) {
        if (kDebugMode) print('Unbekannter Fehler bei _requestPermissions: $e');
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS/macOS: Standardanfrage
      await _firebaseMessaging.requestPermission();
    } else {
      // Android/Desktop: Keine explizite Anfrage nötig, aber zur Sicherheit aufrufen
      await _firebaseMessaging.requestPermission();
    }
  }

// Navigation aus Message, sicher über navigatorKey
  void _navigateToNewsDetail(RemoteMessage message) {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushNamed(
        NewsDetailScreen.routename,
        arguments: message.data['id'], // ID oder andere Daten
      );
      _pendingMessage = null; // Nach Navigation leeren
    } else {
      _pendingMessage = message; // Nachricht puffern
      debugPrint(
          '⚠️ NavigatorKey noch nicht bereit. Nachricht gepuffert: ${message.data}');
    }
  }

  /// Neue Methode: Prüft gepufferte Nachricht nach dem ersten Frame
  void processPendingMessage() {
    if (_pendingMessage != null && navigatorKey.currentState != null) {
      _navigateToNewsDetail(_pendingMessage!);
    }
  }

  void setupFirebaseMessaging() {
// Foreground Nachrichten
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint("📩 Foreground message: ${message.messageId}");
      }
// Snackbar nur anzeigen, wenn Context verfügbar ist
      final context = navigatorKey.currentContext;
      if (context != null && message.notification != null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(message.notification!.title ?? 'Neue Nachricht')),
        );
      }
    });

    // App wurde aus Hintergrund durch Klick auf Notification geöffnet
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("📌 Notification angeklickt: ${message.messageId}");
      debugPrint("📌 Notification type: ${message.data['type']}");
      if (message.data['type'] == 'News') {
        _navigateToNewsDetail(message);
      }
    });

// Initial check, falls App durch Notification gestartet wurde
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _navigateToNewsDetail(message);
      }
    });
  }

// Top-level Background Handler (unverändert)
  Future firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    debugPrint('📩 Background message: ${message.messageId}');
  }

  Future _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 👇 Android Channel MUSS registriert werden!
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'foreground_channel',
      'Foreground Notifications',
      description: 'Benachrichtigungen, wenn App im Vordergrund ist',
      importance: Importance.high,
    );

    // Plugin holen
    final androidPlugin =
        _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Channel registrieren
    await androidPlugin?.createNotificationChannel(channel);

    // Initialisieren
    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) async {
        _handleLocalNotificationTap(response.payload);
      },
    );
  }

  /// Hört auf eingehende Foreground-Nachrichten
  void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
  }

  void _handleLocalNotificationTap(String? payload) {
    if (payload == null) return;

    try {
      final data = jsonDecode(payload);
      _navigateToNewsDetail(RemoteMessage(data: data));
    } catch (e) {
      debugPrint("❌ Fehler beim Parsen des Payloads: $e");
    }
  }

  /// Zeigt lokale Notification an
  Future _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'foreground_channel',
      'Foreground Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title ?? "Keine Überschrift",
      message.notification?.body ?? "",
      platformDetails,
      payload: jsonEncode(message.data),
    );
  }

  /// Startet Listener für Realtime Database
  void startDatabaseListener() {
    if (_listenersInitialized) return;
    _listenersInitialized = true;

    // NEWS – nur die letzten 20 Einträge beobachten
    final refNews = _database.ref("News").limitToLast(2);
    refNews.onChildAdded.listen((event) {
      _processEvent("News", "added", event);
    });
    refNews.onChildChanged.listen((event) {
      _processEvent("News", "changed", event);
    });

    // TERMINE – nur die nächsten Termine beobachten
    final refTermine = _database.ref("Termine/2025").limitToLast(2);
    refTermine.onChildAdded.listen((event) {
      _processEvent("Termine", "added", event);
    });
    refTermine.onChildChanged.listen((event) {
      _processEvent("Termine", "changed", event);
    });
  }

  /// Verarbeitet DB-Events
  Future _processEvent(String type, String action, DatabaseEvent event) async {
    // 1. Initialprüfung: Wenn keine Map, abbrechen.
    if (event.snapshot.value is! Map) return;

    final data = Map<String, dynamic>.from(event.snapshot.value as Map);
    TeGNotification?
        n; // Deklaration als nullable, um den "final variable can't be read" Fehler zu beheben

    // 2. Zuweisung über alle erkannten Pfade.
    if (type == "News") {
      n = TeGNotification(
        id: event.snapshot.key ?? "",
        type: "News",
        title: data["title"] ?? "Keine Nachricht",
        body: data["body"] ?? "",
        year: "",
        // Sicherstellung, dass der Zeitstempel ein int ist (wichtig!)
        timestamp: (data["lastUpdate"] as int?) ?? 0,
      );
    } else if (type == "Termine") {
      n = TeGNotification(
        id: data["id"].toString(),
        type: "Termin",
        title: data["title"] ?? "Kein Titel",
        body: data["details"] ?? "",
        year: event.snapshot.ref.parent?.key ?? "",
        timestamp: (data["lastUpdate"] as int?) ?? 0,
      );
    }

    // 3. Wichtiger Null-Check (behebt den Fehler "The final variable 'n' can't be read...")
    if (n == null) {
      if (kDebugMode) {
        debugPrint(
            'Unbekannter Event-Typ ($type) oder Datenfehler. Verarbeitung abgebrochen.');
      }
      return;
    }

    // AB HIER weiß der Compiler, dass n NICHT null ist.

    // 4. Entfernung der unnötigen Typ-Prüfung (behebt "Unnecessary type check...")
    // n.timestamp sollte gemäß dem Modell (final int) garantiert ein int sein.
    final currentTimestamp = n.timestamp;
    if (currentTimestamp == 0) return;

    final lastFetch = await _getLastFetchTime();

    // 1. Fall: App startet zum ersten Mal (lastFetch == 0)
    // 1. Fall: App startet zum ersten Mal (lastFetch == 0)
    if (lastFetch == 0) {
      // Der erste von Vieren setzt den Wert. Alle nachfolgenden Aufrufe von _saveLastFetchTime
      // werden ignoriert, wenn ihr timestamp niedriger ist.
      await _saveLastFetchTime(timestamp: currentTimestamp);

      if (isDebug) {
        debugPrint(
            '⚠️ Initialisierung abgeschlossen. Erster Event verarbeitet.');
      }
      return; // Verarbeitung abbrechen, da dies nur Initialisierung ist.
    }

    // 2. Fall: Reguläre Prüfung (lastFetch > 0)
    else if (currentTimestamp > lastFetch) {
      // Nur senden, wenn die Nachricht wirklich neuer ist als der letzte gespeicherte Wert.
      await sendPushNotification(n);
      await _saveLastFetchTime(timestamp: currentTimestamp);
    } else {
      if (isDebug) {
        debugPrint('ℹ️ "added" Event ignoriert: Zeitstempel zu alt.');
      }
    }
  }

  Future<void> _saveLastFetchTime(
      {required int timestamp, bool forceUpdate = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final oldTime = prefs.getInt("lastFetchTime") ?? 0;

    if (timestamp > oldTime || forceUpdate) {
      prefs.setInt("lastFetchTime", timestamp);
      if (isDebug) {
        debugPrint('🕑 Neue lastFetchTime gespeichert: $timestamp');
      }
    } else {
      // Bei asynchronen Aufrufen wird der ältere Zeitstempel ignoriert.
      if (isDebug) {
        debugPrint(
            '🕑 Speicherung ignoriert: $timestamp ist nicht neuer als $oldTime');
      }
    }
  }

  Future _getLastFetchTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("lastFetchTime") ?? 0;
  }

  /// Sendet Push an Topic 'notifications'
  Future sendPushNotification(TeGNotification notifi) async {
    String? token;

    // 1. Token-Abruf in einem try-catch-Block absichern.
    // Dies fängt den "permission-blocked"-Fehler ab, der auf dem Web
    // beim Versuch, das Token abzurufen, auftritt.
    try {
      token = await _firebaseMessaging.getToken();
    } on FirebaseException catch (e) {
      // <-- Jetzt funktioniert es mit dem Import
      if (kIsWeb && e.code == 'permission-blocked') {
        // Erwarteter Fehler, wenn Berechtigung im Browser blockiert ist.
        if (kDebugMode) {
          debugPrint(
              "⚠️ Token-Abruf blockiert (Web). Senden abgebrochen. (Fehler: ${e.code})");
        }
        return; // Senden abbrechen
      }
      // Andere Firebase-Fehler
      if (kDebugMode) print('Fehler beim Abrufen des Tokens: ${e.code}');
      return;
    } catch (e) {
      // Unbekannte Fehler abfangen
      if (kDebugMode) print('Unbekannter Fehler beim Abrufen des Tokens: $e');
      return;
    }

    if (token == null || token.isEmpty) {
      return; // Weiter nur, wenn Token vorhanden
    }
    // Access Token für FCM HTTP v1 holen
    final accessToken = await _getAccessToken();
// FCM Endpoint
    final url = Uri.parse(
        "https://fcm.googleapis.com/v1/projects/db-teg/messages:send");

// Payload für sichtbare Notification auf Android + iOS
    final payload = {
      "message": {
        "topic": "notifications",
        "notification": {"title": notifi.title, "body": notifi.body},
        "data": {
          "title": notifi.title,
          "type": notifi.type,
          "body": notifi.body,
          "year": notifi.year,
          "id": notifi.id,
        },
        "android": {
          "priority": "high",
          "collapse_key": "${notifi.type}-update-${notifi.id}",
          "notification": {
            "channel_id": "default_channel",
            "sound": "default",
            "click_action": "FLUTTER_NOTIFICATION_CLICK"
          }
        },
        "apns": {
          "headers": {"apns-priority": "10"},
          "apns-collapse-id": "${notifi.type}-update-${notifi.id}",
          "payload": {
            "aps": {
              "alert": {"title": notifi.title, "body": notifi.body},
              "sound": "default",
              "badge": 1,
              "category": "FLUTTER_NOTIFICATION_CLICK"
            }
          }
        }
      }
    };

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $accessToken",
        "Content-Type": "application/json"
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      debugPrint("✅ Push erfolgreich gesendet: ${notifi.title}");
    } else {
      debugPrint("❌ Fehler beim Senden: ${response.body}");
    }
  }

  /// Holt AccessToken aus ServiceAccount
  Future<String?> _getAccessToken() async {
    final jsonStr = await rootBundle.loadString('assets/service-account.json');
    final data = jsonDecode(jsonStr);
    final credentials = ServiceAccountCredentials.fromJson(data);
    final client = await clientViaServiceAccount(
        credentials, ['https://www.googleapis.com/auth/firebase.messaging']);
    return client.credentials.accessToken.data;
  }
}
