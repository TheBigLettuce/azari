// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/db/base/post_base.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/booru/post.dart';
import 'package:gallery/src/db/schemas/grid_state/grid_state_booru.dart';
import 'package:gallery/src/db/schemas/settings/settings.dart';
import 'package:gallery/src/interfaces/booru/safe_mode.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/pages/home.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart';
import 'package:gallery/src/pages/booru/booru_restored_page.dart';
import 'package:gallery/src/pages/more/settings/settings_widget.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/shimmer_loading_indicator.dart';
import 'package:isar/isar.dart';

import '../../widgets/time_label.dart';

class BookmarkPage extends StatefulWidget {
  final void Function(String? e) saveSelectedPage;
  final PagingStateRegistry pagingRegistry;
  final SelectionGlue<J> Function<J extends Cell>()? generateGlue;

  const BookmarkPage({
    super.key,
    required this.saveSelectedPage,
    required this.generateGlue,
    required this.pagingRegistry,
  });

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  late final StreamSubscription<void> watcher;
  late final StreamSubscription<void> settingsWatcher;
  final List<GridStateBooru> gridStates = [];

  Settings settings = Settings.fromDb();

  final m = <String, List<Post>>{};

  bool dirty = false;
  bool inInner = false;

  @override
  void dispose() {
    watcher.cancel();
    settingsWatcher.cancel();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    settingsWatcher = Settings.watch((s) {
      settings = s!;

      setState(() {});
    });

    watcher = Dbs.g.main.gridStateBoorus
        .watchLazy(fireImmediately: true)
        .listen((event) {
      if (inInner) {
        dirty = true;
      } else {
        _updateDirectly();
      }
    });
  }

  List<Post> getSingle(Isar db) => switch (settings.safeMode) {
        SafeMode.normal => db.posts
            .where()
            .ratingEqualTo(PostRating.general)
            .limit(5)
            .findAllSync(),
        SafeMode.relaxed => db.posts
            .where()
            .ratingEqualTo(PostRating.general)
            .or()
            .ratingEqualTo(PostRating.sensitive)
            .limit(5)
            .findAllSync(),
        SafeMode.none => db.posts.where().limit(5).findAllSync(),
      };

  void _updateDirectly() async {
    gridStates.clear();

    gridStates.addAll(
        Dbs.g.main.gridStateBoorus.where().sortByTimeDesc().findAllSync());

    if (m.isEmpty) {
      for (final e in gridStates) {
        final db = DbsOpen.secondaryGridName(e.name);

        final List<Post> p = getSingle(db);

        List<Post>? l = m[e.name];
        if (l == null) {
          l = [];
          m[e.name] = l;
        }

        l.addAll(p);

        await db.close();
      }
    }

    setState(() {});
  }

  void _procUpdate() {
    inInner = false;

    if (dirty) {
      _updateDirectly();
    }
  }

  void launchGrid(BuildContext context, GridStateBooru e) {
    Dbs.g.main.writeTxnSync(() =>
        Dbs.g.main.gridStateBoorus.putByNameSync(e.copy(time: DateTime.now())));

    widget.saveSelectedPage(e.name);

    inInner = true;

    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return BooruRestoredPage(
          state: e,
          pagingRegistry: widget.pagingRegistry,
          onDispose: () {
            if (!isRestart || settings.buddhaMode) {
              widget.saveSelectedPage(null);
              widget.pagingRegistry.remove(e.name);
            }
          },
          generateGlue: widget.generateGlue,
        );
      },
    )).whenComplete(_procUpdate);
  }

  List<Widget> makeList(BuildContext context) {
    final timeNow = DateTime.now();
    final list = <Widget>[];

    final titleStyle = Theme.of(context)
        .textTheme
        .titleSmall!
        .copyWith(color: Theme.of(context).colorScheme.secondary);

    (int, int, int)? time;

    for (final e in gridStates) {
      final addTime =
          time == null || time != (e.time.day, e.time.month, e.time.year);
      if (addTime) {
        time = (e.time.day, e.time.month, e.time.year);

        list.add(TimeLabel(time, titleStyle, timeNow));
      }

      List<Post>? posts = m[e.name];
      if (posts == null) {
        final db = DbsOpen.secondaryGridName(e.name);

        posts = getSingle(db);

        m[e.name] = posts;

        // TODO: do something about this
        db.close(deleteFromDisk: false);
      }

      list.add(
        Padding(
          padding: EdgeInsets.only(top: addTime ? 0 : 12, left: 12, right: 16),
          child: _BookmarkListTile(
            onPressed: launchGrid,
            key: ValueKey(e.name),
            state: e,
            title: e.tags,
            subtitle: e.booru.string,
            posts: posts,
          ),
        ),
      );
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return gridStates.isEmpty
        ? const SliverToBoxAdapter(
            child: EmptyWidget(
              gridSeed: 0,
            ),
          )
        : SliverList.list(
            children: makeList(context),
          );
  }
}

class BookmarkListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final GridStateBooru state;

  const BookmarkListTile({
    super.key,
    required this.subtitle,
    required this.title,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
                  letterSpacing: -0.4,
                ),
          ),
          Text(
            subtitle,
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
    );
  }
}

class _BookmarkListTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final GridStateBooru state;
  final void Function(BuildContext context, GridStateBooru e) onPressed;
  final List<Post> posts;

  const _BookmarkListTile({
    super.key,
    required this.subtitle,
    required this.title,
    required this.state,
    required this.onPressed,
    required this.posts,
  });

  @override
  State<_BookmarkListTile> createState() => __BookmarkListTileState();
}

class __BookmarkListTileState extends State<_BookmarkListTile> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final singleHeight = (size.width / 5) - (12 / 5) - (18 / 5) - (12 / 5);

    Iterable<Widget> addDividers(
        Iterable<Widget> l, double height, int len, Color? dividerColor) sync* {
      for (final e in l.indexed) {
        yield e.$2;
        if (e.$1 != len - 1) {
          yield VerticalDivider(
            width: 1,
            color: dividerColor,
          );
        }
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        widget.onPressed(context, widget.state);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color:
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.25),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(left: 6, right: 6, top: 6, bottom: 3),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(20)),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Wrap(
                  children: addDividers(
                    widget.posts.indexed.map((e) => SizedBox(
                          height:
                              singleHeight / GridAspectRatio.zeroSeven.value,
                          width: e.$1 != widget.posts.length - 1
                              ? singleHeight - 0.5
                              : singleHeight,
                          child: Image(
                            frameBuilder: (
                              context,
                              child,
                              frame,
                              wasSynchronouslyLoaded,
                            ) {
                              if (wasSynchronouslyLoaded) {
                                return child;
                              }

                              return frame == null
                                  ? const ShimmerLoadingIndicator()
                                  : child.animate().fadeIn();
                            },
                            colorBlendMode: BlendMode.hue,
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withOpacity(0.5),
                            image: e.$2.thumbnail()!,
                            fit: BoxFit.cover,
                          ),
                        )),
                    singleHeight,
                    widget.posts.length,
                    Theme.of(context).colorScheme.background,
                  ).toList(),
                ),
              ),
            ),
            const Padding(padding: EdgeInsets.only(top: 3)),
            Divider(
              height: 0,
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.8),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.25),
              ),
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 8, bottom: 8, left: 12, right: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.9),
                                    letterSpacing: -0.4,
                                  ),
                        ),
                        Text(
                          widget.subtitle,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withOpacity(0.8),
                                    letterSpacing: 0.8,
                                  ),
                        )
                      ],
                    ),
                    IconButton(
                      onPressed: () {
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
                                    title: Text(widget.state.tags),
                                    subtitle:
                                        Text(widget.state.time.toString()),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        DbsOpen.secondaryGridName(
                                                widget.state.name)
                                            .close(deleteFromDisk: true)
                                            .then((value) {
                                          if (value) {
                                            Dbs.g.main.writeTxnSync(() => Dbs
                                                .g.main.gridStateBoorus
                                                .deleteByNameSync(
                                                    widget.state.name));
                                          }

                                          Navigator.pop(context);
                                        });
                                      },
                                      child: Text(
                                          AppLocalizations.of(context)!.yes),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                          AppLocalizations.of(context)!.no),
                                    ),
                                  ],
                                );
                              },
                            ));
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
