// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/db/schemas/grid_settings/booru.dart';
import 'package:gallery/src/db/schemas/grid_state/grid_state_booru.dart';
import 'package:gallery/src/db/tags/booru_tagging.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/interfaces/booru/booru_api.dart';
import 'package:gallery/src/interfaces/booru/safe_mode.dart';
import 'package:gallery/src/db/schemas/booru/favorite_booru.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart';
import 'package:gallery/src/interfaces/logging/logging.dart';
import 'package:gallery/src/pages/booru/add_to_bookmarks_button.dart';
import 'package:gallery/src/pages/more/tags/tags_widget.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_layout_behaviour.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/image_view_description.dart';
import 'package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/search_bar/search_launch_grid.dart';
import 'package:gallery/src/widgets/search_bar/search_launch_grid_data.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

import '../../db/schemas/statistics/statistics_booru.dart';
import '../../db/schemas/statistics/statistics_general.dart';
import 'booru_grid_actions.dart';
import '../../net/downloader.dart';
import '../../db/tags/post_tags.dart';
import '../../db/initalize_db.dart';
import '../../db/schemas/downloader/download_file.dart';
import '../../db/schemas/booru/post.dart';
import '../../db/schemas/settings/settings.dart';
import '../../widgets/skeletons/grid.dart';
import '../../widgets/notifiers/booru_api.dart';
import '../../widgets/grid_frame/grid_frame.dart';
import '../../widgets/image_view/image_view.dart';
import '../../widgets/grid_frame/configuration/grid_frame_settings_button.dart';

class BooruSearchPage extends StatefulWidget {
  final Booru booru;
  final String tags;
  final SafeMode? overrideSafeMode;
  final SelectionGlue<J> Function<J extends Cell>()? generateGlue;

  const BooruSearchPage({
    super.key,
    required this.booru,
    required this.tags,
    this.generateGlue,
    this.overrideSafeMode,
  });

  @override
  State<BooruSearchPage> createState() => _BooruSearchPageState();
}

class _BooruSearchPageState extends State<BooruSearchPage> {
  static const _log = LogTarget.booru;

  late final StreamSubscription<Settings?> settingsWatcher;
  late final StreamSubscription favoritesWatcher;
  late final Dio client = BooruAPI.defaultClientForBooru(widget.booru);
  late final tagManager = TagManager.fromEnum(widget.booru);
  late final BooruAPI api;

  late final SearchLaunchGrid search;

  double? _currentScroll;

  SafeMode? safeMode;

  late String tags = widget.tags;

  int? currentSkipped;

  bool reachedEnd = false;
  bool addedToBookmarks = false;

  late final Isar instance = DbsOpen.secondaryGrid(temporary: true);

  late final state = GridSkeletonState<Post>(
    reachedEnd: () => reachedEnd,
  );

  @override
  void initState() {
    super.initState();

    api = BooruAPI.fromEnum(widget.booru, client, const EmptyPageSaver());

    safeMode = widget.overrideSafeMode;

    search = SearchLaunchGrid(SearchLaunchGridData(
      completeTag: api.completeTag,
      mainFocus: state.mainFocus,
      header: TagsWidget(
        tagging: tagManager.latest,
        onPress: (tag, safeMode) => _clearAndRefreshB(tag.tag),
      ),
      searchText: widget.tags,
      addItems: (_) => const [],
      onSubmit: (context, tag) {
        _clearAndRefreshB(tag);
        // }
      },
    ));

    settingsWatcher = Settings.watch((s) {
      state.settings = s!;

      setState(() {});
    });

    favoritesWatcher = Dbs.g.main.favoriteBoorus
        .watchLazy(fireImmediately: false)
        .listen((event) {
      state.imageViewKey.currentState?.setState(() {});
      setState(() {});
    });
  }

  @override
  void dispose() {
    settingsWatcher.cancel();
    favoritesWatcher.cancel();

    client.close();
    search.dispose();

    state.dispose();

    if (addedToBookmarks) {
      instance.close(deleteFromDisk: false);
      final f = File.fromUri(Uri.file(
          path.joinAll([Dbs.g.temporaryDbDir, "${instance.name}.isar"])));
      f.renameSync(
          path.joinAll([Dbs.g.appStorageDir, "${instance.name}.isar"]));
      Dbs.g.main.writeTxnSync(() => Dbs.g.main.gridStateBoorus.putSync(
            GridStateBooru(api.booru,
                tags: tags,
                scrollOffset: _currentScroll ?? 0,
                safeMode: safeMode ?? state.settings.safeMode,
                name: instance.name,
                time: DateTime.now()),
          ));
    } else {
      instance.close(deleteFromDisk: true);
    }

    super.dispose();
  }

  SafeMode _safeMode() {
    return safeMode ?? state.settings.safeMode;
  }

  void _clearAndRefreshB(String tag) {
    final mutation = state.refreshingStatus.mutation;

    mutation.cellCount = 0;
    mutation.isRefreshing = true;

    setState(() {
      tags = tag;
    });

    _clearAndRefresh().whenComplete(() {
      mutation.cellCount = instance.posts.countSync();
      mutation.isRefreshing = false;
    });
  }

  Future<int> _clearAndRefresh() async {
    try {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        state.gridKey.currentState?.selection.reset();
      });
      StatisticsGeneral.addRefreshes();

      instance.writeTxnSync(() => instance.posts.clearSync());

      final list = await api.page(0, tags, tagManager.excluded,
          overrideSafeMode: _safeMode());
      currentSkipped = list.$2;
      await instance.writeTxn(() {
        instance.posts.clear();
        return instance.posts.putAllByFileUrl(list.$1);
      });

      reachedEnd = false;
    } catch (e) {
      rethrow;
    }

    return instance.posts.count();
  }

  Future<void> _download(int i) async {
    final p = instance.posts.getSync(i + 1);
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
      return instance.posts.countSync();
    }
    final p = instance.posts.getSync(instance.posts.countSync());
    if (p == null) {
      return instance.posts.countSync();
    }

    try {
      final list = await api.fromPost(
          currentSkipped != null && currentSkipped! < p.id
              ? currentSkipped!
              : p.id,
          tags,
          tagManager.excluded,
          overrideSafeMode: _safeMode());
      if (list.$1.isEmpty && currentSkipped == null) {
        reachedEnd = true;
      } else {
        currentSkipped = list.$2;
        final oldCount = instance.posts.countSync();
        instance
            .writeTxnSync(() => instance.posts.putAllByFileUrlSync(list.$1));

        if (instance.posts.countSync() - oldCount < 3) {
          return await _addLast();
        }
      }
    } catch (e, trace) {
      _log.logDefaultImportant(
          "_addLast on grid ${state.settings.selectedBooru.string}"
              .errorMessage(e),
          trace);
    }

    return instance.posts.count();
  }

  @override
  Widget build(BuildContext context) {
    return WrapGridPage<Post>(
      provided: widget.generateGlue,
      scaffoldKey: state.scaffoldKey,
      child: Builder(
        builder: (context) {
          final glue = GlueProvider.of<Post>(context);

          return BooruAPINotifier(
            api: api,
            child: GridSkeleton(
              state,
              (context) => GridFrame<Post>(
                key: state.gridKey,
                refreshingStatus: state.refreshingStatus,
                layout: const GridSettingsLayoutBehaviour(
                    GridSettingsBooru.current),
                mainFocus: state.mainFocus,
                getCell: (i) => instance.posts.getSync(i + 1)!,
                imageViewDescription: ImageViewDescription(
                  addIconsImage: (post) => [
                    BooruGridActions.favorites(context, post),
                    BooruGridActions.download(context, api.booru)
                  ],
                  imageViewKey: state.imageViewKey,
                  statistics: const ImageViewStatistics(
                    swiped: StatisticsBooru.addSwiped,
                    viewed: StatisticsBooru.addViewed,
                  ),
                ),
                functionality: GridFunctionality(
                  watchLayoutSettings: GridSettingsBooru.watch,
                  updateScrollPosition: (pos) {
                    _currentScroll = pos;
                  },
                  onError: (error) {
                    return OutlinedButton(
                      onPressed: () {
                        launchUrl(Uri.https(api.booru.url),
                            mode: LaunchMode.externalApplication);
                      },
                      child: Text(AppLocalizations.of(context)!.openInBrowser),
                    );
                  },
                  download: _download,
                  selectionGlue: glue,
                  search: OverrideGridSearchWidget(
                    SearchAndFocus(
                        search.searchWidget(context, hint: api.booru.name),
                        search.searchFocus),
                  ),
                  loadNext: _addLast,
                  refresh: AsyncGridRefresh(_clearAndRefresh),
                  registerNotifiers: (child) =>
                      BooruAPINotifier(api: api, child: child),
                ),
                systemNavigationInsets: MediaQuery.of(context).viewPadding,
                description: GridDescription(
                  actions: [
                    BooruGridActions.download(context, api.booru),
                    BooruGridActions.favorites(context, null,
                        showDeleteSnackbar: true)
                  ],
                  menuButtonItems: [
                    AddToBookmarksButton(
                        state: state,
                        f: () {
                          if (tags.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      "Search text is empty")), // TODO: change
                            );

                            return false;
                          }
                          addedToBookmarks = true;

                          return true;
                        }),
                  ],
                  settingsButton: GridFrameSettingsButton(
                      selectGridColumn: (columns, settings) =>
                          (settings as GridSettingsBooru)
                              .copy(columns: columns)
                              .save(),
                      selectGridLayout: (layoutType, settings) =>
                          (settings as GridSettingsBooru)
                              .copy(layoutType: layoutType)
                              .save(),
                      selectRatio: (ratio, settings) =>
                          (settings as GridSettingsBooru)
                              .copy(aspectRatio: ratio)
                              .save(),
                      safeMode: _safeMode(),
                      selectSafeMode: (s, _) {
                        setState(() {
                          safeMode = s;
                        });
                      }),
                  inlineMenuButtonItems: true,
                  keybindsDescription:
                      AppLocalizations.of(context)!.booruGridPageName,
                  gridSeed: state.gridSeed,
                ),
              ),
              canPop: true,
              overrideOnPop: (pop, hideAppBar) {
                if (hideAppBar()) {
                  setState(() {});
                  return;
                }
              },
            ),
          );
        },
      ),
    );
  }
}
