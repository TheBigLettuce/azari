import 'dart:async';
import 'dart:convert';

//import 'dart:io';
//import 'dart:math';
import 'package:gallery/src/models/grid_list.dart';
import 'package:gallery/src/models/images.dart';
import 'package:provider/provider.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
//import 'package:async/async.dart' as async;
import 'package:flutter/services.dart';

import 'src/cell/cell.dart';
import 'src/cell/image_widget.dart';
import 'src/cell/directory.dart';
import 'src/cell/image.dart';
import 'src/models/directory_list.dart';
//import 'package:permission_handler/permission_handler.dart';
//import 'package:web_socket_channel/io.dart';
//import 'package:web_socket_channel/web_socket_channel.dart';

//import 'package:transparent_image/transparent_image.dart';
//import 'package:convert/convert.dart' as convert;

//import 'dart:async';
//import 'package:transparent_image/transparent_image.dart';

const imageType = 1;
const videoType = 2;
const movingImageType = 3;

void main() async {
  runApp(const MyApp());
}

//const platform = MethodChannel('lol.bruh19.azari.gallery/mediastore');

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        var img = DirectoryModel();
        img.refresh();

        return img;
      },
      child: MaterialApp(
        title: 'Welcome to Flutter',
        theme: ThemeData(
          useMaterial3: true,
          /*appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),*/
        ),
        home: const Home(),
      ),
    );
  }
}

class AddImage extends StatelessWidget {
  const AddImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Add Image")),
        body: Row(
          children: [
            Consumer<DirectoryModel>(
              builder: ((context, list, child) {
                return ElevatedButton(
                  child: const Text("Pick"),
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform
                        .pickFiles(type: FileType.image, withReadStream: true);

                    if (result == null) {
                      showDialog(
                          context: context,
                          builder: ((context) {
                            return AlertDialog(
                              title: const Text("No image provided"),
                              content:
                                  const Text("Select an image from gallery"),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text("OK"))
                              ],
                            );
                          }));
                    } else {
                      const ch = MethodChannel("org.gallery");

                      try {
                        var res = ch.invokeMethod("addFiles", <String, dynamic>{
                          "type": 1,
                          "files": result.files.map((e) => e.path!).toList(),
                        });

                        res.then((value) => print("succes")).onError(
                            (error, stackTrace) => print("failed: $error"));
                      } catch (e) {
                        print("failed: $e");
                      }
                    }
                  },
                );
              }),
            ),
          ],
        ));
  }
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gallery"),
        actions: [
          Consumer<DirectoryModel>(
            builder: (context, list, child) {
              return IconButton(
                tooltip: "Refresh grid",
                onPressed: (() {
                  list.refresh();
                }),
                icon: const Icon(Icons.refresh),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(child: Text("Gallery")),
            ListTile(
                title: const Text("Add Image"),
                leading: const Icon(Icons.image),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddImage()));
                }),
            ListTile(
              title: const Text("Settings"),
              leading: const Icon(Icons.settings),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const Settings()));
              },
            )
          ],
        ),
      ),
      body: ImageGrid(
        data: Provider.of<DirectoryModel>(context).copy(),
        onPressed: (context, cell) {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return Images(dir: (cell as DirectoryCell).path);
          }));
        },
      ),
    );
  }
}

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: const Text("not implemented"),
    );
  }
}

class Images extends StatefulWidget {
  final String dir;
  const Images({super.key, required this.dir});

  @override
  State<Images> createState() => _ImagesState();
}

class _ImagesState extends State<Images> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        var model = ImagesModel(dir: widget.dir);
        model.refresh();

        return model;
      },
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(widget.dir)),
          body: Consumer<ImagesModel>(builder: (context, data, _) {
            return data.isListEmpty()
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ImageGrid(
                    data: data.copy(),
                    onPressed: (context, cell) {
                      print("pressed image ${(cell as ImageCell).alias}");
                    });
          }),
        );
      },
    );
  }
}

class ImageGrid<T extends Cell> extends StatefulWidget {
  final List<T> data;
  final Null Function(BuildContext context, T cell) onPressed;
  const ImageGrid({Key? key, required this.data, required this.onPressed})
      : super(key: key);

  @override
  State<ImageGrid> createState() => _ImageGridState<T>();
}

class _ImageGridState<T extends Cell> extends State<ImageGrid<T>> {
  static const maxExtend = 150.0;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxExtend,
      ),
      itemCount: widget.data.length,
      itemBuilder: (context, indx) {
        var m = widget.data[indx];
        return CellImageWidget<T>(
          cell: m,
          onPressed: widget.onPressed,
          //extend: maxExtend,
        );
      },
    );
  }
}
