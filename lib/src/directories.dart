import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'drawer.dart';
import 'image/grid.dart';
import 'image/images.dart';
import 'models/directory.dart';

class Directories extends StatefulWidget {
  const Directories({super.key});

  @override
  State<Directories> createState() => _DirectoriesState();
}

class _DirectoriesState extends State<Directories> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gallery"),
        actions: () {
          var provider = Provider.of<DirectoryModel>(context, listen: false);

          return [
            IconButton(
                onPressed: () {
                  if (Platform.isAndroid) {
                    String outputDir = "";

                    Navigator.of(context).push(DialogRoute(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Choose output directory"),
                            content: TextField(
                              onSubmitted: (value) {
                                outputDir = value;
                                Navigator.of(context).pop();
                                provider.chooseFilesAndUpload((err) {
                                  print(err);
                                }, forcedDir: outputDir);
                              },
                            ),
                          );
                        }));
                  } else {
                    provider.chooseFilesAndUpload((err) {
                      print(err);
                    });
                  }
                },
                icon: const Icon(Icons.add)),
            IconButton(
              tooltip: "Refresh grid",
              onPressed: (() {
                provider.refresh();
              }),
              icon: const Icon(Icons.refresh),
            )
          ];
        }(),
      ),
      drawer: makeDrawer(context, true),
      body: ImageGrid(
        onOverscroll: () {
          return Future.value(true);
        },
        onLongPress: Provider.of<DirectoryModel>(context, listen: false).delete,
        data: Provider.of<DirectoryModel>(context).copy(),
        onPressed: (context, indx) {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return Images(
                cell: Provider.of<DirectoryModel>(context, listen: false)
                    .get(indx));
          }));
        },
      ),
    );
  }
}
