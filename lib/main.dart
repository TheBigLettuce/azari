import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
//import 'dart:io';
//import 'dart:math';
import 'package:provider/provider.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
//import 'package:async/async.dart' as async;
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
//import 'package:permission_handler/permission_handler.dart';
//import 'package:web_socket_channel/io.dart';
//import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:mime/mime.dart' as mime;
import 'package:http_parser/http_parser.dart';
//import 'package:transparent_image/transparent_image.dart';
import 'package:convert/convert.dart' as convert;

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

class ImagesModel extends GridListModel<ImageCell> {
  String dir;

  @override
  Future<List<ImageCell>> fetchRes() async {
    http.Response resp;
    try {
      resp = await http.get(Uri.http("localhost:8080", "/dirs", {"dir": dir}));
    } catch (e) {
      return Future.error(e);
    }

    return Future((() {
      var r = resp;
      if (r.statusCode != 200) {
        return Future.error("status code is not ok");
      }

      List<ImageCell> list = [];
      List<dynamic> j = json.decode(r.body);
      for (var element in j) {
        list.add(ImageCell.fromJson(element, onPressed));
      }

      return list; //Future.error("invalid type for directories");
    }));
  }

  @override
  void onPressed(String dir, BuildContext context) {}

  @override
  void refresh() {
    super._refreshF(fetchRes());
  }

  ImagesModel({required this.dir});
}

class DirectoryModel extends GridListModel<DirectoryCell> {
  @override
  Future<List<DirectoryCell>> fetchRes() async {
    http.Response resp;
    try {
      resp = await http.get(Uri.parse("http://localhost:8080/dirs"));
    } catch (e) {
      return Future.error(e);
    }

    return Future((() {
      var r = resp;
      if (r.statusCode != 200) {
        return Future.error("status code is not ok");
      }

      List<DirectoryCell> list = [];
      List<dynamic> j = json.decode(r.body);
      for (var element in j) {
        list.add(DirectoryCell.fromJson(element, onPressed));
      }

      return list; //Future.error("invalid type for directories");
    }));
  }

  @override
  void onPressed(String dir, BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Images(
                  dir: dir,
                )));
    print("pressed: $dir");
  }

  @override
  void refresh() {
    super._refreshF(fetchRes());
  }

  DirectoryModel();
}

class GridListModel<T extends Cell> extends ChangeNotifier {
  final List<T> _list = [];

  //UnmodifiableListView<T> get directories => UnmodifiableListView(_list);

  void replace(List<T> newList) {
    _list.clear();
    _list.addAll(newList);

    notifyListeners();
  }

  void _refreshF(Future<List<T>> f) {
    f.then((value) {
      replace(value);
    }).onError((error, stackTrace) {
      print(error);
    });
  }

  void refresh() {
    throw ("unimplemented");
  }

  void onPressed(String dir, BuildContext context) {
    throw ("unimplemented");
  }

  Future<List<T>> fetchRes() async {
    throw ("unimplemented");
  }

  //GridListModel({required this.list});
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
      body: const ImageGrid(),
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

class Images extends StatelessWidget {
  final String dir;
  const Images({super.key, required this.dir});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(dir)),
      body: const Text("not implemented(uet)"),
    );
  }
}

class ImageGrid extends StatefulWidget {
  //final T cell;
  const ImageGrid({Key? key}) : super(key: key);

  @override
  State<ImageGrid> createState() => _ImageGridState();
}

class CellData {
  final Uint8List thumb;
  final String name;
  void Function(BuildContext context) onPressed;

  CellData({required this.thumb, required this.name, required this.onPressed});
}

class _ImageGridState extends State<ImageGrid> {
  static const maxExtend = 150.0;

  @override
  Widget build(BuildContext context) {
    return Consumer<DirectoryModel>(
      builder: (context, list, child) {
        if (list._list.isEmpty) {
          return const Text("empty list");
        }

        var data = list._list;

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxExtend,
          ),
          itemCount: data.length,
          itemBuilder: (context, indx) {
            var m = data[indx];
            return CellImage<DirectoryCell>(
              a: m,
              //extend: maxExtend,
            );
          },
        );
      },
    );
  }
}

class DirectoryCell extends Cell {
  DirectoryCell.fromJson(Map<String, dynamic> m,
      void Function(String dir, BuildContext context) onPressed)
      : super(
            onPressed: (context) {
              onPressed(m["path"], context);
            },
            alias: path.basename(m["path"]),
            hash: base64Decode(m["thumbhash"]),
            path: m["path"]);

  Map<String, dynamic> toJson() => {
        "path": super.path,
        "alias": alias,
        "thumbhash": base64Encode(super.hash)
      };

  DirectoryCell(
      {required super.hash,
      required super.path,
      required super.alias,
      required super.onPressed});
}

class ImageCell extends Cell {
  Uint8List orighash;
  int type;

  ImageCell.fromJson(Map<String, dynamic> m,
      void Function(String dir, BuildContext context) onPressed)
      : orighash = base64Decode(m["orighash"]),
        type = int.parse(m["type"]),
        super(
            onPressed: (context) {
              onPressed(m["dir"], context);
            },
            alias: m["name"],
            hash: base64Decode(m["thumbhash"]),
            path: m["dir"]);

  Map<String, dynamic> toJson() => {
        "dir": super.path,
        "alias": super.alias,
        "thumbhash": base64Encode(super.hash),
        "orighash": base64Encode(orighash),
        "type": type.toString(),
      };

  ImageCell(
      {required super.alias,
      required super.hash,
      required super.path,
      required this.orighash,
      required this.type,
      required super.onPressed});
}

class Cell {
  String path;
  String alias;
  Uint8List hash;
  void Function(BuildContext context) onPressed;

  Future<CellData> getFile() async {
    http.Response resp;
    try {
      resp = await http.get(Uri.parse(
          "http://localhost:8080/static/${convert.hex.encode(hash)}"));
    } catch (e) {
      return Future.error(e);
    }

    return Future((() {
      if (resp.statusCode != 200) {
        return Future.error("status code is not ok");
      }

      return CellData(thumb: resp.bodyBytes, name: alias, onPressed: onPressed);
    }));
  }

  Cell(
      {required this.path,
      required this.hash,
      required this.alias,
      required this.onPressed});
}

class CellImage<T extends Cell> extends StatefulWidget {
  final T _directory;
  //final double _ext;

  const CellImage({Key? key, required T a})
      : _directory = a,
        //_ext = extend,
        super(key: key);

  @override
  State<CellImage> createState() => _CellImageState();
}

class _CellImageState extends State<CellImage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: widget._directory.getFile(),
        builder: ((context, snapshot) {
          if (snapshot.hasData) {
            var data = snapshot.data as CellData;

            return InkWell(
              splashColor: Colors.indigo,
              //focusColor: Colors.purple,
              hoverColor: Colors.indigoAccent,
              borderRadius: BorderRadius.circular(15.0),
              onTap: () {
                data.onPressed(context);
              },
              child: Card(
                  elevation: 0,
                  child: ClipPath(
                    clipper: ShapeBorderClipper(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0))),
                    child: Stack(
                      children: [
                        Image.memory(data.thumb),
                        Container(
                          alignment: Alignment.bottomCenter,
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                Colors.black.withAlpha(50),
                                Colors.black12,
                                Colors.black45
                              ])),
                          child: Text(
                            data.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )),
            );
          } else if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          } else {
            return const CircularProgressIndicator();
          }
        }));
  }
}
