import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../cell/directory.dart';
import 'cells.dart';
import 'view.dart';
import '../models/images.dart';

class Images extends StatefulWidget {
  final DirectoryCell cell;
  const Images({super.key, required this.cell});

  @override
  State<Images> createState() => _ImagesState();
}

class _ImagesState extends State<Images> {
  int? itemCount;
  final GlobalKey<ScaffoldState> _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        var model = ImagesModel(dir: widget.cell.path);
        model.setOnRefresh((newList) {
          setState(() {
            itemCount = newList.length;
          });
        });
        model.refresh();

        return model;
      },
      builder: (context, _) {
        return Scaffold(
          key: _key,
          appBar: AppBar(
            title: Text(widget.cell.alias),
            actions: [
              IconButton(
                  onPressed: () {
                    Navigator.of(context).push(DialogRoute(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(widget.cell.alias),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView(children: [
                                ListTile(
                                  title: const Text("Alias"),
                                  subtitle: Text(widget.cell.alias),
                                ),
                                ListTile(
                                  title: const Text("Path"),
                                  subtitle: Text(widget.cell.path),
                                ),
                                ListTile(
                                  title: const Text("Number of elements"),
                                  subtitle: Text(itemCount != null
                                      ? itemCount.toString()
                                      : "0"),
                                )
                              ]),
                            ),
                          );
                        }));
                  },
                  icon: const Icon(Icons.info_outline)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.add))
            ],
          ),
          body: Consumer<ImagesModel>(builder: (context, data, _) {
            return data.isListEmpty()
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : () {
                    var cells = data.copy();

                    return CellsWidget(
                      scaffoldKey: _key,
                      refresh: () {
                        return Future.value(cells.length);
                      },
                      hasReachedEnd: () {
                        return true;
                      },
                      search: (s) {},
                      getCell: (i) => cells[i],
                      initalScrollPosition: 0,
                      onLongPress: (indx) {
                        return Navigator.of(context).push(DialogRoute(
                            context: context,
                            builder: ((context) {
                              return AlertDialog(
                                title: const Text("Do you want to delete:"),
                                content: Text(widget.cell.alias),
                                actions: [
                                  TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text("no")),
                                  TextButton(
                                      onPressed: () {
                                        data.delete(indx);
                                      },
                                      child: const Text("yes")),
                                ],
                              );
                            })));
                      },
                    );
                  }();
          }),
        );
      },
    );
  }
}
