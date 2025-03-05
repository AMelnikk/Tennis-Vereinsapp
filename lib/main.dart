import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/screens/user_profile_screen.dart';
import 'package:verein_app/utils/push_notification_service';
import './providers/season_provider.dart';
import './models/notification.dart';
import './providers/termine_provider.dart';
import './screens/add_termine_screen.dart';
import './screens/getraenke_summen_screen.dart';
import './screens/news_screen.dart';
import './providers/getraenkebuchen_provider.dart';
import './screens/getraenkedetails_screen.dart';
import './screens/datenschutz_screen.dart';
import './screens/getraenkebuchen_screen.dart';
import './providers/user_provider.dart';
import './providers/team_result_provider.dart';
import './screens/add_user_screen.dart';
import './screens/impressum_screen.dart';
import './screens/news_detail_screen.dart';
import './providers/news_provider.dart';
import 'screens/add_photo_screen.dart';
import './screens/add_news_screen.dart';
import './screens/admin_screen.dart';
import './screens/add_team_game_screen.dart';
import './screens/add_team_result.dart';
import './screens/place_booking_screen.dart';
import './providers/auth_provider.dart';
import './providers/photo_provider.dart';
import './screens/auth_screen.dart';
import 'screens/photo_gallery_screen.dart';
import './screens/trainers_screen.dart';
import "./providers/team_provider.dart";
import './screens/documents_screen.dart';
import './screens/functions_screen.dart';
import './screens/team_screen.dart';
import './screens/more_screen.dart';
import './widgets/verein_appbar.dart';
import "./screens/add_team_screen.dart";
import "./screens/team_detail_screen.dart";
import "./screens/calendar_screen.dart";
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart'; // Firebase-Optionen
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void handleNotificationClick(String? payload) async {
  print("🏷️ Benachrichtigung angeklickt, Payload: $payload");

  if (payload != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Hole den aktuellen Navigator Context direkt aus der aktiven Route
      BuildContext? context = navigatorKey.currentContext;

      if (context != null) {
        try {
          // Teile den Payload in Typ und ID auf
          var parts = payload.split('|');
          String type = parts[0];  // Der Typ (z. B. "News" oder "Termin")
          String id = parts[1];    // Die ID (z. B. "123")

          // Hier die Navigation entsprechend dem Typ
          if (type == "News") {
            Navigator.pushNamed(
              context,
              NewsDetailScreen.routename,
              arguments: id,  // Die ID für die News
            );
          } else if (type == "Termin") {
            // Navigator.pushNamed(
            //   context,
            //   TerminDetailScreen.routename,
            //   arguments: id,  // Die ID für den Termin
            // );
          } else {
            print("❌ Unbekannter Typ im Payload: $type");
          }
        } catch (e) {
          print("❌ Fehler beim Laden der Benachrichtigung: $e");
        }
      } else {
        print("❌ Kein gültiger Navigator-Kontext.");
      }
    });
  } else {
    print("❌ Ungültiges Payload.");
  }
}

void checkForNotificationLaunch() async {
  final details =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  if (details?.didNotificationLaunchApp ?? false) {
    String? payload = details?.notificationResponse?.payload;
    if (payload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handleNotificationClick(payload);
      });
    }
  }
}

Future<void> setupPushNotifications() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await PushNotificationService().initialize();

    // Lokale Benachrichtigungen konfigurieren
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          handleNotificationClick(response.payload!);
        }
      },
    );

    final user = FirebaseAuth.instance.currentUser;
    print("✅ Firebase Auth erfolgreich initialisiert!");
    print("👤 Aktueller Nutzer: ${user?.email}");
  } catch (e) {
    print("❌ Fehler beim Firebase-Start: $e");
  }
}
Future<void> setupNewsNotificationListeners() async {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print("📩 Nachricht empfangen: ${message.data['title']}");

    String type = message.data['type'] ?? '';
    String id = message.data['id'] ?? '';

    if (id.isNotEmpty && navigatorKey.currentContext != null) {
      if (type == "News") {
        await Navigator.pushNamed(
          navigatorKey.currentContext!,
          NewsDetailScreen.routename,
          arguments: id,
        );
      } else if (type == "Termin") {
        // await Navigator.pushNamed(
        //   navigatorKey.currentContext!,
        //   TerminDetailScreen.routename, // Beispiel: Detailseite für Termine
        //   arguments: id,
        // );
      }
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    print("📩 Nachricht empfangen onMessageOpenedApp: ${message.data['title']}");

    String type = message.data['type'] ?? '';
    String id = message.data['id'] ?? '';

    if (id.isNotEmpty && navigatorKey.currentContext != null) {
      if (type == "News") {
        await Navigator.pushNamed(
          navigatorKey.currentContext!,
          NewsDetailScreen.routename,
          arguments: id,
        );
      } else if (type == "Termin") {
        // await Navigator.pushNamed(
        //   navigatorKey.currentContext!,
        //   TerminDetailScreen.routename, // Beispiel: Detailseite für Termine
        //   arguments: id,
        // );
      }
    }
  });
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("🏁 App startet...");

  await setupPushNotifications(); // Nur Firebase-Setup, keine Listener hier

  await initializeDateFormatting('de_DE', null);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MyApp());

  await setupNewsNotificationListeners(); // Jetzt direkt nach runApp() aufrufen
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    print("Hintergrundnachricht empfangen: ${message.data}");

    // Stelle sicher, dass die Daten vorhanden sind
    String type = message.data['type'] ?? '';
    String newsId = message.data['id'] ?? '';
    String title = message.data['title'] ?? '';
    String body = message.data['body'] ?? '';

    if (newsId.isEmpty) {
      print("🔴 Keine gültige News-ID oder Benachrichtigungsdetails gefunden");
      return;
    }

    // Erstelle eine Notification-Instanz
    TeGNotification notification = TeGNotification(
      id: newsId,
      type: type, // Hier kannst du den Typ der Nachricht anpassen
      title: title,
      body: body,
    );

    // Zeige die Benachrichtigung an
    await _showNotification(notification);
  } catch (e) {
    print("Fehler im Hintergrundnachricht-Handler: $e");
  }
}

Future<void> _showNotification(TeGNotification notification) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'default_channel',
    'Default',
    channelDescription: 'Channel for notifications',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  String payload = "${notification.type}|${notification.id.toString()}"; // Typ zuerst, dann ID

  // Zeige die Benachrichtigung an, indem die Notification-Daten verwendet werden
  await flutterLocalNotificationsPlugin.show(
    0, // Eindeutige ID verwenden
    notification.title,
    notification.body,
    platformChannelSpecifics,
    payload: payload,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthorizationProvider(),
      builder: (context, _) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
            value: TeamProvider(
                Provider.of<AuthorizationProvider>(context).writeToken),
          ),
          ChangeNotifierProvider.value(
            value: PhotoProvider(
                Provider.of<AuthorizationProvider>(context).writeToken),
          ),
          ChangeNotifierProvider.value(
            value: NewsProvider(
                Provider.of<AuthorizationProvider>(context).writeToken),
          ),
          ChangeNotifierProvider.value(
            value: TermineProvider(
                Provider.of<AuthorizationProvider>(context).writeToken),
          ),
          ChangeNotifierProvider.value(
            value: LigaSpieleProvider(
                Provider.of<AuthorizationProvider>(context).writeToken),
          ),
          ChangeNotifierProvider.value(
            value: UserProvider(
                Provider.of<AuthorizationProvider>(context).writeToken),
          ),
          ChangeNotifierProvider.value(
            value: SaisonProvider(
                Provider.of<AuthorizationProvider>(context).writeToken),
          ),
          ChangeNotifierProvider.value(
            value: GetraenkeBuchenProvider(
                Provider.of<AuthorizationProvider>(context).writeToken),
          ),
        ],
        child: Consumer<AuthorizationProvider>(
          builder: (ctx, authProvider, _) => MaterialApp(
            title: "TSV Weidenbach",
            theme: ThemeData(
              scaffoldBackgroundColor: const Color.fromRGBO(221, 221, 226, 1),
              appBarTheme: const AppBarTheme(
                  backgroundColor: Color.fromRGBO(43, 43, 43, 1),
                  foregroundColor: Colors.white),
            ),
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            navigatorKey: navigatorKey, // <--- Hier den Key setzen
            supportedLocales: [
              Locale('de', 'DE'), // Deutsch
            ],
            home: const MyHomePage(),
            routes: {
              TeamScreen.routename: (ctx) => const TeamScreen(),
              TeamDetailScreen.routename: (ctx) => const TeamDetailScreen(),
              DocumentsScreen.routename: (ctx) => const DocumentsScreen(),
              TrainersScreen.routename: (ctx) => const TrainersScreen(),
              AuthScreen.routeName: (ctx) => const AuthScreen(pop: true),
              PhotoGalleryScreen.routename: (ctx) => const PhotoGalleryScreen(),
              PlaceBookingScreen.routename: (ctx) => const PlaceBookingScreen(),
              AddNewsScreen.routename: (ctx) => const AddNewsScreen(),
              AdminScreen.routename: (ctx) => const AdminScreen(),
              AddPhotoScreen.routename: (ctx) => const AddPhotoScreen(),
              NewsDetailScreen.routename: (ctx) => const NewsDetailScreen(),
              ImpressumScreen.routename: (ctx) => const ImpressumScreen(),
              AddUserScreen.routename: (ctx) => const AddUserScreen(),
              UserProfileScreen.routename: (ctx) => const UserProfileScreen(),
              DatenschutzScreen.routename: (ctx) => const DatenschutzScreen(),
              GetraenkeBuchenScreen.routename: (ctx) =>
                  Provider.of<AuthorizationProvider>(context).isSignedIn
                      ? const GetraenkeBuchenScreen()
                      : const AuthScreen(pop: false),
              GetraenkeBuchungenDetailsScreen.routename: (ctx) =>
                  const GetraenkeBuchungenDetailsScreen(),
              GetraenkeSummenScreen.routename: (ctx) =>
                  const GetraenkeSummenScreen(),
              AddMannschaftScreen.routename: (ctx) =>
                  const AddMannschaftScreen(),
              CalendarScreen.routename: (ctx) => const CalendarScreen(),
              AddTermineScreen.routename: (ctx) => const AddTermineScreen(),
              AddLigaSpieleScreen.routename: (ctx) =>
                  const AddLigaSpieleScreen(),
              AddTeamResultScreen.routename: (ctx) =>
                  const AddTeamResultScreen(),
            },
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _firstLoading = true;

  @override
  void initState() {
    super.initState();
    checkForNotificationLaunch();
  }

  Future<void> firstLoadNews() async {
    if (mounted) {
      setState(() {
        Provider.of<NewsProvider>(context, listen: false).isNewsLoading = true;
      });
    }
    await Provider.of<NewsProvider>(context).getData();
    if (mounted) {
      setState(() {
        Provider.of<NewsProvider>(context, listen: false).isNewsLoading = false;
      });
    }
  }

  Future<void> getCredentialsAndLogin() async {
    String? email;
    String? password;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    if (mounted) {
      email = await Provider.of<AuthorizationProvider>(context)
          .storage
          .read(key: "email");
    }
    if (mounted) {
      password =
          await Provider.of<AuthorizationProvider>(context, listen: false)
              .storage
              .read(key: "password");
    }
    if (mounted) {
      Provider.of<AuthorizationProvider>(context, listen: false).credentials = {
        "email": email,
        "password": password
      };
    }
    if (mounted) {
      if (Provider.of<AuthorizationProvider>(context, listen: false)
                  .credentials["email"] !=
              null &&
          Provider.of<AuthorizationProvider>(context, listen: false)
                  .credentials["password"] !=
              null) {
        Provider.of<AuthorizationProvider>(context, listen: false).signIn(
            context,
            Provider.of<AuthorizationProvider>(context, listen: false)
                .credentials["email"] as String,
            Provider.of<AuthorizationProvider>(context, listen: false)
                .credentials["password"] as String);
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<int, Widget> sites = {
    0: const NewsScreen(),
    1: const FunctionsScreen(),
    2: const MoreScreen(),
  };

  @override
  void didChangeDependencies() {
    if (_firstLoading) {
      getCredentialsAndLogin();
      _firstLoading = false;
    }
    if (Provider.of<NewsProvider>(context).loadedNews.isEmpty) {
      firstLoadNews();
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VereinAppbar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : sites[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        currentIndex: _selectedIndex,
        selectedIconTheme: const IconThemeData(size: 28, color: Colors.white),
        unselectedIconTheme:
            const IconThemeData(size: 25, color: Colors.white60),
        selectedFontSize: 13,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Neuigkeiten"),
          BottomNavigationBarItem(
              icon: Icon(Icons.apps_sharp), label: "Funktionen"),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: "Mehr"),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
