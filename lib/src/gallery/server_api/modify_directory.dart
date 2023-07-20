// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:gallery/src/gallery/interface.dart';
import 'package:gallery/src/schemas/directory.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:logging/logging.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../schemas/directory_file.dart';

class ModifyDirectory extends StatefulWidget {
  final GalleryAPIReadWrite<void, void, Directory, DirectoryFile> api;
  final Directory old;
  final GlobalKey<CallbackGridState> refreshKey;
  const ModifyDirectory(this.api,
      {super.key, required this.old, required this.refreshKey});

  @override
  State<ModifyDirectory> createState() => _ModifyDirectoryState();
}

class _ModifyDirectoryState extends State<ModifyDirectory> {
  late var copy = widget.old;

  final state = SkeletonState(kGalleryDrawerIndex);

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
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return makeSkeleton(
        context, AppLocalizations.of(context)!.modifyDirectoryPageName, state,
        popSenitel: false,
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
                                  copy = copy.copy(dirName: value);
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
        appBarActions: [
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
        ]);
  }
}
