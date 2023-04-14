import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
//import 'dart:io';
//import 'dart:math';
import 'package:gallery/src/models/grid_list.dart';
import 'package:gallery/src/models/images.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
//import 'package:async/async.dart' as async;
import 'package:flutter/services.dart';

import 'src/cell/cell.dart';
import 'src/cell/image_widget.dart';
import 'src/cell/directory.dart';
import 'src/cell/image.dart';
import 'src/models/directory.dart';
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
  await Hive.initFlutter();
  await Hive.openBox("settings");

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
        // img.refresh();

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
        home: const Directories(),
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
                        .pickFiles(
                            type: FileType.image,
                            withReadStream: false,
                            initialDirectory:
                                Hive.box("settings").get("directory"));

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
                          "deviceId": Hive.box("settings").get("deviceId"),
                          "baseDirectory":
                              Hive.box("settings").get("directory"),
                          "serverAddress":
                              Hive.box("settings").get("serverAddress"),
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

class Directories extends StatefulWidget {
  const Directories({super.key});

  @override
  State<Directories> createState() => _DirectoriesState();
}

class _DirectoriesState extends State<Directories> {
  @override
  Widget build(BuildContext context) {
    return () {
          List<PageViewModel> list = [];

          var provider = Provider.of<DirectoryModel>(context);

          if (!provider.isServerAddressSet()) {
            list.add(PageViewModel(
                title: "Set server address",
                footer: provider.serverAddrSetError != null
                    ? Text(provider.serverAddrSetError!)
                    : null,
                bodyWidget: TextField(
                  keyboardType: TextInputType.url,
                  onSubmitted: provider.setServerAddress,
                )));
          }

          if (!provider.isDeviceIdSet() && provider.isServerAddressSet()) {
            list.add(PageViewModel(
                title: "Set DeviceID",
                footer: provider.deviceIdSetError != null
                    ? Text(provider.deviceIdSetError!)
                    : null,
                bodyWidget: TextField(
                  onSubmitted: provider.setDeviceId,
                )));
          }

          if (!provider.isDirectorySet() && provider.isServerAddressSet()) {
            list.add(
              PageViewModel(
                title: "Choose default directory",
                footer: provider.directorySetError != null
                    ? Text(provider.directorySetError!)
                    : null,
                bodyWidget: TextButton(
                  child: const Text("pick"),
                  onPressed: () async {
                    var pickedDir =
                        await FilePicker.platform.getDirectoryPath();
                    if (pickedDir == null ||
                        pickedDir == "" ||
                        FileStat.statSync(pickedDir).type ==
                            FileSystemEntityType.notFound) {
                      provider.directorySetError = "Path is invalid";
                      return;
                    }

                    provider.setDirectory(pickedDir);
                  },
                ),
              ),
            );
          }

          return list.isEmpty
              ? null
              : IntroductionScreen(
                  pages: list,
                  //done: Text("ok"),
                  showDoneButton: false,
                  next: const Text("next"),
                );
        }() ??
        Scaffold(
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
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Settings()));
                  },
                )
              ],
            ),
          ),
          body: ImageGrid(
            data: Provider.of<DirectoryModel>(context).copy(),
            onPressed: (context, cell) {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return Images(cell: (cell as DirectoryCell));
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
      body: ListView(children: [
        ListTile(
          title: const Text("Device ID"),
          subtitle: Text(Hive.box("settings").get("deviceId")),
        ),
        ListTile(
          title: const Text("Default Directory"),
          subtitle: Text(Hive.box("settings").get("directory")),
        ),
        ListTile(
          title: const Text("Server Address"),
          subtitle: Text(Hive.box("settings").get("serverAddress")),
        )
      ]),
    );
  }
}

class Images extends StatefulWidget {
  final DirectoryCell cell;
  const Images({super.key, required this.cell});

  @override
  State<Images> createState() => _ImagesState();
}

class _ImagesState extends State<Images> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        var model = ImagesModel(dir: widget.cell.path);
        model.refresh();

        return model;
      },
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.cell.alias),
            actions: [
              IconButton(
                  onPressed: () {
                    FilePicker.platform
                        .pickFiles(
                            type: FileType.image,
                            withReadStream: false,
                            initialDirectory: widget.cell.path)
                        .then((result) {
                      if (result == null) {
                        return Future.error("result is null");
                      }

                      const ch = MethodChannel("org.gallery");

                      try {
                        var res = ch.invokeMethod("addFiles", <String, dynamic>{
                          "type": 1,
                          "files": result.files.map((e) => e.path!).toList(),
                        });

                        res.then((value) {
                          Provider.of<ImagesModel>(context, listen: false)
                              .refresh();
                          print("succes");
                        }).onError((error, stackTrace) {
                          print("failed: $error");
                        });
                      } catch (e) {
                        print("failed: $e");
                      }
                    }).onError((error, stackTrace) {
                      print("failed: $error");
                      return;
                    });
                  },
                  icon: const Icon(Icons.add))
            ],
          ),
          body: Consumer<ImagesModel>(builder: (context, data, _) {
            return data.isListEmpty()
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ImageGrid(
                    data: data.copy(),
                    onPressed: (context, cell) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) {
                          return ImageView(url: (cell as ImageCell).url());
                        },
                      ));
                    });
          }),
        );
      },
    );
  }
}

class ImageView extends StatefulWidget {
  final String url;
  const ImageView({super.key, required this.url});

  @override
  State<ImageView> createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: PhotoViewGallery.builder(
            itemCount: 1,
            builder: (context, indx) {
              return PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(widget.url));
            }));
  }
}

/* PhotoView(
            filterQuality: FilterQuality.high,
            imageProvider: NetworkImage(widget.url))*/

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
