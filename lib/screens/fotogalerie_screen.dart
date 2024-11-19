import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/models/Photo.dart';
import 'package:verein_app/providers/photo_provider.dart';
import 'package:verein_app/widgets/photo_widget.dart';
import 'package:verein_app/widgets/verein_appbar.dart';

class FotogalerieScreen extends StatefulWidget {
  const FotogalerieScreen({super.key});
  static const routename = "/fotogalerie";

  @override
  State<FotogalerieScreen> createState() => _FotogalerieScreenState();
}

class _FotogalerieScreenState extends State<FotogalerieScreen> {
  var _isLoading = true;
  late final List<Photo> loadedData;

  Future<void> getData() async {
    loadedData =
        await Provider.of<PhotoProvider>(context, listen: false).getData();
    setState(() {
      _isLoading = false;
    });
  }

  // Future<Uint8List> getBytesFromPhoto() async {
  //   return (await rootBundle.load("assets/images/Vereinslogo.png"))
  //       .buffer
  //       .asUint8List();
  // }

  // Future<void> postDbimage(//Uint8List imageData,
  // String title) async {
  //   final Uint8List imageData = await getBytesFromPhoto();

  //   var responce = await http.post(
  //     Uri.parse("https://db-teg-default-rtdb.firebaseio.com/Fotogalerie.json/"),
  //     body: json.encode(
  //       {"title": title, "imageData": imageData},
  //     ),
  //   );
  //   print(responce.statusCode);
  // }

  @override
  initState() {
    //postDbimage("logo");
    getData();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VereinAppbar(),
      body: _isLoading
          ? const CircularProgressIndicator()
          : CustomScrollView(
              slivers: [
                SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10),
                    delegate: SliverChildListDelegate(loadedData
                        .map((item) => PhotoWidget(
                            title: item.title, photoData: item.imageData))
                        .toList()))
              ],
            ),
    );
  }
}
