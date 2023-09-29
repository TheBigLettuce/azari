// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/db/state_restoration.dart';
import 'package:gallery/src/pages/booru/random.dart';
import 'package:gallery/src/schemas/grid_state_booru.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:gallery/src/widgets/settings_label.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../db/isar.dart';
import '../schemas/settings.dart';

class Bookmarks extends StatefulWidget {
  const Bookmarks({super.key});

  @override
  State<Bookmarks> createState() => _BookmarksState();
}

class _BookmarksState extends State<Bookmarks> {
  late final StreamSubscription<Settings?> settingsWatcher;
  late final StreamSubscription gridStatesWatcher;

  final state = SkeletonState(kBookmarksDrawerIndex);
  var settings = Settings.fromDb();

  @override
  void initState() {
    super.initState();

    gridStatesWatcher = Dbs.g.main.gridStateBoorus.watchLazy().listen((event) {
      setState(() {});
    });

    settingsWatcher = Settings.watch((s) {
      settings = s!;

      setState(() {});
    });
  }

  List<Widget> _makeList() {
    final list = <Widget>[];
    final l = Dbs.g.main.gridStateBoorus.where().sortByTimeDesc().findAllSync();

    final titleStyle = Theme.of(context)
        .textTheme
        .titleSmall!
        .copyWith(color: Theme.of(context).colorScheme.secondary);

    (int, int, int)? time;

    for (final e in l) {
      if (time == null || time != (e.time.day, e.time.month, e.time.year)) {
        time = (e.time.day, e.time.month, e.time.year);

        list.add(timeLabel(time, titleStyle));
      }

      list.add(ListTile(
        title: Text(e.tags),
        subtitle: Text(e.booru.string),
        trailing: IconButton(
          onPressed: () {
            Navigator.push(
                context,
                DialogRoute(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text(
                        "Delete", // TODO: change
                      ),
                      content: ListTile(
                        title: Text(e.tags),
                        subtitle: Text(e.time.toString()),
                      ),
                      actions: [
                        TextButton(
                            onPressed: () {
                              IsarDbsOpen.secondaryGridName(e.name)
                                  .close(deleteFromDisk: true)
                                  .then((value) {
                                if (value) {
                                  Dbs.g.main.writeTxnSync(() => Dbs
                                      .g.main.gridStateBoorus
                                      .deleteByNameSync(e.name));
                                }
                              });

                              Navigator.pop(context);
                            },
                            child: Text(AppLocalizations.of(context)!.yes)),
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(AppLocalizations.of(context)!.no)),
                      ],
                    );
                  },
                ));
          },
          icon: const Icon(Icons.delete),
        ),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) {
              return RandomBooruGrid(
                api: BooruAPI.fromEnum(e.booru),
                tagManager: TagManager.fromEnum(e.booru, true),
                tags: e.tags,
                state: e,
              );
            },
          ));
        },
      ));
    }

    return list;
  }

  @override
  void dispose() {
    state.dispose();

    gridStatesWatcher.cancel();
    settingsWatcher.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return makeSkeleton(
      context,
      "Bookmarks",
      state,
      children: _makeList(),
    );
  }
}
