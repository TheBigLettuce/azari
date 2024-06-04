// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/base/post_base.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/pages/booru/booru_restored_page.dart";
import "package:gallery/src/pages/home.dart";
import "package:gallery/src/pages/more/tags/tags_widget.dart";
import "package:gallery/src/widgets/empty_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_bottom_padding_provider.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:gallery/src/widgets/shimmer_loading_indicator.dart";
import "package:gallery/src/widgets/time_label.dart";

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({
    super.key,
    required this.saveSelectedPage,
    required this.generateGlue,
    required this.pagingRegistry,
    required this.scrollUp,
    required this.db,
  });

  final void Function(String? e) saveSelectedPage;
  final PagingStateRegistry pagingRegistry;
  final SelectionGlue Function([Set<GluePreferences>])? generateGlue;
  final void Function() scrollUp;

  final DbConn db;

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  GridBookmarkService get gridStateBooru => widget.db.gridBookmarks;

  late final StreamSubscription<void> watcher;
  late final StreamSubscription<void> settingsWatcher;
  final List<GridBookmark> gridStates = [];

  SettingsData settings = SettingsService.db().current;

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

    watcher = gridStateBooru.watch(
      (event) {
        if (inInner) {
          dirty = true;
        } else {
          _updateDirectly();
        }
      },
      true,
    );
  }

  List<Post> getSingle(SecondaryGridService grid) =>
      switch (settings.safeMode) {
        SafeMode.normal => grid.savedPosts.firstFiveNormal,
        SafeMode.relaxed => grid.savedPosts.firstFiveRelaxed,
        SafeMode.none => grid.savedPosts.firstFiveAll,
      };

  Future<void> _updateDirectly() async {
    gridStates.clear();
    gridStates.addAll(gridStateBooru.all);

    if (m.isEmpty) {
      for (final e in gridStates) {
        final grid = widget.db.secondaryGrid(e.booru, e.name, null);
        final List<Post> p = getSingle(grid);

        List<Post>? l = m[e.name];
        if (l == null) {
          l = [];
          m[e.name] = l;
        }

        l.addAll(p);

        await grid.close();
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

  void launchGrid(BuildContext context, GridBookmark e) {
    inInner = true;

    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return BooruRestoredPage(
            booru: e.booru,
            tags: e.tags,
            name: e.name,
            pagingRegistry: widget.pagingRegistry,
            saveSelectedPage: widget.saveSelectedPage,
            generateGlue: widget.generateGlue,
            db: widget.db,
          );
        },
      ),
    ).whenComplete(_procUpdate);
  }

  List<Widget> makeList(BuildContext context, ThemeData theme) {
    final timeNow = DateTime.now();
    final list = <Widget>[];

    final titleStyle = theme.textTheme.titleSmall!
        .copyWith(color: theme.colorScheme.secondary);

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
        final grid = widget.db.secondaryGrid(e.booru, e.name, null);
        posts = getSingle(grid);

        m[e.name] = posts;

        // TODO: do something about this
        grid.close();
      }

      list.add(
        Padding(
          padding: EdgeInsets.only(top: addTime ? 0 : 12, left: 12, right: 16),
          child: _BookmarkListTile(
            onPressed: launchGrid,
            key: ValueKey(e.name),
            state: e,
            title: e.tags,
            db: widget.db,
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
    final theme = Theme.of(context);

    final list = makeList(context, theme);

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
              children: list,
            ),
    );
  }
}

class BookmarkListTile extends StatelessWidget {
  const BookmarkListTile({
    super.key,
    required this.subtitle,
    required this.title,
    required this.state,
  });
  final String title;
  final String subtitle;
  final GridBookmark state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.primary.withOpacity(0.9),
              letterSpacing: -0.4,
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarkListTile extends StatefulWidget {
  const _BookmarkListTile({
    super.key,
    required this.subtitle,
    required this.title,
    required this.state,
    required this.onPressed,
    required this.posts,
    required this.db,
  });

  final String title;
  final String subtitle;
  final GridBookmark state;
  final void Function(BuildContext context, GridBookmark e) onPressed;
  final List<Post> posts;

  final DbConn db;

  @override
  State<_BookmarkListTile> createState() => __BookmarkListTileState();
}

class __BookmarkListTileState extends State<_BookmarkListTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).longestSide * 0.2;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Animate(
      autoPlay: false,
      value: 0,
      controller: animationController,
      effects: const [
        FadeEffect(
          delay: Duration(milliseconds: 80),
          duration: Durations.medium4,
          curve: Easing.standard,
          begin: 1,
          end: 0,
        ),
        SlideEffect(
          duration: Durations.medium4,
          curve: Easing.emphasizedDecelerate,
          begin: Offset.zero,
          end: Offset(1, 0),
        ),
      ],
      child: GestureDetector(
        onTap: () {
          widget.onPressed(context, widget.state);
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.25),
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
                                  color: colorScheme.primaryContainer
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.primary.withOpacity(0.9),
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            widget.subtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  colorScheme.onSurfaceVariant.withOpacity(0.8),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      IconButton.filledTonal(
                        onPressed: () {
                          Navigator.push(
                            context,
                            DialogRoute<void>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text(
                                    l10n.delete,
                                  ),
                                  content: ListTile(
                                    title: Text(widget.state.tags),
                                    subtitle:
                                        Text(widget.state.time.toString()),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        widget.db
                                            .secondaryGrid(
                                              widget.state.booru,
                                              widget.state.name,
                                              null,
                                            )
                                            .destroy()
                                            .then(
                                          (value) {
                                            Navigator.pop(context);

                                            animationController
                                                .forward()
                                                .then((_) {
                                              widget.db.gridBookmarks
                                                  .delete(widget.state.name);
                                            });
                                          },
                                        );
                                      },
                                      child: Text(l10n.yes),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(l10n.no),
                                    ),
                                  ],
                                );
                              },
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
