import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/models/user.dart';
import './screens/user_profile_screen.dart';
import './utils/push_notification_service.dart';
import './providers/season_provider.dart';
import './providers/termine_provider.dart';
import './screens/add_termine_screen.dart';
import './screens/getraenke_summen_screen.dart';
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
import './screens/add_photo_screen.dart';
import './screens/add_news_screen.dart';
import './screens/admin_screen.dart';
import './screens/add_team_game_screen.dart';
import './screens/add_team_result.dart';
import './screens/place_booking_screen.dart';
import './providers/auth_provider.dart';
import './providers/photo_provider.dart';
import './screens/auth_screen.dart';
import './screens/photo_gallery_screen.dart';
import './screens/trainers_screen.dart';
import "./providers/team_provider.dart";
import './screens/documents_screen.dart';
import './screens/functions_screen.dart';
import './screens/team_screen.dart';
import './screens/more_screen.dart';
import './screens/news_admin_screen.dart';
import './widgets/verein_appbar.dart';
import "./screens/news_screen.dart";
import "./screens/add_team_screen.dart";
import "./screens/team_detail_screen.dart";
import "./screens/calendar_screen.dart";
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart'; // Firebase-Optionen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialisieren
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Background Handler registrieren (muss top-level sein)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Locale vorbereiten
  await initializeDateFormatting('de_DE', null);

  // Portrait erzwingen
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // App starten
  runApp(const MyApp());

  // Push-Service nach App-Start initialisieren (nicht blockierend)
  try {
    await PushNotificationService().initialize();
  } catch (e, stack) {
    debugPrint("❌ Fehler in PushNotificationService: $e");
    debugPrint(stack.toString());
  }
}

// Top-level Background-Handler

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase muss hier initialisiert werden
  await Firebase.initializeApp();
  debugPrint("📩 Hintergrund-Nachricht empfangen: ${message.messageId}");
  debugPrint("Daten: ${message.data}");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthorizationProvider(),
      builder: (context, child) {
        // Holen Sie sich die Instanz A, die soeben erstellt wurde.
        final authProviderInstanceA = context.read<AuthorizationProvider>();

        return MultiProvider(
          providers: [
            // Auth Provider als Basis
            ChangeNotifierProvider.value(
              value: authProviderInstanceA, // <--- Nur DIESE Instanz verwenden
            ),

            // Ab hier alle Provider, die das Token benötigen → ProxyProvider
            ChangeNotifierProxyProvider<AuthorizationProvider, TeamProvider>(
              create: (_) => TeamProvider(null),
              update: (_, auth, prev) => TeamProvider(auth.writeToken),
            ),

            ChangeNotifierProxyProvider<AuthorizationProvider, PhotoProvider>(
              create: (_) => PhotoProvider(null),
              update: (_, auth, prev) => PhotoProvider(auth.writeToken),
            ),

            ChangeNotifierProxyProvider<AuthorizationProvider, NewsProvider>(
              create: (_) => NewsProvider(null),
              update: (_, auth, prev) => NewsProvider(auth.writeToken),
            ),

            ChangeNotifierProxyProvider<AuthorizationProvider, TermineProvider>(
              create: (_) => TermineProvider(null),
              update: (_, auth, prev) => TermineProvider(auth.writeToken),
            ),

            ChangeNotifierProxyProvider<AuthorizationProvider,
                LigaSpieleProvider>(
              create: (_) => LigaSpieleProvider(null),
              update: (_, auth, prev) => LigaSpieleProvider(auth.writeToken),
            ),

            ChangeNotifierProxyProvider<AuthorizationProvider, UserProvider>(
              create: (_) => UserProvider(null),
              update: (_, auth, prev) => UserProvider(auth.writeToken),
            ),

            ChangeNotifierProxyProvider<AuthorizationProvider, SaisonProvider>(
              create: (_) => SaisonProvider(null),
              update: (_, auth, prev) => SaisonProvider(auth.writeToken),
            ),

            ChangeNotifierProxyProvider<AuthorizationProvider,
                GetraenkeBuchenProvider>(
              create: (_) => GetraenkeBuchenProvider(null),
              update: (_, auth, prev) =>
                  GetraenkeBuchenProvider(auth.writeToken),
            ),
          ],
          child: Consumer<AuthorizationProvider>(
            builder: (ctx, authProvider, _) => MaterialApp(
              navigatorKey: PushNotificationService
                  .navigatorKey, // <--- über Klasse, nicht Instanz
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
                PhotoGalleryScreen.routename: (ctx) =>
                    const PhotoGalleryScreen(),
                PlaceBookingScreen.routename: (ctx) =>
                    const PlaceBookingScreen(),
                AddNewsScreen.routename: (ctx) => const AddNewsScreen(),
                AdminScreen.routename: (ctx) => const AdminScreen(),
                AddPhotoScreen.routename: (ctx) => const AddPhotoScreen(),
                NewsDetailScreen.routename: (ctx) => const NewsDetailScreen(),
                ImpressumScreen.routename: (ctx) => const ImpressumScreen(),
                AddUserScreen.routename: (ctx) => const AddUserScreen(),
                UserProfileScreen.routename: (ctx) => const UserProfileScreen(),
                DatenschutzScreen.routename: (ctx) => const DatenschutzScreen(),
                NewsAdminScreen.routename: (ctx) => const NewsAdminScreen(),
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
        );
      },
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
      email = await Provider.of<AuthorizationProvider>(context, listen: false)
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
        // SingIn
        String localId =
            await Provider.of<AuthorizationProvider>(context, listen: false)
                .signIn(
                    context,
                    Provider.of<AuthorizationProvider>(context, listen: false)
                        .credentials["email"] as String,
                    Provider.of<AuthorizationProvider>(context, listen: false)
                        .credentials["password"] as String);
        //GetUserData
        if (mounted) {
          User? user = await Provider.of<UserProvider>(context, listen: false)
              .getUserData(localId);
          // !!! when running getUserData() inside of UserProvider the user variable appears
          // to lose data when ending the function, so no the function returns a User and then
          // it is assigning the returned value to the user variable in UserProvider the hard way
          if (user != null) {
            if (mounted) {
              Provider.of<UserProvider>(context, listen: false).user = user;
            }
          }
        }
        // This was used for debugging
        // if (kDebugMode) {
        //   print(
        //       """Data in UserProvider from main() at the end of getCredentialsAndLogin()
        //   Vorname: ${Provider.of<UserProvider>(context, listen: false).user.vorname},
        //   Email: ${Provider.of<UserProvider>(context, listen: false).user.email},
        //   Uid: ${Provider.of<UserProvider>(context, listen: false).user.uid},
        //   PlatzbuchungLink: ${Provider.of<UserProvider>(context, listen: false).user.platzbuchungLink}""");
        // }
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> loginAndGetUserData() async {}

  Map<int, Widget> sites = {
    0: const NewsScreen(),
    1: const FunctionsScreen(),
    2: const MoreScreen(),
  };

  @override
  void didChangeDependencies() {
    if (_firstLoading) {
      getCredentialsAndLogin();
    }
    _firstLoading = false;
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
