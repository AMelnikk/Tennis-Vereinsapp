import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
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
import './screens/news_overview_screen.dart';
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
import "./screens/news_screen.dart";
import "./screens/add_team_screen.dart";
import "./screens/team_detail_screen.dart";
import "./screens/calendar_screen.dart";
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //const FirebaseOptions firebaseOptions = FirebaseOptions(
  //    apiKey: "AIzaSyCV6bEMtuX4q-s4YpHStlU3kNCMj11T4Dk",
  //    authDomain: "db-teg.firebaseapp.com",
  //    databaseURL: "https://db-teg-default-rtdb.firebaseio.com",
  //    projectId: "db-teg",
  //    storageBucket: "db-teg.firebasestorage.app",
  //    messagingSenderId: "1050815457795",
  //    appId: "1:1050815457795:web:2d0bc6f9b80793f6e37c36",
  //    measurementId: "G-LNJY8VGKTG");
  //try {
  //  await Firebase.initializeApp();
  //} catch (e) {
  //  print("Firebase initialization failed: $e");
  //}
  await initializeDateFormatting('de_DE', null); // Lokalisierung vorbereiten
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then(
    (_) {
      runApp(const MyApp());
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      builder: (context, _) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
            value: TeamProvider(Provider.of<AuthProvider>(context).writeToken),
          ),
          ChangeNotifierProvider.value(
            value: PhotoProvider(Provider.of<AuthProvider>(context).writeToken),
          ),
          ChangeNotifierProvider.value(
            value: NewsProvider(Provider.of<AuthProvider>(context).writeToken),
          ),
          ChangeNotifierProvider.value(
            value:
                TermineProvider(Provider.of<AuthProvider>(context).writeToken),
          ),
          ChangeNotifierProvider.value(
            value: LigaSpieleProvider(
                Provider.of<AuthProvider>(context).writeToken),
          ),
          ChangeNotifierProvider.value(
            value: UserProvider(Provider.of<AuthProvider>(context).writeToken),
          ),
          ChangeNotifierProvider.value(
            value:
                SaisonProvider(Provider.of<AuthProvider>(context).writeToken),
          ),
          ChangeNotifierProvider.value(
            value: GetraenkeBuchenProvider(
                Provider.of<AuthProvider>(context).writeToken),
          ),
        ],
        child: Consumer<AuthProvider>(
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
              NewsOverviewScreen.routename: (ctx) => const NewsOverviewScreen(),
              ImpressumScreen.routename: (ctx) => const ImpressumScreen(),
              AddUserScreen.routename: (ctx) => const AddUserScreen(),
              DatenschutzScreen.routename: (ctx) => const DatenschutzScreen(),
              GetraenkeBuchenScreen.routename: (ctx) =>
                  Provider.of<AuthProvider>(context).isSignedIn
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
      email =
          await Provider.of<AuthProvider>(context).storage.read(key: "email");
    }
    if (mounted) {
      password = await Provider.of<AuthProvider>(context, listen: false)
          .storage
          .read(key: "password");
    }
    if (mounted) {
      Provider.of<AuthProvider>(context, listen: false).credentials = {
        "email": email,
        "password": password
      };
    }
    if (mounted) {
      if (Provider.of<AuthProvider>(context, listen: false)
                  .credentials["email"] !=
              null &&
          Provider.of<AuthProvider>(context, listen: false)
                  .credentials["password"] !=
              null) {
        Provider.of<AuthProvider>(context, listen: false).signIn(
            context,
            Provider.of<AuthProvider>(context, listen: false)
                .credentials["email"] as String,
            Provider.of<AuthProvider>(context, listen: false)
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
