import 'dart:typed_data';
import 'package:flutter/material.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:flutter_image_converter/flutter_image_converter.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import '../providers/photo_provider.dart';
import '../widgets/verein_appbar.dart';

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({super.key});
  static const routename = "/fotogalerie";

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  var _isLoading = true;

  Uint8List? photo;

  // Future<void> testConvert() async {
  //   setState(() {
  //     _isLoading = true;
  //   });

  //   final list =
  //       await Image.asset("assets/images/Oliver_Ströbel_Trainer.jpg").uint8List;
  //   final result = await FlutterImageCompress.compressWithList(
  //     list,
  //     minHeight: 1080,
  //     minWidth: 1080,
  //     quality: 40,
  //     format: CompressFormat.webp,
  //   );
  //   print(list.length);
  //   print(result.length);
  //   photo = result;
  //   setState(() {
  //     _isLoading = false;
  //   });
  // }

  Future<void> getData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await Provider.of<PhotoProvider>(context, listen: false).getData();
      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      print(error);
    }
  }

  @override
  void didChangeDependencies() {
    if (_isLoading) {
      if (Provider.of<PhotoProvider>(context).loadedData.isEmpty) {
        getData();
      } else {
        _isLoading = false;
      }
    }
    super.didChangeDependencies();
  }

  // @override
  // void initState() {
  //   testConvert();
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    final photoProvider = Provider.of<PhotoProvider>(context);
    return Scaffold(
      appBar: VereinAppbar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : photoProvider.loadedData.isEmpty
              ? RefreshIndicator(
                  onRefresh: getData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).viewInsets.bottom -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom -
                          AppBar().preferredSize.height,
                      child: const Center(
                        child: Text(
                          "Es gibt noch nichts hier",
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                )
              : PhotoViewGallery.builder(
                  gaplessPlayback: true,
                  backgroundDecoration: const BoxDecoration(
                    color: Color.fromRGBO(221, 221, 226, 1),
                  ),
                  scrollPhysics: const BouncingScrollPhysics(),
                  itemCount: photoProvider.loadedData.length,
                  builder: (context, index) {
                    return PhotoViewGalleryPageOptions(
                      imageProvider: MemoryImage(photoProvider
                          .loadedData[
                              photoProvider.loadedData.length - 1 - index]
                          .imageData),
                    );
                  },
                ),
      // body: _isLoading
      //     ? const Center(
      //         child: CircularProgressIndicator(),
      //       )
      //     : Image.memory(photo as Uint8List),
    );
  }
}
