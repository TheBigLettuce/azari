// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/logic/cancellable_grid_settings_data.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/posts_source.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/booru/actions.dart" as actions;
import "package:azari/src/ui/material/pages/booru/booru_page.dart";
import "package:azari/src/ui/material/pages/gallery/directories.dart";
import "package:azari/src/ui/material/pages/gallery/files.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/widgets/empty_widget.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/ui/material/widgets/scaffold_selection_bar.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_aspect_ratio.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_column.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/shell_app_bar_type.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/shell_fab_type.dart";
import "package:azari/src/ui/material/widgets/shell/parts/shell_settings_button.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";

class BooruRestoredPage extends StatefulWidget {
  const BooruRestoredPage({
    super.key,
    required this.booru,
    required this.tags,
    this.overrideSafeMode,
    this.name,
    this.thenMoveTo,
    this.trySearchBookmarkByTags = false,
  });

  final String? name;
  final Booru booru;
  final String tags;
  final SafeMode? overrideSafeMode;

  final PathVolume? thenMoveTo;
  final bool trySearchBookmarkByTags;

  static bool hasServicesRequired() => GridDbService.available;

  static Future<void> open(
    BuildContext context, {
    required Booru booru,
    required String tags,
    void Function(String? e)? saveSelectedPage,
    String? name,
    PagingStateRegistry? pagingRegistry,
    SafeMode? overrideSafeMode,
    PathVolume? thenMoveTo,
    bool trySearchBookmarkByTags = false,
  }) {
    if (!hasServicesRequired()) {
      addAlert(
        "BooruRestoredPage",
        "Booru functionality isn't available", // TODO: change
      );

      return Future.value();
    }

    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => BooruRestoredPage(
          booru: booru,
          tags: tags,
          name: name,
          overrideSafeMode: overrideSafeMode,
          thenMoveTo: thenMoveTo,
          trySearchBookmarkByTags: trySearchBookmarkByTags,
        ),
      ),
    );
  }

  @override
  State<BooruRestoredPage> createState() => _BooruRestoredPageState();
}

class _BooruRestoredPageState extends State<BooruRestoredPage>
    with SettingsWatcherMixin<BooruRestoredPage> {
  final gridSettings = CancellableGridSettingsData.noPersist(
    hideName: true,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.two,
    layoutType: GridLayoutType.gridQuilted,
  );

  BooruAPI get api => pagingState.api;
  GridPostSource get source => pagingState.source;

  late final StreamSubscription<void>? favoritesWatcher;
  late final StreamSubscription<void>? hiddenPostWatcher;

  late final RestoredBooruPageState pagingState;

  final _textKey = GlobalKey<__AppBarTextState>();

  RestoredBooruPageState makePageEntry(
    String name,
    bool addToBookmarks,
    SafeMode? safeMode,
    String tags,
  ) {
    final secondary = const GridDbService().openSecondary(
      widget.booru,
      name,
      safeMode,
      !addToBookmarks,
    );

    return RestoredBooruPageState(
      widget.booru,
      tags,
      secondary,
      addToBookmarks,
      [
        if (DownloadManager.available && LocalTagsService.available)
          actions.downloadPost(context, widget.booru, widget.thenMoveTo),
        if (FavoritePostSourceService.available)
          actions.favorites(context, showDeleteSnackbar: true),
        if (HiddenBooruPostsService.available) actions.hide(context),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    final tagsTrimmed = widget.tags.trim();

    final bookmarkByName =
        widget.trySearchBookmarkByTags && GridBookmarkService.available
        ? const GridBookmarkService().getFirstByTags(tagsTrimmed, widget.booru)
        : null;

    final String name;
    if (bookmarkByName == null) {
      name = widget.name ?? DateTime.now().microsecondsSinceEpoch.toString();
    } else {
      name = bookmarkByName.name;
    }

    pagingState = makePageEntry(
      name,
      bookmarkByName != null || widget.name != null,
      bookmarkByName != null ? null : widget.overrideSafeMode,
      bookmarkByName?.tags ?? tagsTrimmed,
    );

    TagManagerService.safe()?.latest.add(bookmarkByName?.tags ?? tagsTrimmed);

    if (GridBookmarkService.available &&
        const GridBookmarkService().get(pagingState.secondaryGrid.name) ==
            null) {
      const GridBookmarkService().add(
        GridBookmark(
          booru: widget.booru,
          name: pagingState.secondaryGrid.name,
          time: DateTime.now(),
          tags: bookmarkByName?.tags ?? tagsTrimmed,
        ),
      );
    }

    hiddenPostWatcher = HiddenBooruPostsService.safe()?.watch((_) {
      source.backingStorage.addAll([]);
    });

    favoritesWatcher = FavoritePostSourceService.safe()?.cache.countEvents
        .listen((event) {
          source.backingStorage.addAll([]);
        });
  }

  @override
  void dispose() {
    gridSettings.cancel();
    favoritesWatcher?.cancel();
    hiddenPostWatcher?.cancel();

    final gridBookmarks = GridBookmarkService.safe();
    if (gridBookmarks != null && !pagingState.addToBookmarks) {
      gridBookmarks.delete(pagingState.secondaryGrid.name);
    }
    pagingState.dispose(pagingState.addToBookmarks);

    super.dispose();
  }

  void _onTagPressed(
    BuildContext context,
    Booru booru,
    String tag,
    SafeMode? safeMode,
  ) {
    PauseVideoNotifier.maybePauseOf(context, true);

    BooruRestoredPage.open(
      context,
      booru: booru,
      overrideSafeMode: safeMode,
      tags: tag,
      saveSelectedPage: (s) {},
    ).then((value) {
      if (context.mounted) {
        PauseVideoNotifier.maybePauseOf(context, false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
    final navigationButtonEvents = NavigationButtonEvents.maybeOf(context);
    final theme = Theme.of(context);

    return ScaffoldWithSelectionBar(
      actions: pagingState.selectionActions,
      child: Builder(
        builder: (context) {
          return BooruAPINotifier(
            api: api,
            child: GridPopScope(
              searchTextController: null,
              filter: null,
              child: ShellScope(
                fab: navigationButtonEvents == null
                    ? const DefaultShellFab()
                    : const NoShellFab(),
                stackInjector: pagingState.status,
                configWatcher: gridSettings.watch,
                settingsButton: ShellSettingsButton.onlyHeader(
                  SafeModeButton(secondaryGrid: pagingState.secondaryGrid),
                ),
                appBar: RawAppBarType((context, settingsButton, bottomWidget) {
                  return SliverAppBar(
                    leading: const BackButton(),
                    backgroundColor: theme.colorScheme.surface.withValues(
                      alpha: 1,
                    ),
                    scrolledUnderElevation: 0,
                    floating: true,
                    pinned: true,
                    snap: true,
                    stretch: true,
                    bottom:
                        bottomWidget ??
                        const PreferredSize(
                          preferredSize: Size.zero,
                          child: SizedBox.shrink(),
                        ),
                    title: _AppBarText(key: _textKey, source: source),
                    actions: [
                      IconButton(
                        icon: pagingState.addToBookmarks
                            ? const Icon(Icons.bookmark_remove_rounded)
                            : const Icon(Icons.bookmark_add_rounded),
                        onPressed: () {
                          pagingState.addToBookmarks =
                              !pagingState.addToBookmarks;

                          setState(() {});
                        },
                      ),
                      if (settingsButton != null) settingsButton,
                    ],
                  );
                }),
                elements: [
                  ElementPriority(
                    ShellElement(
                      // key: gridKey,
                      state: pagingState.status,
                      initialScrollPosition: pagingState.offset,
                      animationsOnSourceWatch: false,
                      scrollUpOn: navigationButtonEvents == null
                          ? const []
                          : [(navigationButtonEvents, null)],
                      scrollingState: ScrollingStateSinkProvider.maybeOf(
                        context,
                      ),
                      updateScrollPosition: pagingState.setOffset,
                      registerNotifiers: (child) => OnBooruTagPressed(
                        onPressed: _onTagPressed,
                        child: pagingState.status.source.inject(
                          BooruAPINotifier(api: api, child: child),
                        ),
                      ),
                      slivers: [
                        Builder(
                          builder: (context) {
                            final padding = MediaQuery.systemGestureInsetsOf(
                              context,
                            );

                            return SliverPadding(
                              padding: EdgeInsets.only(
                                left: padding.left * 0.2,
                                right: padding.right * 0.2,
                              ),
                              sliver: CurrentGridSettingsLayout<Post>(
                                source: source.backingStorage,
                                progress: source.progress,
                                // gridSeed: gridSeed,
                                selection: null,
                                buildEmpty: (e) => EmptyWidgetWithButton(
                                  error: e,
                                  buttonText: l10n.openInBrowser,
                                  onPressed: () {
                                    launchUrl(
                                      Uri.https(api.booru.url),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        Builder(
                          builder: (context) {
                            final padding = MediaQuery.systemGestureInsetsOf(
                              context,
                            );

                            return SliverPadding(
                              padding: EdgeInsets.only(
                                left: padding.left * 0.2,
                                right: padding.right * 0.2,
                              ),
                              sliver: GridConfigPlaceholders(
                                progress: source.progress,
                                // randomNumber: gridSeed,
                              ),
                            );
                          },
                        ),
                        GridFooter<void>(
                          storage: source.backingStorage,
                          name: source.tags,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class RestoredBooruPageState implements PagingEntry {
  RestoredBooruPageState(
    Booru booru,
    String tags,
    this.secondaryGrid,
    this.addToBookmarks,
    this.actions,
    // this.selectionController,
  ) : client = BooruAPI.defaultClientForBooru(booru) {
    api = BooruAPI.fromEnum(booru, client);

    void saveThumbnails(GridPostSource instance) {
      const GridBookmarkService()
          .get(secondaryGrid.name)!
          .copy(
            thumbnails: instance.lastFive
                .map(
                  (e) => GridBookmarkThumbnail(
                    url: e.previewUrl,
                    rating: e.rating,
                  ),
                )
                .toList(),
          )
          .maybeSave();
    }

    source = secondaryGrid.makeSource(
      api,
      this,
      tags,
      onNextCompleted: saveThumbnails,
      onClearRefreshCompleted: saveThumbnails,
    );

    status = SourceShellElementState(
      source: source,
      onEmpty: SourceOnEmptyInterface(
        source,
        (context) => context.l10n().emptyNoPosts,
      ),
      selectionController: selectionActions.controller,
      actions: actions,
      updatesAvailable: source.updatesAvailable,
    );
  }

  bool addToBookmarks;

  @override
  void updateTime() => const GridBookmarkService()
      .get(secondaryGrid.name)!
      .copy(time: DateTime.now())
      .maybeSave();

  final Dio client;
  late final BooruAPI api;

  final SecondaryGridHandle secondaryGrid;
  late final GridPostSource source;
  late final SourceShellElementState<Post> status;
  final List<SelectionBarAction> actions;
  final selectionActions = SelectionActions();

  int? currentSkipped;

  @override
  bool reachedEnd = false;

  @override
  Future<void> dispose([bool closeGrid = true]) {
    status.destroy();
    client.close();
    source.destroy();

    if (closeGrid) {
      return secondaryGrid.close();
    } else {
      return secondaryGrid.destroy();
    }
  }

  SafeMode get safeMode => secondaryGrid.currentState.safeMode;
  set safeMode(SafeMode s) =>
      secondaryGrid.currentState.copy(safeMode: s).saveSecondary(secondaryGrid);

  @override
  double get offset => secondaryGrid.currentState.offset;

  @override
  int get page => secondaryGrid.page;

  @override
  set page(int p) => secondaryGrid.page = p;

  @override
  void setOffset(double o) =>
      secondaryGrid.currentState.copy(offset: o).saveSecondary(secondaryGrid);
}

class _AppBarText extends StatefulWidget {
  const _AppBarText({required super.key, required this.source});

  final GridPostSource source;

  @override
  State<_AppBarText> createState() => __AppBarTextState();
}

class __AppBarTextState extends State<_AppBarText> {
  @override
  Widget build(BuildContext context) {
    return Text(widget.source.tags);
  }
}
