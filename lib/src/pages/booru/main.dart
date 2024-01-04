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
import 'package:gallery/src/db/schemas/booru/favorite_booru.dart';
import 'package:gallery/src/db/schemas/grid_state/grid_state_booru.dart';
import 'package:gallery/src/db/schemas/settings/hidden_booru_post.dart';
import 'package:gallery/src/db/schemas/booru/note_booru.dart';
import 'package:gallery/src/db/schemas/statistics/statistics_booru.dart';
import 'package:gallery/src/db/schemas/statistics/statistics_general.dart';
import 'package:gallery/src/db/schemas/tags/tags.dart';
import 'package:gallery/src/interfaces/booru/booru_api.dart';
import 'package:gallery/src/interfaces/refreshing_status_interface.dart';
import 'package:gallery/src/pages/booru/random.dart';
import 'package:gallery/src/pages/image_view.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';

import '../../widgets/grid/actions/booru_grid.dart';
import '../../net/downloader.dart';
import '../../db/tags/post_tags.dart';
import '../../db/initalize_db.dart';
import '../../db/state_restoration.dart';
import '../../db/schemas/downloader/download_file.dart';
import '../../db/schemas/booru/post.dart';
import '../../db/schemas/settings/settings.dart';
import '../../widgets/search_bar/search_launch_grid_data.dart';
import '../../widgets/skeletons/grid_skeleton_state.dart';
import '../../widgets/notifiers/booru_api.dart';
import '../../widgets/notifiers/tag_manager.dart';
import '../../widgets/search_bar/search_launch_grid.dart';

import '../../widgets/skeletons/grid_skeleton.dart';

import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/time_label.dart';
import 'grid_button.dart';
import 'main_grid_settings_mixin.dart';
import 'secondary.dart';

class MainBooruGrid extends StatefulWidget {
  final Isar mainGrid;
  final void Function(bool) procPop;
  final RefreshingStatusInterface refreshingInterface;

  const MainBooruGrid(
      {super.key,
      required this.mainGrid,
      required this.refreshingInterface,
      required this.procPop});

  @override
  State<MainBooruGrid> createState() => _MainBooruGridState();
}

class _MainBooruGridState extends State<MainBooruGrid>
    with SearchLaunchGrid<Post>, MainGridSettingsMixin {
  late final StreamSubscription<Settings?> settingsWatcher;
  late final StreamSubscription favoritesWatcher;
  late final StreamSubscription timeUpdater;
  // late final StreamSubscription ;
  bool inForeground = true;

  late final AppLifecycleListener lifecycleListener;

  late final BooruAPI api;
  late final StateRestoration restore;
  late final TagManager<Restorable> tagManager;

  int? currentSkipped;

  bool reachedEnd = false;

  final state = GridSkeletonState<Post>();

  @override
  void initState() {
    super.initState();

    gridSettingsHook();

    lifecycleListener = AppLifecycleListener(onHide: () {
      inForeground = false;
    }, onShow: () {
      inForeground = true;
    });

    timeUpdater = Stream.periodic(5.seconds).listen((event) {
      if (inForeground) {
        StatisticsGeneral.addTimeSpent(5.seconds.inMilliseconds);
      }
    });

    // main grid safe mode only from Settings
    restore = StateRestoration(widget.mainGrid,
        state.settings.selectedBooru.string, state.settings.safeMode);
    api = BooruAPI.fromSettings(page: restore.copy.page);

    tagManager = TagManager.restorable(restore, (fire, f) {
      return widget.mainGrid.tags
          .watchLazy(fireImmediately: fire)
          .listen((event) {
        f();
      });
    });

    searchHook(SearchLaunchGridData(
      mainFocus: state.mainFocus,
      searchText: "",
      addItems: null,
      onSubmit: (context, tag) => TagManagerNotifier.ofRestorable(context)
          .onTagPressed(context, tag, BooruAPINotifier.of(context).booru, true),
    ));

    if (api.wouldBecomeStale &&
        state.settings.autoRefresh &&
        state.settings.autoRefreshMicroseconds != 0 &&
        restore.copy.time.isBefore(DateTime.now()
            .subtract(state.settings.autoRefreshMicroseconds.microseconds))) {
      widget.mainGrid.writeTxnSync(() => widget.mainGrid.posts.clearSync());
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

    disposeGridSettings();
    disposeSearch();

    state.dispose();

    timeUpdater.cancel();

    lifecycleListener.dispose();

    super.dispose();
  }

  Future<int> _clearAndRefresh() async {
    try {
      widget.mainGrid.writeTxnSync(() => widget.mainGrid.posts.clearSync());

      StatisticsGeneral.addRefreshes();

      restore.updateTime();

      final list = await api.page(0, "", tagManager.excluded);
      restore.updateScrollPosition(0, page: api.currentPage);
      currentSkipped = list.$2;
      widget.mainGrid.writeTxnSync(() {
        widget.mainGrid.posts.clearSync();
        return widget.mainGrid.posts.putAllByFileUrlSync(list.$1
            .where(
                (element) => !HiddenBooruPost.isHidden(element.id, api.booru))
            .toList());
      });

      reachedEnd = false;
    } catch (e) {
      rethrow;
    }

    return widget.mainGrid.posts.count();
  }

  Future<void> _download(int i) async {
    final p = widget.mainGrid.posts.getSync(i + 1);
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
      return widget.mainGrid.posts.countSync();
    }
    final p = widget.mainGrid.posts.getSync(widget.mainGrid.posts.countSync());
    if (p == null) {
      return widget.mainGrid.posts.countSync();
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
        final oldCount = widget.mainGrid.posts.countSync();
        widget.mainGrid.writeTxnSync(() => widget.mainGrid.posts
            .putAllByFileUrlSync(list.$1
                .where((element) =>
                    !HiddenBooruPost.isHidden(element.id, api.booru))
                .toList()));
        restore.updateTime();
        if (widget.mainGrid.posts.countSync() - oldCount < 3) {
          return await _addLast();
        }
      }
    } catch (e, trace) {
      log("_addLast on grid ${state.settings.selectedBooru.string}",
          level: Level.WARNING.value, error: e, stackTrace: trace);
    }

    return widget.mainGrid.posts.count();
  }

  @override
  Widget build(BuildContext context) {
    final glue = GlueProvider.of<Post>(context);

    return BooruAPINotifier(
        api: api,
        child: TagManagerNotifier.restorable(
            tagManager,
            GridSkeleton(
              state,
              (context) => CallbackGrid<Post>(
                key: state.gridKey,
                systemNavigationInsets: EdgeInsets.only(
                    bottom: MediaQuery.of(context).systemGestureInsets.bottom +
                        (Scaffold.of(context).widget.bottomNavigationBar !=
                                    null &&
                                !glue.keyboardVisible()
                            ? 80
                            : 0)),
                selectionGlue: glue,
                registerNotifiers: (child) => TagManagerNotifier.restorable(
                    tagManager, BooruAPINotifier(api: api, child: child)),
                inlineMenuButtonItems: true,
                addFabPadding:
                    Scaffold.of(context).widget.bottomNavigationBar == null,
                menuButtonItems: [
                  const BookmarkButton(),
                  gridButton(state.settings, gridSettings)
                ],
                addIconsImage: (post) => [
                  BooruGridActions.favorites(context, post),
                  BooruGridActions.download(context, api),
                  BooruGridActions.hide(context, () {
                    setState(() {});

                    state.gridKey.currentState?.imageViewKey.currentState
                        ?.setState(() {});
                  }, post: post),
                ],
                statistics: const ImageViewStatistics(
                    swiped: StatisticsBooru.addSwiped,
                    viewed: StatisticsBooru.addViewed),
                onExitImageView: () => restore.removeScrollTagsSelectedPost(),
                description: GridDescription([
                  BooruGridActions.download(context, api),
                  BooruGridActions.favorites(context, null,
                      showDeleteSnackbar: true),
                  BooruGridActions.hide(context, () => setState(() {})),
                ],
                    keybindsDescription:
                        AppLocalizations.of(context)!.booruGridPageName,
                    layout: gridSettings.listView
                        ? const ListLayout()
                        : GridLayout(
                            gridSettings.columns, gridSettings.aspectRatio)),
                hasReachedEnd: () => reachedEnd,
                mainFocus: state.mainFocus,
                scaffoldKey: state.scaffoldKey,
                noteInterface: NoteBooru.interface(setState),
                onError: (error) {
                  return OutlinedButton(
                    onPressed: () {
                      launchUrl(Uri.https(api.booru.url),
                          mode: LaunchMode.externalApplication);
                    },
                    child: Text(AppLocalizations.of(context)!.openInBrowser),
                  );
                },
                getCell: (i) => widget.mainGrid.posts.getSync(i + 1)!,
                loadNext: _addLast,
                refresh: _clearAndRefresh,
                refreshInterface: widget.refreshingInterface,
                hideAlias: true,
                download: _download,
                updateScrollPosition: (pos, {infoPos, selectedCell}) =>
                    restore.updateScrollPosition(pos,
                        infoPos: infoPos,
                        selectedCell: selectedCell,
                        page: api.currentPage),
                initalScrollPosition: restore.copy.scrollPositionGrid,
                initalCellCount: widget.mainGrid.posts.countSync(),
                beforeImageViewRestore: () {
                  final last = restore.last();
                  if (last != null) {
                    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) {
                          return SecondaryBooruGrid(
                            restore: last,
                            noRestoreOnBack: false,
                            api: BooruAPI.fromEnum(api.booru,
                                page: last.copy.page),
                            tagManager: tagManager,
                            instance: DbsOpen.secondaryGridName(last.copy.name),
                          );
                        },
                      ));
                    });
                  }
                },
                searchWidget: SearchAndFocus(
                    searchWidget(context, hint: api.booru.name), searchFocus,
                    onPressed: () {
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
              canPop: true,
              overrideOnPop: (pop, hideAppBar) {
                if (hideAppBar()) {
                  setState(() {});
                  return;
                }

                widget.procPop(pop);
              },
            )));
  }
}

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
                          api: BooruAPI.fromEnum(e.booru, page: e.page),
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
