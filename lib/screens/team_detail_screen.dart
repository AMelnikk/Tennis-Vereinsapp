import 'package:flutter/material.dart';

class TeamDetailScreen extends StatefulWidget {
  const TeamDetailScreen({super.key});
  static const routename = "/team-detail";

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("TSV Rohr"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Logo und Header
            Container(
              color: Colors.black,
              padding: EdgeInsets.all(10),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 40,
                child: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/7/7a/Football_icon.png', // Ersetze mit deinem Logo
                  width: 60,
                ),
              ),
            ),

            // Mannschaftsbild
            Image.network(
              'https://via.placeholder.com/400', // Ersetze mit dem echten Bild-URL
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            // Mannschaftsinfo
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text("Herren",
                        style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                  SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text("Mannschaftsführer"),
                    subtitle: Text("Leuthold Yanni"),
                  ),
                  ListTile(
                    leading: Icon(Icons.phone),
                    title: Text("0151 28948327"),
                  ),
                  ListTile(
                    leading: Icon(Icons.sports_tennis),
                    title: Text("Liga"),
                    subtitle: Text("Herren Landesliga 1 Gr. 062 NO"),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text("weitere Informationen (nuliga)",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),

            // Navigation (Spiele, Tabelle, Spieler)
            Container(
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                      onPressed: () {},
                      child: Text("Spiele",
                          style: TextStyle(color: Colors.white))),
                  TextButton(
                      onPressed: () {},
                      child: Text("Tabelle",
                          style: TextStyle(color: Colors.white))),
                  TextButton(
                      onPressed: () {},
                      child: Text("Spieler/-innen",
                          style: TextStyle(color: Colors.white))),
                ],
              ),
            ),

            // Letztes Spielergebnis
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text("TSV Rohr  2:4  TC Postkeller W...",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text("Letztes Spielergebnis"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
