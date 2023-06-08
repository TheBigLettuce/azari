import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:gallery/src/gallery/interface.dart';
import 'package:gallery/src/schemas/directory.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:logging/logging.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ModifyDirectory extends StatefulWidget {
  final GalleryAPI api;
  final Directory old;
  final GlobalKey<CallbackGridState> refreshKey;
  const ModifyDirectory(this.api,
      {super.key, required this.old, required this.refreshKey});

  @override
  State<ModifyDirectory> createState() => _ModifyDirectoryState();
}

class _ModifyDirectoryState extends State<ModifyDirectory> {
  late var copy = widget.old;

  void _delete(Directory d) async {
    try {
      await widget.api.delete(d);

      widget.refreshKey.currentState!.refresh();
    } catch (e, trace) {
      log("deleting directory",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
    }
  }

  void _modify() async {
    try {
      await widget.api.modify(widget.old, copy);

      widget.refreshKey.currentState!.refresh();
    } catch (e, trace) {
      log("modifying directory",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.modifyDirectoryPageName),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    DialogRoute(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(AppLocalizations.of(context)!
                                .doYouWantToDelete(copy.dirName)),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child:
                                      Text(AppLocalizations.of(context)!.no)),
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.pop(context);

                                    _delete(widget.old);
                                  },
                                  child:
                                      Text(AppLocalizations.of(context)!.yes)),
                            ],
                          );
                        }));
              },
              icon: const Icon(Icons.delete))
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(AppLocalizations.of(context)!.directoryAlias),
            subtitle: Text(copy.dirName),
            trailing: TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    DialogRoute(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(AppLocalizations.of(context)!.newAlias),
                            content: TextField(
                              onSubmitted: (value) {
                                setState(() {
                                  copy.dirName = value;
                                });
                                Navigator.pop(context);

                                _modify();
                              },
                            ),
                          );
                        }));
              },
              child: Text(AppLocalizations.of(context)!.changeAlias),
            ),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.directoryPath),
            enabled: false,
            subtitle: Text(widget.old.dirPath),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.directoryCount),
            enabled: false,
            subtitle: Text(widget.old.count.toString()),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.dateModified),
            enabled: false,
            subtitle: Text(widget.old.time.toString()),
          )
        ],
      ),
    );
  }
}
