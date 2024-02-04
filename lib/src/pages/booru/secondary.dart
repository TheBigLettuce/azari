// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/db/schemas/booru/favorite_booru.dart';
import 'package:gallery/src/db/schemas/tags/tags.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/grid/selection_glue.dart';
import 'package:gallery/src/interfaces/logging/logging.dart';
import 'package:gallery/src/pages/booru/add_to_bookmarks_button.dart';
import 'package:gallery/src/widgets/grid/wrap_grid_page.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:isar/isar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../db/schemas/booru/note_booru.dart';
import '../../db/schemas/statistics/statistics_booru.dart';
import '../../db/schemas/statistics/statistics_general.dart';
import '../../widgets/image_view/image_view.dart';
import 'grid_button.dart';

import '../../widgets/grid/actions/booru_grid.dart';
import '../../widgets/grid/callback_grid.dart';
import '../../net/downloader.dart';
import '../../interfaces/booru/booru_api_state.dart';
import '../../db/tags/post_tags.dart';
import '../../db/initalize_db.dart';
import '../../db/state_restoration.dart';
import '../../db/schemas/downloader/download_file.dart';
import '../../db/schemas/booru/post.dart';
import '../../db/schemas/settings/settings.dart';
import '../../widgets/search_bar/search_launch_grid_data.dart';
import '../../widgets/skeletons/grid_skeleton_state.dart';
import '../../widgets/skeletons/grid_skeleton.dart';
import '../../widgets/notifiers/booru_api.dart';
import '../../widgets/notifiers/tag_manager.dart';
import '../../widgets/search_bar/search_launch_grid.dart';
import '../more/settings/settings_widget.dart';
import 'main_grid_settings_mixin.dart';

class SecondaryBooruGrid extends StatefulWidget {
  final StateRestoration restore;
  final Isar instance;
  final TagManager<Restorable> tagManager;
  final BooruAPIState api;

  final bool noRestoreOnBack;
  final SelectionGlue<J> Function<J extends Cell>()? generateGlue;

  const SecondaryBooruGrid({
    super.key,
    required this.restore,
    required this.instance,
    required this.api,
    required this.noRestoreOnBack,
    required this.tagManager,
    this.generateGlue,
  });

  @override
  State<SecondaryBooruGrid> createState() => _SecondaryBooruGridState();
}

class _SecondaryBooruGridState extends State<SecondaryBooruGrid>
    with SearchLaunchGrid<Post>, MainGridSettingsMixin {
  static const _log = LogTarget.booru;

  late final StreamSubscription<Settings?> settingsWatcher;
  late final StreamSubscription favoritesWatcher;

  int? currentSkipped;

  bool reachedEnd = false;
  bool addedToBookmarks = false;

  late final state = GridSkeletonState<Post>();

  @override
  void initState() {
    super.initState();

    gridSettingsHook();

    searchHook(SearchLaunchGridData(
      mainFocus: state.mainFocus,
      searchText: widget.restore.copy.tags,
      addItems: null,
      onSubmit: (context, tag) =>
          TagManagerNotifier.ofRestorable(context).onTagPressed(
        context,
        tag,
        BooruAPINotifier.of(context).booru,
        true,
        generateGlue: widget.generateGlue,
      ),
    ));

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

    widget.api.close();

    disposeGridSettings();
    disposeSearch();

    state.dispose();

    if (addedToBookmarks) {
      widget.instance.close(deleteFromDisk: false);
    } else {
      if (!isRestart) {
        widget.instance.close(deleteFromDisk: true);
        widget.restore.removeSelf();
      } else {
        widget.instance.close(deleteFromDisk: false);
      }
    }

    super.dispose();
  }

  Future<int> _clearAndRefresh() async {
    try {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        state.gridKey.currentState?.selection.reset();
      });
      StatisticsGeneral.addRefreshes();

      widget.instance.writeTxnSync(() => widget.instance.posts.clearSync());

      final list = await widget.api.page(
          0, widget.restore.copy.tags, widget.tagManager.excluded,
          overrideSafeMode: widget.restore.current.safeMode);
      widget.restore.updateScrollPosition(0, page: widget.api.currentPage);
      currentSkipped = list.$2;
      await widget.instance.writeTxn(() {
        widget.instance.posts.clear();
        return widget.instance.posts.putAllByFileUrl(list.$1);
      });

      reachedEnd = false;
    } catch (e) {
      rethrow;
    }

    return widget.instance.posts.count();
  }

  Future<void> _download(int i) async {
    final p = widget.instance.posts.getSync(i + 1);
    if (p == null) {
      return Future.value();
    }

    PostTags.g.addTagsPost(p.filename(), p.tags, true);

    return Downloader.g.add(
        DownloadFile.d(
            url: p.fileDownloadUrl(),
            site: widget.api.booru.url,
            name: p.filename(),
            thumbUrl: p.previewUrl),
        state.settings);
  }

  Future<int> _addLast() async {
    if (reachedEnd) {
      return widget.instance.posts.countSync();
    }
    final p = widget.instance.posts.getSync(widget.instance.posts.countSync());
    if (p == null) {
      return widget.instance.posts.countSync();
    }

    try {
      final list = await widget.api.fromPost(
          currentSkipped != null && currentSkipped! < p.id
              ? currentSkipped!
              : p.id,
          widget.restore.copy.tags,
          widget.tagManager.excluded,
          overrideSafeMode: widget.restore.current.safeMode);
      if (list.$1.isEmpty && currentSkipped == null) {
        reachedEnd = true;
      } else {
        currentSkipped = list.$2;

        if (!widget.instance.isOpen) {
          return 0;
        }

        final oldCount = widget.instance.posts.countSync();
        widget.instance.writeTxnSync(
            () => widget.instance.posts.putAllByFileUrlSync(list.$1));
        widget.restore.updateScrollPosition(
            widget.restore.current.scrollPositionGrid,
            page: widget.api.currentPage);
        if (widget.instance.posts.countSync() - oldCount < 3) {
          return await _addLast();
        }
      }
    } catch (e, trace) {
      _log.logDefaultImportant(
          "_addLast on grid ${state.settings.selectedBooru.string}"
              .errorMessage(e),
          trace);
    }

    return !widget.instance.isOpen
        ? Future.value(0)
        : widget.instance.posts.count();
  }

  void _restore(BuildContext context) {
    if (addedToBookmarks) {
      widget.restore.moveToBookmarks(widget.api.booru, widget.api.currentPage);
    }

    if (widget.noRestoreOnBack) {
      return;
    }

    final next = widget.restore.next();
    if (next != null) {
      final db = DbsOpen.secondaryGridName(next.copy.name);

      Navigator.of(context, rootNavigator: false).push(MaterialPageRoute(
        builder: (context) {
          return SecondaryBooruGrid(
            restore: next,
            noRestoreOnBack: false,
            api: BooruAPIState.fromEnum(widget.api.booru, page: next.copy.page),
            tagManager: widget.tagManager,
            instance: db,
          );
        },
      ));
    }
  }

  late SelectionGlue<Post>? glue = widget.generateGlue?.call();

  @override
  Widget build(BuildContext context) {
    return WrapGridPage<Post>(
      provided:
          widget.generateGlue == null ? null : (glue!, widget.generateGlue!),
      scaffoldKey: state.scaffoldKey,
      child: Builder(
        builder: (context) {
          final glue = GlueProvider.of<Post>(context);

          return BooruAPINotifier(
            api: widget.api,
            child: TagManagerNotifier.restorable(
                widget.tagManager,
                GridSkeleton(
                  state,
                  (context) => CallbackGrid<Post>(
                    key: state.gridKey,
                    selectionGlue: glue,
                    systemNavigationInsets: MediaQuery.of(context).viewPadding,
                    registerNotifiers: (child) => TagManagerNotifier.restorable(
                        widget.tagManager,
                        BooruAPINotifier(api: widget.api, child: child)),
                    menuButtonItems: [
                      AddToBookmarksButton(
                          state: state,
                          glue: glue,
                          f: () {
                            addedToBookmarks = true;
                          }),
                      gridButton(state.settings, gridSettings,
                          currentSafeMode: widget.restore.current.safeMode,
                          selectSafeMode: (safeMode) {
                        if (safeMode == null) {
                          return;
                        }

                        widget.restore.setSafeMode(safeMode);
                        setState(() {});
                      })
                    ],
                    addIconsImage: (post) => [
                      BooruGridActions.favorites(context, post),
                      BooruGridActions.download(context, widget.api)
                    ],
                    onExitImageView: () =>
                        widget.restore.removeScrollTagsSelectedPost(),
                    description: GridDescription(
                      [
                        BooruGridActions.download(context, widget.api),
                        BooruGridActions.favorites(context, null,
                            showDeleteSnackbar: true)
                      ],
                      keybindsDescription:
                          AppLocalizations.of(context)!.booruGridPageName,
                      layout: gridSettings.layoutType.layout(
                        gridSettings,
                        gridSeed: state.gridSeed,
                      ),
                    ),
                    inlineMenuButtonItems: true,
                    statistics: const ImageViewStatistics(
                        swiped: StatisticsBooru.addSwiped,
                        viewed: StatisticsBooru.addViewed),
                    hasReachedEnd: () => reachedEnd,
                    mainFocus: state.mainFocus,
                    scaffoldKey: state.scaffoldKey,
                    onError: (error) {
                      return OutlinedButton(
                        onPressed: () {
                          launchUrl(Uri.https(widget.api.booru.url),
                              mode: LaunchMode.externalApplication);
                        },
                        child:
                            Text(AppLocalizations.of(context)!.openInBrowser),
                      );
                    },
                    noteInterface: NoteBooru.interface(setState),
                    backButtonBadge: widget.restore.secondaryCount(),
                    getCell: (i) => widget.instance.posts.getSync(i + 1)!,
                    loadNext: _addLast,
                    refresh: _clearAndRefresh,
                    initalCellCount: widget.instance.posts.countSync(),
                    onBack: () {
                      Navigator.pop(context);
                      // _restore(context);
                    },
                    download: _download,
                    updateScrollPosition: (pos, {infoPos, selectedCell}) =>
                        widget.restore.updateScrollPosition(pos,
                            infoPos: infoPos,
                            selectedCell: selectedCell,
                            page: widget.api.currentPage),
                    initalScrollPosition:
                        widget.restore.copy.scrollPositionGrid,
                    searchWidget: SearchAndFocus(
                        searchWidget(context, hint: widget.api.booru.name),
                        searchFocus, onPressed: () {
                      if (currentlyHighlightedTag != "") {
                        state.mainFocus.unfocus();
                        widget.tagManager.onTagPressed(
                            context,
                            Tag.string(tag: currentlyHighlightedTag),
                            widget.api.booru,
                            true);
                      }
                    }),
                    pageViewScrollingOffset:
                        widget.restore.copy.scrollPositionTags,
                    initalCell: widget.restore.copy.selectedPost,
                  ),
                  overrideBooru: widget.api.booru,
                  canPop: !glue.isOpen(),
                  overrideOnPop: (pop, hideAppBar) {
                    if (glue.isOpen()) {
                      state.gridKey.currentState?.selection.reset();
                      return;
                    }

                    if (hideAppBar()) {
                      setState(() {});
                      return;
                    }

                    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
                      _restore(context);
                    });
                  },
                )),
          );
        },
      ),
    );
  }
}
