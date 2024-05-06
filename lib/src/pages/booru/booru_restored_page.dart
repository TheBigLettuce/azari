// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/base/post_base.dart";
import "package:gallery/src/db/services/impl/isar/foundation/initalize_db.dart";
import "package:gallery/src/db/services/impl/isar/schemas/booru/favorite_booru.dart";
import "package:gallery/src/db/services/impl/isar/schemas/booru/post.dart";
import "package:gallery/src/db/services/impl/isar/schemas/downloader/download_file.dart";
import "package:gallery/src/db/services/impl/isar/schemas/grid_settings/booru.dart";
import "package:gallery/src/db/services/impl/isar/schemas/grid_state/grid_booru_paging.dart";
import "package:gallery/src/db/services/impl/isar/schemas/grid_state/grid_state_booru.dart";
import "package:gallery/src/db/services/impl/isar/schemas/settings/hidden_booru_post.dart";
import "package:gallery/src/db/services/posts_source.dart";
import "package:gallery/src/db/services/settings.dart";
import "package:gallery/src/db/tags/booru_tagging.dart";
import "package:gallery/src/db/tags/post_tags.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/booru_api.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/net/download_manager/download_manager.dart";
import "package:gallery/src/pages/booru/booru_grid_actions.dart";
import "package:gallery/src/pages/booru/booru_page.dart";
import "package:gallery/src/pages/booru/booru_search_page.dart";
import "package:gallery/src/pages/home.dart";
import "package:gallery/src/pages/more/tags/tags_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_frame_settings_button.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_layout_behaviour.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_mutation_interface.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:gallery/src/widgets/notifiers/booru_api.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:gallery/src/widgets/notifiers/pause_video.dart";
import "package:gallery/src/widgets/search_bar/search_launch_grid.dart";
import "package:gallery/src/widgets/search_bar/search_launch_grid_data.dart";
import "package:gallery/src/widgets/skeletons/grid.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";
import "package:isar/isar.dart";
import "package:url_launcher/url_launcher.dart";

class BooruRestoredPage extends StatefulWidget {
  const BooruRestoredPage({
    super.key,
    required this.state,
    this.generateGlue,
    required this.pagingRegistry,
    this.overrideSafeMode,
    this.onDispose,
  });

  final GridStateBooru state;
  final PagingStateRegistry pagingRegistry;
  final SafeMode? overrideSafeMode;
  final void Function()? onDispose;
  final SelectionGlue Function([Set<GluePreferences>])? generateGlue;

  @override
  State<BooruRestoredPage> createState() => _BooruRestoredPageState();
}

class RestoredBooruPageState implements PagingEntry {
  RestoredBooruPageState(
    Booru booru,
    String name,
    String tags,
  )   : tagManager = TagManager.fromEnum(booru),
        instance = DbsOpen.secondaryGridName(name),
        client = BooruAPI.defaultClientForBooru(booru) {
    api = BooruAPI.fromEnum(booru, client, this);

    source = PostsSourceService.currentRestored(
      name,
      api,
      tagManager.excluded,
      this,
      initialTags: tags,
    );
  }

  final Dio client;
  final TagManager tagManager;
  late final BooruAPI api;
  late final PostsSourceService source;

  int? currentSkipped;

  @override
  bool reachedEnd = false;

  final Isar instance;

  late final state = GridSkeletonRefreshingState<Post>(
    initalCellCount: instance.postIsars.countSync(),
    reachedEnd: () => reachedEnd,
    clearRefresh: AsyncGridRefresh(source.clearRefresh),
    next: source.next,
  );

  @override
  void updateTime() {}

  @override
  void dispose() {
    client.close();

    state.dispose();

    instance.close();
  }

  @override
  double get offset {
    final o =
        Dbs.g.main.gridStateBoorus.getByNameSync(instance.name)!.scrollOffset;
    if (o.isNaN) {
      return 0;
    }

    return o;
  }

  @override
  int get page => instance.gridBooruPagings.getSync(0)?.page ?? 0;

  @override
  set page(int p) {
    instance.writeTxnSync(
      () => instance.gridBooruPagings.putSync(GridBooruPaging(p)),
    );
  }

  @override
  void setOffset(double o) {
    final prev = Dbs.g.main.gridStateBoorus.getByNameSync(instance.name)!;

    Dbs.g.main.writeTxnSync(
      () => Dbs.g.main.gridStateBoorus.putByNameSync(
        prev.copy(
          scrollOffset: o,
        ),
      ),
    );
  }
}

class _BooruRestoredPageState extends State<BooruRestoredPage> {
  late final StreamSubscription<SettingsData?> settingsWatcher;
  late final StreamSubscription<void> favoritesWatcher;
  late final StreamSubscription<void> blacklistedWatcher;

  late final SearchLaunchGrid search;

  late final RestoredBooruPageState pagingState;

  BooruAPI get api => pagingState.api;
  GridSkeletonRefreshingState<Post> get state => pagingState.state;
  TagManager get tagManager => pagingState.tagManager;
  Isar get instance => pagingState.instance;

  @override
  void initState() {
    super.initState();

    pagingState = widget.pagingRegistry.getOrRegister(widget.state.name, () {
      return RestoredBooruPageState(
        widget.state.booru,
        widget.state.name,
        widget.state.tags,
      );
    }) as RestoredBooruPageState;

    search = SearchLaunchGrid(
      SearchLaunchGridData(
        completeTag: api.completeTag,
        mainFocus: state.mainFocus,
        header: TagsWidget(
          tagging: tagManager.latest,
          onPress: (tag, safeMode) {},
        ),
        searchText: widget.state.tags,
        addItems: (_) => const [],
        disabled: true,
        onSubmit: (context, tag) {},
      ),
    );

    settingsWatcher = state.settings.s.watch((s) {
      state.settings = s!;

      setState(() {});
    });

    favoritesWatcher = Dbs.g.main.favoriteBoorus.watchLazy().listen((event) {
      state.refreshingStatus.mutation.notify();
      setState(() {});
    });

    blacklistedWatcher = HiddenBooruPost.watch((_) {
      state.refreshingStatus.mutation.notify();
    });
  }

  @override
  void dispose() {
    blacklistedWatcher.cancel();
    settingsWatcher.cancel();
    favoritesWatcher.cancel();

    widget.onDispose?.call();

    search.dispose();

    super.dispose();
  }

  SafeMode _safeMode() {
    final prev = Dbs.g.main.gridStateBoorus.getByNameSync(widget.state.name)!;

    return prev.safeMode;
  }

  Future<void> _download(int i) async {
    final p = instance.postIsars.getSync(i + 1);
    if (p == null) {
      return Future.value();
    }

    PostTags.g.addTagsPost(p.filename(), p.tags, true);

    return Downloader.g.add(
      DownloadFile.d(
        url: p.fileDownloadUrl(),
        site: api.booru.url,
        name: p.filename(),
        thumbUrl: p.previewUrl,
      ),
      state.settings,
    );
  }

  void _onTagPressed(
    BuildContext context,
    Booru booru,
    String tag,
    SafeMode? safeMode,
  ) {
    PauseVideoNotifier.maybePauseOf(context, true);

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) {
          return BooruSearchPage(
            booru: booru,
            tags: tag,
            wrapScaffold: true,
            overrideSafeMode: safeMode,
          );
        },
      ),
    ).then((value) => PauseVideoNotifier.maybePauseOf(context, false));
  }

  @override
  Widget build(BuildContext context) {
    return WrapGridPage(
      provided: widget.generateGlue,
      child: Builder(
        builder: (context) {
          return BooruAPINotifier(
            api: api,
            child: GridSkeleton(
              state,
              (context) => GridFrame<Post>(
                key: state.gridKey,
                layout: const GridSettingsLayoutBehaviour(
                  GridSettingsBooru.current,
                ),
                mainFocus: state.mainFocus,
                getCell: pagingState.source.forIdxUnsafe,
                initalScrollPosition: pagingState.offset,
                functionality: GridFunctionality(
                  watchLayoutSettings: GridSettingsBooru.watch,
                  updateScrollPosition: pagingState.setOffset,
                  onError: (error) {
                    return OutlinedButton.icon(
                      onPressed: () {
                        launchUrl(
                          Uri.https(api.booru.url),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      label: Text(AppLocalizations.of(context)!.openInBrowser),
                      icon: const Icon(Icons.public),
                    );
                  },
                  download: _download,
                  selectionGlue: GlueProvider.generateOf(context)(),
                  refreshingStatus: state.refreshingStatus,
                  search: OverrideGridSearchWidget(
                    SearchAndFocus(
                      search.searchWidget(context, hint: api.booru.name),
                      search.searchFocus,
                    ),
                  ),
                  registerNotifiers: (child) => OnBooruTagPressed(
                    onPressed: _onTagPressed,
                    child: BooruAPINotifier(api: api, child: child),
                  ),
                ),
                description: GridDescription(
                  actions: [
                    BooruGridActions.download(context, api.booru),
                    BooruGridActions.favorites(
                      context,
                      showDeleteSnackbar: true,
                    ),
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
                    selectSafeMode: (safeMode, _) {
                      if (safeMode == null) {
                        return;
                      }

                      final prev = Dbs.g.main.gridStateBoorus
                          .getByNameSync(widget.state.name)!;

                      Dbs.g.main.writeTxnSync(
                        () => Dbs.g.main.gridStateBoorus.putByNameSync(
                          prev.copy(safeMode: safeMode),
                        ),
                      );

                      setState(() {});
                    },
                  ),
                  inlineMenuButtonItems: true,
                  keybindsDescription:
                      AppLocalizations.of(context)!.booruGridPageName,
                  gridSeed: state.gridSeed,
                ),
              ),
              canPop: true,
            ),
          );
        },
      ),
    );
  }
}
