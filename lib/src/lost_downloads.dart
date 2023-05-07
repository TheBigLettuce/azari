import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/booru/downloader.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/schemas/download_file.dart';
import 'package:isar/isar.dart';

class LostDownloads extends StatefulWidget {
  const LostDownloads({super.key});

  @override
  State<LostDownloads> createState() => _LostDownloadsState();
}

class _LostDownloadsState extends State<LostDownloads> {
  List<File>? _files;
  late final StreamSubscription<void> _updates;
  //bool defunct = false;

  @override
  void initState() {
    super.initState();

    _updates = isar().files.watchLazy(fireImmediately: true).listen((_) async {
      var files = await isar().files.where().sortByDateDesc().findAll();
      setState(() {
        _files = files;
      });
    });
  }

  @override
  void dispose() {
    _updates.cancel();

    super.dispose();
  }

  int _inProcess() {
    int n = 0;
    for (var e in _files!) {
      if (e.inProgress && hasCancelKey(e.id!)) {
        n++;
      }
    }

    return n;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_files == null
            ? "Downloads"
            : _files!.isEmpty
                ? "Downloads (empty)"
                : "Downloads (${_inProcess().toString()}/${_files!.length.toString()})"),
      ),
      body: _files == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: _files!.length,
              itemBuilder: (context, index) {
                return ListTile(
                  onLongPress: () {
                    var file = _files![index];
                    Navigator.push(
                        context,
                        DialogRoute(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                actions: [
                                  TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text("no")),
                                  TextButton(
                                      onPressed: () {
                                        if (hasCancelKey(file.id!)) {
                                          cancelAndRemoveToken(file.id!);
                                          Navigator.pop(context);
                                        } else {
                                          downloadFile(
                                              file.url, file.site, file.name,
                                              oldid: file.id);
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: const Text("yes")),
                                ],
                                title: Text(hasCancelKey(file.id!)
                                    ? "Stop the download?"
                                    : "Retry?"),
                                content: Text(file.name),
                              );
                            }));
                  },
                  title: Text("${_files![index].site}: ${_files![index].name}"),
                  subtitle: Text(!hasCancelKey(_files![index].id!)
                      ? "Failed"
                      : _files![index].inProgress
                          ? "In progress"
                          : "Failed"),
                );
              },
            ),
    );
  }
}
