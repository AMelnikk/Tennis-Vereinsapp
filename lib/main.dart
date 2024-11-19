import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/providers/auth_provider.dart';
import 'package:verein_app/providers/photo_provider.dart';
import 'package:verein_app/screens/auth_screen.dart';
import 'package:verein_app/screens/fotogalerie_screen.dart';
import 'package:verein_app/screens/trainers_screen.dart';
import "./providers/game_results_provider.dart";
import './screens/documents_screen.dart';
import './screens/functions_screen.dart';
import './screens/game_results_screen.dart';
import './screens/more_screen.dart';
import './widgets/verein_appbar.dart';
import "./screens/news_screen.dart";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: GameResultsProvider(),
        ),
        ChangeNotifierProvider.value(
          value: AuthProvider(),
        ),
        ChangeNotifierProvider.value(
          value: PhotoProvider(),
        )
      ],
      child: MaterialApp(
        title: "TSV Weidenbach",
        theme: ThemeData(
          scaffoldBackgroundColor: const Color.fromRGBO(221, 221, 226, 1),
          appBarTheme: const AppBarTheme(
              backgroundColor: Color.fromRGBO(43, 43, 43, 1),
              foregroundColor: Colors.white),
        ),
        home: const MyHomePage(),
        routes: {
          GameResultsScreen.routename: (ctx) => const GameResultsScreen(),
          DocumentsScreen.routename: (ctx) => const DocumentsScreen(),
          TrainersScreen.routename: (ctx) => const TrainersScreen(),
          AuthScreen.routeName: (ctx) => const AuthScreen(),
          FotogalerieScreen.routename: (ctx) => const FotogalerieScreen(),
        },
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

  Map<int, Widget> sites = {
    0: const NewsScreen(),
    1: const FunctionsScreen(),
    2: const MoreScreen(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VereinAppbar(),
      body: sites[_selectedIndex],
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
