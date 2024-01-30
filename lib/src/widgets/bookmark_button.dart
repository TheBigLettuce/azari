// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/grid_state/grid_state_booru.dart';
import 'package:gallery/src/db/state_restoration.dart';
import 'package:gallery/src/interfaces/booru/booru_api_state.dart';
import 'package:gallery/src/pages/booru/random.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/menu_wrapper.dart';
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
        return [
          const PopupMenuItem(
            enabled: false,
            padding: EdgeInsets.zero,
            child: _WrapEntries(),
          )
        ];
      },
      icon: const Icon(Icons.bookmarks_outlined),
    );
  }
}

class _WrapEntries extends StatefulWidget {
  const _WrapEntries({super.key});

  @override
  State<_WrapEntries> createState() => __WrapEntriesState();
}

class __WrapEntriesState extends State<_WrapEntries> {
  late final StreamSubscription<void> watcher;
  List<GridStateBooru> gridStates =
      Dbs.g.main.gridStateBoorus.where().sortByTimeDesc().findAllSync();

  @override
  void initState() {
    super.initState();

    watcher = Dbs.g.main.gridStateBoorus.watchLazy().listen((event) {
      gridStates =
          Dbs.g.main.gridStateBoorus.where().sortByTimeDesc().findAllSync();

      setState(() {});
    });
  }

  @override
  void dispose() {
    watcher.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> makeList() {
      final timeNow = DateTime.now();
      final list = <PopupMenuEntry>[];

      final titleStyle = Theme.of(context)
          .textTheme
          .titleSmall!
          .copyWith(color: Theme.of(context).colorScheme.secondary);

      (int, int, int)? time;

      for (final e in gridStates) {
        if (time == null || time != (e.time.day, e.time.month, e.time.year)) {
          time = (e.time.day, e.time.month, e.time.year);

          list.add(PopupMenuItem(
            enabled: false,
            padding: const EdgeInsets.all(0),
            child: TimeLabel(time, titleStyle, timeNow),
          ));
        }

        list.add(
          _LongPressPopupItem(
            menuItems: [
              PopupMenuItem(
                onTap: () {
                  Navigator.push(
                      context,
                      DialogRoute(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(
                              AppLocalizations.of(context)!.delete,
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
                                  });
                                },
                                child: Text(AppLocalizations.of(context)!.yes),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(AppLocalizations.of(context)!.no),
                              ),
                            ],
                          );
                        },
                      ));
                },
                child: Text(AppLocalizations.of(context)!.delete),
              )
            ],
            menuTitle: e.tags,
            onTap: () {
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
            // enabled: false,
            padding: const EdgeInsets.only(left: 16),
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.tags,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.9),
                          letterSpacing: -0.4,
                        ),
                  ),
                  Text(
                    e.booru.string,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.8),
                          letterSpacing: 0.8,
                        ),
                  )
                ],
              ),
            ),
          ),
        );
      }

      return list;
    }

    return gridStates.isEmpty
        ? const EmptyWidget(mini: true)
        : Column(
            children: makeList(),
          );
  }
}

class _LongPressPopupItem extends PopupMenuItem {
  final String menuTitle;
  final List<PopupMenuItem<dynamic>> menuItems;

  const _LongPressPopupItem({
    required this.menuItems,
    required this.menuTitle,
    super.padding,
    super.onTap,
    required super.child,
  });

  @override
  PopupMenuItemState<dynamic, PopupMenuItem> createState() =>
      _LongPressPopupItemState();
}

class _LongPressPopupItemState extends PopupMenuItemState {
  @override
  Widget build(BuildContext context) {
    final widget = this.widget as _LongPressPopupItem;

    return MenuWrapper(
      title: widget.menuTitle,
      items: widget.menuItems,
      child: super.build(context),
    );
  }
}
