// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/resource_source/source_storage.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/pages/booru/booru_restored_page.dart";
import "package:azari/src/pages/home/home.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/common_grid_data.dart";
import "package:azari/src/widgets/empty_widget.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:azari/src/widgets/shimmer_loading_indicator.dart";
import "package:azari/src/widgets/time_label.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({
    super.key,
    required this.pagingRegistry,
    required this.db,
    required this.saveSelectedPage,
  });

  final void Function(String? e) saveSelectedPage;
  final PagingStateRegistry pagingRegistry;

  final DbConn db;

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage>
    with CommonGridData<Post, BookmarkPage> {
  GridBookmarkService get gridStateBooru => widget.db.gridBookmarks;

  late final StreamSubscription<void> events;

  final gridSettings = CancellableWatchableGridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.three,
    layoutType: GridLayoutType.list,
  );

  String? currentPage;

  late final source = GenericListSource<GridBookmark>(
    () => Future.value(gridStateBooru.all),
  );

  @override
  void initState() {
    super.initState();

    watchSettings();

    events = gridStateBooru.watch(
      (event) {
        source.clearRefresh();
      },
      true,
    );
  }

  @override
  void dispose() {
    gridSettings.cancel();
    events.cancel();

    super.dispose();
  }

  void launchGrid(BuildContext context, GridBookmark e) {
    currentPage = e.name;

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
            db: widget.db,
          );
        },
      ),
    ).whenComplete(() => currentPage = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return GridConfiguration(
      watch: gridSettings.watch,
      child: GridFrame<GridBookmark>(
        key: gridKey,
        slivers: [
          _BookmarkBody(
            source: source.backingStorage,
            db: widget.db,
            openBookmark: launchGrid,
            progress: source.progress,
          ),
        ],
        functionality: GridFunctionality(
          scrollUpOn: [
            (
              NavigationButtonEvents.maybeOf(context)!,
              () => currentPage == null,
            ),
          ],
          onEmptySource: EmptyWidgetBackground(
            subtitle: l10n.emptyBookmarkedSearches,
          ),
          source: source,
          search: PageNameSearchWidget(
            leading: IconButton(
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              icon: const Icon(Icons.menu_rounded),
            ),
          ),
        ),
        description: GridDescription(
          pullToRefresh: false,
          gridSeed: gridSeed,
          pageName: l10n.bookmarksPageName,
        ),
      ),
    );
  }
}

class _BookmarkBody extends StatefulWidget {
  const _BookmarkBody({
    // super.key,
    required this.source,
    required this.db,
    required this.openBookmark,
    required this.progress,
  });

  final ReadOnlyStorage<int, GridBookmark> source;
  final RefreshingProgress progress;

  final void Function(BuildContext context, GridBookmark e) openBookmark;

  final DbConn db;

  @override
  State<_BookmarkBody> createState() => __BookmarkBodyState();
}

class __BookmarkBodyState extends State<_BookmarkBody> {
  late final StreamSubscription<void> subsc;

  @override
  void initState() {
    super.initState();

    subsc = widget.source.watch((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    subsc.cancel();

    super.dispose();
  }

  List<Widget> makeList(BuildContext context, ThemeData theme) {
    final timeNow = DateTime.now();
    final list = <Widget>[];

    final titleStyle = theme.textTheme.titleSmall!
        .copyWith(color: theme.colorScheme.secondary);

    ({int day, int month, int year})? time;

    for (final e in widget.source) {
      final addTime = time == null ||
          time != (day: e.time.day, month: e.time.month, year: e.time.year);
      if (addTime) {
        time = (day: e.time.day, month: e.time.month, year: e.time.year);

        list.add(TimeLabel(time, titleStyle, timeNow));
      }

      list.add(
        Padding(
          padding: EdgeInsets.only(top: addTime ? 0 : 12, left: 12, right: 16),
          child: _BookmarkListTile(
            openBookmark: widget.openBookmark,
            key: ValueKey(e.name),
            state: e,
            title: e.tags,
            db: widget.db,
            subtitle: e.booru.string,
          ),
        ),
      );
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 8),
      sliver: SliverList.list(
        children: makeList(context, theme),
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
    required this.openBookmark,
    required this.db,
  });

  final String title;
  final String subtitle;

  final GridBookmark state;

  final void Function(BuildContext context, GridBookmark e) openBookmark;

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
    final l10n = context.l10n();

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
          widget.openBookmark(context, widget.state);
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
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
                            widget.state.thumbnails.length,
                            (index) {
                              final e = widget.state.thumbnails[index];

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
                                      .withValues(alpha: 0.4),
                                  image: CachedNetworkImageProvider(e.url),
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
                              color: colorScheme.primary.withValues(alpha: 0.9),
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            widget.subtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.8),
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
                                            if (context.mounted) {
                                              Navigator.pop(context);
                                            }

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
