// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/db/schemas/favorite_booru.dart';
import 'package:gallery/src/db/schemas/tags.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';

import '../../widgets/skeletons/drawer/destinations.dart';
import '../../widgets/grid/actions/booru_grid.dart';
import '../../net/downloader.dart';
import '../../interfaces/booru.dart';
import '../../db/post_tags.dart';
import '../../db/initalize_db.dart';
import '../../db/state_restoration.dart';
import '../../db/schemas/download_file.dart';
import '../../db/schemas/post.dart';
import '../../db/schemas/settings.dart';
import '../../widgets/search_bar/search_launch_grid_data.dart';
import '../../widgets/skeletons/grid_skeleton_state.dart';
import '../../widgets/notifiers/booru_api.dart';
import '../../widgets/notifiers/tag_manager.dart';
import '../../widgets/radio_dialog.dart';
import '../../widgets/search_bar/search_launch_grid.dart';

import '../../widgets/skeletons/make_grid_skeleton.dart';
import '../settings/settings_widget.dart';

import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:url_launcher/url_launcher.dart';

import 'secondary.dart';
import '../../db/schemas/settings.dart' as schema show AspectRatio;

PopupMenuButton gridSettingsButton(GridSettings gridSettings,
    {required void Function(schema.AspectRatio?) selectRatio,
    required void Function(bool)? selectHideName,
    required void Function(bool)? selectListView,
    required void Function(GridColumn?) selectGridColumn}) {
  return PopupMenuButton(
    icon: const Icon(Icons.more_horiz_outlined),
    itemBuilder: (context) => [
      if (selectListView != null)
        _listView(gridSettings.listView, selectListView),
      if (selectHideName != null)
        _hideName(context, gridSettings.hideName, selectHideName),
      _ratio(context, gridSettings.aspectRatio, selectRatio),
      _columns(context, gridSettings.columns, selectGridColumn)
    ],
  );
}

PopupMenuItem _hideName(
    BuildContext context, bool hideName, void Function(bool) select) {
  return PopupMenuItem(
    child: Text(hideName
        ? "Show names" // TODO: change
        : "Hide names"),
    onTap: () => select(!hideName),
  );
}

PopupMenuItem _ratio(BuildContext context, schema.AspectRatio aspectRatio,
    void Function(schema.AspectRatio?) select) {
  return PopupMenuItem(
    child: const Text("Ratio"), // TODO: change
    onTap: () => radioDialog(
      context,
      schema.AspectRatio.values.map((e) => (e, e.value.toString())).toList(),
      aspectRatio,
      select,
      title: AppLocalizations.of(context)!.cellAspectRadio,
    ),
  );
}

PopupMenuItem _columns(BuildContext context, GridColumn columns,
    void Function(GridColumn?) select) {
  return PopupMenuItem(
    child: const Text("Columns"), // TODO: change
    onTap: () => radioDialog(
      context,
      GridColumn.values.map((e) => (e, e.number.toString())).toList(),
      columns,
      select,
      title: AppLocalizations.of(context)!.nPerElementsSetting,
    ),
  );
}

PopupMenuItem _listView(bool listView, void Function(bool) select) {
  return PopupMenuItem(
    child: Text(listView
        ? "Grid view" // TODO: change
        : "List view"),
    onTap: () => select(!listView),
  );
}

class MainBooruGrid extends StatefulWidget {
  const MainBooruGrid({super.key});

  static Widget bookmarkButton(
      BuildContext context, GridSkeletonState state, void Function() f) {
    return IconButton(
        onPressed: () {
          f();
          ScaffoldMessenger.of(state.scaffoldKey.currentContext!)
              .showSnackBar(const SnackBar(
                  content: Text(
            "Bookmarked", // TODO: change
          )));
          state.gridKey.currentState?.selection.currentBottomSheet?.close();
          state.gridKey.currentState?.selection.selected.clear();
          Navigator.pop(context);
        },
        icon: const Icon(Icons.bookmark_add));
  }

  static PopupMenuButton gridButton(Settings settings) {
    return gridSettingsButton(
      settings.booru,
      selectHideName: null,
      selectGridColumn: (columns) =>
          settings.copy(booru: settings.booru.copy(columns: columns)).save(),
      selectListView: (listView) =>
          settings.copy(booru: settings.booru.copy(listView: listView)).save(),
      selectRatio: (ratio) =>
          settings.copy(booru: settings.booru.copy(aspectRatio: ratio)).save(),
    );
  }

  @override
  State<MainBooruGrid> createState() => _MainBooruGridState();
}

class _MainBooruGridState extends State<MainBooruGrid>
    with SearchLaunchGrid<Post> {
  late final StreamSubscription<Settings?> settingsWatcher;
  late final StreamSubscription favoritesWatcher;

  int? currentSkipped;

  late final BooruAPI api;
  late final TagManager tagManager;
  late final Isar mainGrid;
  late final StateRestoration restore;

  bool reachedEnd = false;

  final state = GridSkeletonState<Post>(index: kBooruGridDrawerIndex);

  @override
  void initState() {
    super.initState();

    mainGrid = DbsOpen.primaryGrid(state.settings.selectedBooru);
    restore = StateRestoration(
        mainGrid, state.settings.selectedBooru.string, () => api.currentPage);
    api = BooruAPI.fromSettings(page: restore.copy.page);

    tagManager = TagManager(restore, (fire, f) {
      return mainGrid.tags.watchLazy(fireImmediately: fire).listen((event) {
        f();
      });
    });

    searchHook(SearchLaunchGridData(
        mainFocus: state.mainFocus,
        searchText: "",
        addItems: null,
        restorable: true));

    if (api.wouldBecomeStale &&
        state.settings.autoRefresh &&
        state.settings.autoRefreshMicroseconds != 0 &&
        restore.copy.time.isBefore(DateTime.now()
            .subtract(state.settings.autoRefreshMicroseconds.microseconds))) {
      mainGrid.writeTxnSync(() => mainGrid.posts.clearSync());
      restore.updateTime();
    }

    settingsWatcher = Settings.watch((s) {
      state.settings = s!;

      setState(() {});
    });

    favoritesWatcher = Dbs.g.main.favoriteBoorus
        .watchLazy(fireImmediately: false)
        .listen((event) {
      state.gridKey.currentState?.imageViewKey.currentState?.setState(() {});
      setState(() {});
    });
  }

  @override
  void dispose() {
    settingsWatcher.cancel();
    favoritesWatcher.cancel();

    mainGrid.close().then((value) => restartOver());

    disposeSearch();

    state.dispose();

    api.close();

    super.dispose();
  }

  Future<int> _clearAndRefresh() async {
    try {
      restore.updateTime();

      final list = await api.page(0, "", tagManager.excluded);
      restore.updateScrollPosition(0);
      currentSkipped = list.$2;
      mainGrid.writeTxnSync(() {
        mainGrid.posts.clearSync();
        return mainGrid.posts.putAllByFileUrlSync(list.$1);
      });

      reachedEnd = false;
    } catch (e) {
      rethrow;
    }

    return mainGrid.posts.count();
  }

  Future<void> _download(int i) async {
    final p = mainGrid.posts.getSync(i + 1);
    if (p == null) {
      return Future.value();
    }

    PostTags.g.addTagsPost(p.filename(), p.tags, true);

    return Downloader.g.add(
        DownloadFile.d(
            url: p.fileDownloadUrl(),
            site: api.booru.url,
            name: p.filename(),
            thumbUrl: p.previewUrl),
        state.settings);
  }

  Future<int> _addLast() async {
    if (reachedEnd) {
      return mainGrid.posts.countSync();
    }
    final p = mainGrid.posts.getSync(mainGrid.posts.countSync());
    if (p == null) {
      return mainGrid.posts.countSync();
    }

    try {
      final list = await api.fromPost(
          currentSkipped != null && currentSkipped! < p.id
              ? currentSkipped!
              : p.id,
          "",
          tagManager.excluded);
      if (list.$1.isEmpty && currentSkipped == null) {
        reachedEnd = true;
      } else {
        currentSkipped = list.$2;
        final oldCount = mainGrid.posts.countSync();
        mainGrid
            .writeTxnSync(() => mainGrid.posts.putAllByFileUrlSync(list.$1));
        if (mainGrid.posts.countSync() - oldCount < 3) {
          return await _addLast();
        }
      }
    } catch (e, trace) {
      log("_addLast on grid ${state.settings.selectedBooru.string}",
          level: Level.WARNING.value, error: e, stackTrace: trace);
    }

    return mainGrid.posts.count();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewPaddingOf(context);

    return BooruAPINotifier(
        api: api,
        child: TagManagerNotifier(
            tagManager: tagManager,
            child: Builder(
              builder: (context) {
                return makeGridSkeleton(
                    context,
                    state,
                    CallbackGrid<Post>(
                      key: state.gridKey,
                      systemNavigationInsets: insets,
                      registerNotifiers: [
                        (child) => TagManagerNotifier(
                            tagManager: tagManager, child: child),
                        (child) => BooruAPINotifier(api: api, child: child),
                      ],
                      menuButtonItems: [
                        MainBooruGrid.gridButton(state.settings)
                      ],
                      addIconsImage: (post) => [
                        BooruGridActions.favorites(context, post),
                        BooruGridActions.download(context, api)
                      ],
                      onExitImageView: () =>
                          restore.removeScrollTagsSelectedPost(),
                      description: GridDescription(
                        kBooruGridDrawerIndex,
                        [
                          BooruGridActions.download(context, api),
                          BooruGridActions.favorites(context, null,
                              showDeleteSnackbar: true)
                        ],
                        state.settings.booru.columns,
                        listView: state.settings.booru.listView,
                        keybindsDescription:
                            AppLocalizations.of(context)!.booruGridPageName,
                      ),
                      hasReachedEnd: () => reachedEnd,
                      mainFocus: state.mainFocus,
                      scaffoldKey: state.scaffoldKey,
                      onError: (error) {
                        return OutlinedButton(
                          onPressed: () {
                            launchUrl(Uri.https(api.booru.url),
                                mode: LaunchMode.externalApplication);
                          },
                          child:
                              Text(AppLocalizations.of(context)!.openInBrowser),
                        );
                      },
                      aspectRatio: state.settings.booru.aspectRatio.value,
                      getCell: (i) => mainGrid.posts.getSync(i + 1)!,
                      loadNext: _addLast,
                      refresh: _clearAndRefresh,
                      hideShowFab: (
                              {required bool fab, required bool foreground}) =>
                          state.updateFab(setState,
                              fab: fab, foreground: foreground),
                      hideAlias: true,
                      download: _download,
                      updateScrollPosition: restore.updateScrollPosition,
                      initalScrollPosition: restore.copy.scrollPositionGrid,
                      initalCellCount: mainGrid.posts.countSync(),
                      beforeImageViewRestore: () {
                        final last = restore.last();
                        if (last != null) {
                          WidgetsBinding.instance
                              .scheduleFrameCallback((timeStamp) {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) {
                                return SecondaryBooruGrid(
                                  restore: last,
                                  noRestoreOnBack: false,
                                  api: BooruAPI.fromEnum(api.booru, page: null),
                                  tagManager: tagManager,
                                  instance:
                                      DbsOpen.secondaryGridName(last.copy.name),
                                );
                              },
                            ));
                          });
                        }
                      },
                      searchWidget: SearchAndFocus(
                          searchWidget(context, hint: api.booru.name),
                          searchFocus, onPressed: () {
                        if (currentlyHighlightedTag != "") {
                          state.mainFocus.unfocus();
                          tagManager.onTagPressed(
                              context,
                              Tag.string(tag: currentlyHighlightedTag),
                              api.booru,
                              true);
                        }
                      }),
                      pageViewScrollingOffset: restore.copy.scrollPositionTags,
                      initalCell: restore.copy.selectedPost,
                    ),
                    overrideBooru: api.booru,
                    popSenitel: false);
              },
            )));
  }
}
