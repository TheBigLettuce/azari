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
import 'package:gallery/src/db/services/settings.dart';
import 'package:gallery/src/interfaces/booru/safe_mode.dart';
import 'package:gallery/src/pages/home.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart';
import 'package:gallery/src/pages/booru/booru_restored_page.dart';
import 'package:gallery/src/pages/more/settings/settings_widget.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/grid_frame/parts/grid_bottom_padding_provider.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/shimmer_loading_indicator.dart';
import 'package:isar/isar.dart';

import '../../widgets/time_label.dart';

class BookmarkPage extends StatefulWidget {
  final void Function(String? e) saveSelectedPage;
  final PagingStateRegistry pagingRegistry;
  final SelectionGlue Function([Set<GluePreferences>])? generateGlue;
  final void Function() scrollUp;

  const BookmarkPage({
    super.key,
    required this.saveSelectedPage,
    required this.generateGlue,
    required this.pagingRegistry,
    required this.scrollUp,
  });

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  late final StreamSubscription<void> watcher;
  late final StreamSubscription<void> settingsWatcher;
  final List<GridStateBooru> gridStates = [];

  SettingsData settings = SettingsService.currentData;

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

    settingsWatcher = settings.s.watch((s) {
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
      widget.scrollUp();
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
            if (!isRestart) {
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
    return SliverPadding(
      padding: EdgeInsets.only(
        bottom: GridBottomPaddingProvider.of(context, true),
      ),
      sliver: gridStates.isEmpty
          ? const SliverToBoxAdapter(
              child: EmptyWidget(
                gridSeed: 0,
              ),
            )
          : SliverList.list(
              children: makeList(context),
            ),
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
    final size = MediaQuery.sizeOf(context).longestSide * 0.2;

    return GestureDetector(
      onTap: () {
        widget.onPressed(context, widget.state);
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceVariant
                  .withOpacity(0.25),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: SizedBox(
              height: size,
              width: double.infinity,
            ),
          ),
          Column(
            children: [
              SizedBox(
                height: size,
                child: ClipPath.shape(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        children: List.generate(
                          widget.posts.length,
                          (index) {
                            final e = widget.posts[index];

                            return SizedBox(
                              width: constraints.maxWidth / 5,
                              height: double.infinity,
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
                                colorBlendMode: BlendMode.color,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withOpacity(0.4),
                                image: e.thumbnail(),
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(25),
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
                    IconButton.filledTonal(
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
            ],
          )
        ],
      ),
    );
  }
}
