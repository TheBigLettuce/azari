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
                    //String outputDir = "";

                    Navigator.of(context).push(DialogRoute(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Choose output directory"),
                            content: TextField(
                              onSubmitted: (value) {},
                            ),
                          );
                        }));
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
      body: Consumer<DirectoryModel>(
        builder: (context, model, _) {
          var cells = model.copy();

          return ImageGrid(
            refresh: () {
              return Future.value(cells.length);
            },
            search: (s) {},
            initalScrollPosition: 0,
            onLongPress: model.delete,
            getCell: (i) => cells[i],
            overrideOnPress: (context, indx) {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return Images(cell: model.get(indx));
              }));
            },
          );
        },
      ),
    );
  }
}
