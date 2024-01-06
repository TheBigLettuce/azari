// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/grid_state/grid_state_booru.dart';
import 'package:gallery/src/db/state_restoration.dart';
import 'package:gallery/src/interfaces/booru/booru_api_state.dart';
import 'package:gallery/src/pages/booru/random.dart';
import 'package:isar/isar.dart';

import 'time_label.dart';

class BookmarkButton extends StatefulWidget {
  const BookmarkButton({super.key});

  @override
  State<BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<BookmarkButton> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
        itemBuilder: (context) {
          final timeNow = DateTime.now();
          final list = <PopupMenuEntry>[];
          final l =
              Dbs.g.main.gridStateBoorus.where().sortByTimeDesc().findAllSync();

          if (l.isEmpty) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text("No bookmarks")));
            return [];
          }

          final titleStyle = Theme.of(context)
              .textTheme
              .titleSmall!
              .copyWith(color: Theme.of(context).colorScheme.secondary);

          (int, int, int)? time;

          for (final e in l) {
            if (time == null ||
                time != (e.time.day, e.time.month, e.time.year)) {
              time = (e.time.day, e.time.month, e.time.year);

              list.add(PopupMenuItem(
                enabled: false,
                padding: const EdgeInsets.all(0),
                child: TimeLabel(time, titleStyle, timeNow),
              ));
            }

            list.add(PopupMenuItem(
                enabled: false,
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5))),
                  title: Text(e.tags,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary)),
                  subtitle: Text(e.booru.string),
                  onLongPress: () {
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
                                      DbsOpen.secondaryGridName(e.name)
                                          .close(deleteFromDisk: true)
                                          .then((value) {
                                        if (value) {
                                          Dbs.g.main.writeTxnSync(() => Dbs
                                              .g.main.gridStateBoorus
                                              .deleteByNameSync(e.name));
                                        }

                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                      });
                                    },
                                    child: Text(
                                        AppLocalizations.of(context)!.yes)),
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child:
                                        Text(AppLocalizations.of(context)!.no)),
                              ],
                            );
                          },
                        ));
                  },
                  onTap: () {
                    Navigator.pop(context);

                    Dbs.g.main.writeTxnSync(() => Dbs.g.main.gridStateBoorus
                        .putByNameSync(e.copy(false, time: DateTime.now())));

                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) {
                        return RandomBooruGrid(
                          api: BooruAPIState.fromEnum(e.booru, page: e.page),
                          tagManager: TagManager.fromEnum(e.booru),
                          tags: e.tags,
                          state: e,
                        );
                      },
                    ));
                  },
                )));
          }

          return list;
        },
        icon: const Icon(Icons.bookmark_rounded));
  }
}
