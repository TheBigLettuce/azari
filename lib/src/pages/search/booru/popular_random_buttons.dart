// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/pages/booru/actions.dart" as actions;
import "package:azari/src/pages/booru/booru_page.dart";
import "package:azari/src/pages/booru/booru_restored_page.dart";
import "package:azari/src/pages/gallery/directories.dart";
import "package:azari/src/pages/gallery/files.dart";
import "package:azari/src/pages/home/home.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/common_grid_data.dart";
import "package:azari/src/widgets/empty_widget.dart";
import "package:azari/src/widgets/grid_cell/cell.dart";
import "package:azari/src/widgets/scaffold_selection_bar.dart";
import "package:azari/src/widgets/selection_bar.dart";
import "package:azari/src/widgets/shell/configuration/grid_aspect_ratio.dart";
import "package:azari/src/widgets/shell/configuration/grid_column.dart";
import "package:azari/src/widgets/shell/configuration/shell_app_bar_type.dart";
import "package:azari/src/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";

class PopularRandomChips extends StatelessWidget {
  const PopularRandomChips({
    super.key,
    required this.listPadding,
    required this.state,
    required this.onPressed,
  });

  final EdgeInsets listPadding;

  final BooruChipsState state;
  final void Function(BooruChipsState state) onPressed;

  @override
  Widget build(BuildContext gridContext) {
    final l10n = AppLocalizations.of(gridContext)!;

    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        padding: listPadding,
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.min,
          children: [
            ChoiceChip(
              selected: state == BooruChipsState.latest,
              showCheckmark: false,
              onSelected: (_) => onPressed(BooruChipsState.latest),
              label: const Text("Latest"), // TODO: change
              avatar: const Icon(Icons.new_releases_outlined),
            ),
            const Padding(padding: EdgeInsets.only(right: 6)),
            ChoiceChip(
              selected: state == BooruChipsState.popular,
              showCheckmark: false,
              onSelected: (_) => onPressed(BooruChipsState.popular),
              label: Text(l10n.popularPosts),
              avatar: const Icon(Icons.whatshot_outlined),
            ),
            const Padding(padding: EdgeInsets.only(right: 6)),
            ChoiceChip(
              selected: state == BooruChipsState.random,
              showCheckmark: false,
              onSelected: (_) => onPressed(BooruChipsState.random),
              label: Text(l10n.randomPosts),
              avatar: const Icon(Icons.shuffle_outlined),
            ),
            const Padding(padding: EdgeInsets.only(right: 6)),
            ChoiceChip(
              selected: state == BooruChipsState.videos,
              showCheckmark: false,
              onSelected: (_) => onPressed(BooruChipsState.videos),
              label: Text(l10n.videosLabel),
              avatar: const Icon(Icons.video_collection_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

enum BooruChipsState {
  latest,
  popular,
  random,
  videos;
}

class _VideosSettingsDialog extends StatefulWidget {
  const _VideosSettingsDialog({
    // super.key,
    required this.booru,
    required this.settingsService,
  });

  final Booru booru;
  final SettingsService settingsService;

  @override
  State<_VideosSettingsDialog> createState() => __VideosSettingsDialogState();
}

class __VideosSettingsDialogState extends State<_VideosSettingsDialog>
    with SettingsWatcherMixin {
  @override
  SettingsService get settingsService => widget.settingsService;

  late final TextEditingController textController;
  final focus = FocusNode();

  late final client = BooruAPI.defaultClientForBooru(widget.booru);
  late final BooruAPI api;

  @override
  void initState() {
    super.initState();

    api = BooruAPI.fromEnum(widget.booru, client);

    textController = TextEditingController(text: settings.randomVideosAddTags);
  }

  @override
  void dispose() {
    focus.dispose();

    client.close(force: true);

    if (settings.randomVideosAddTags != textController.text) {
      settings.copy(randomVideosAddTags: textController.text).save();
    }

    textController.dispose();

    super.dispose();
  }

  (String, List<BooruTag>)? latestSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return AlertDialog(
      title: Text(l10n.settingsLabel),
      actions: [
        IconButton.filled(
          onPressed: () =>
              settings.copy(randomVideosOrder: RandomPostsOrder.random).save(),
          icon: const Icon(Icons.shuffle_rounded),
          isSelected: settings.randomVideosOrder == RandomPostsOrder.random,
        ),
        IconButton.filled(
          onPressed: () =>
              settings.copy(randomVideosOrder: RandomPostsOrder.rating).save(),
          icon: const Icon(Icons.whatshot_rounded),
          isSelected: settings.randomVideosOrder == RandomPostsOrder.rating,
        ),
        IconButton.filled(
          onPressed: () =>
              settings.copy(randomVideosOrder: RandomPostsOrder.latest).save(),
          icon: const Icon(Icons.schedule_rounded),
          isSelected: settings.randomVideosOrder == RandomPostsOrder.latest,
        ),
      ],
      content: Padding(
        padding: EdgeInsets.zero,
        child: SearchBarAutocompleteWrapper(
          search: SearchBarAppBarType(
            onChanged: null,
            complete: (str) async {
              if (str == latestSearch?.$1) {
                return latestSearch!.$2;
              }

              final res = await api.searchTag(str);

              latestSearch = (str, res);

              return res;
            },
            textEditingController: textController,
          ),
          searchFocus: focus,
          child: (context, controller, focus, onSelected) => TextField(
            decoration: InputDecoration(
              icon: const Icon(Icons.tag_outlined),
              suffix: IconButton(
                onPressed: () {
                  controller.clear();
                  focus.unfocus();
                },
                icon: const Icon(Icons.close_rounded),
              ),
              hintText: l10n.addTagsSearch,
              border: InputBorder.none,
            ),
            controller: controller,
            focusNode: focus,
          ),
        ),
      ),
    );
  }
}

class PopularPage extends StatefulWidget {
  const PopularPage({
    super.key,
    required this.api,
    required this.tags,
    required this.safeMode,
    required this.gridBookmarks,
    required this.hiddenBooruPosts,
    required this.favoritePosts,
    required this.tagManager,
    required this.settingsService,
    required this.downloadManager,
    required this.localTags,
    required this.selectionController,
  });

  final String tags;

  final BooruAPI api;
  final SelectionController selectionController;

  final SafeMode Function() safeMode;

  final GridBookmarkService? gridBookmarks;
  final HiddenBooruPostsService? hiddenBooruPosts;
  final FavoritePostSourceService? favoritePosts;
  final TagManagerService? tagManager;
  final DownloadManager? downloadManager;
  final LocalTagsService? localTags;

  final SettingsService settingsService;

  static Future<void> open(
    BuildContext context, {
    required String tags,
    required BooruAPI api,
    required SafeMode Function() safeMode,
  }) {
    final db = Services.of(context);

    return Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (context) => PopularPage(
          api: api,
          tags: tags,
          safeMode: safeMode,
          selectionController: SelectionActions.controllerOf(context),
          gridBookmarks: db.get<GridBookmarkService>(),
          hiddenBooruPosts: db.get<HiddenBooruPostsService>(),
          favoritePosts: db.get<FavoritePostSourceService>(),
          tagManager: db.get<TagManagerService>(),
          downloadManager: DownloadManager.of(context),
          localTags: db.get<LocalTagsService>(),
          settingsService: db.require<SettingsService>(),
        ),
      ),
    );
  }

  @override
  State<PopularPage> createState() => _PopularPageState();
}

class _PopularPageState extends State<PopularPage>
    with CommonGridData<PopularPage> {
  GridBookmarkService? get gridBookmarks => widget.gridBookmarks;
  HiddenBooruPostsService? get hiddenBooruPosts => widget.hiddenBooruPosts;
  FavoritePostSourceService? get favoritePosts => widget.favoritePosts;
  TagManagerService? get tagManager => widget.tagManager;
  DownloadManager? get downloadManager => widget.downloadManager;
  LocalTagsService? get localTags => widget.localTags;

  @override
  SettingsService get settingsService => widget.settingsService;

  final gridSettings = CancellableWatchableGridSettingsData.noPersist(
    hideName: true,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.two,
    layoutType: GridLayoutType.gridQuilted,
  );

  late final SourceShellElementState gridStatus;

  final pageSaver = PageSaver.noPersist();

  late final GenericListSource<Post> source = GenericListSource<Post>(
    () async {
      pageSaver.page = 0;

      final ret = await widget.api.page(
        pageSaver.page,
        widget.tags,
        tagManager?.excluded,
        widget.safeMode(),
        order: BooruPostsOrder.score,
        pageSaver: pageSaver,
      );

      return ret.$1;
    },
    next: () async {
      final ret = await widget.api.page(
        pageSaver.page + 1,
        widget.tags,
        tagManager?.excluded,
        widget.safeMode(),
        order: BooruPostsOrder.score,
        pageSaver: pageSaver,
      );

      return ret.$1;
    },
  );

  @override
  void initState() {
    super.initState();

    gridStatus = SourceShellElementState(
      source: source,
      selectionController: widget.selectionController,
      onEmpty: SourceOnEmptyInterface(
        source,
        (context) => context.l10n().emptyNoPosts,
      ),
      actions: <SelectionBarAction>[
        if (downloadManager != null && localTags != null)
          actions.downloadPost(
            context,
            widget.api.booru,
            null,
            downloadManager: downloadManager!,
            localTags: localTags!,
            settingsService: settingsService,
          ),
        if (favoritePosts != null)
          actions.favorites(
            context,
            favoritePosts!,
            showDeleteSnackbar: true,
          ),
        if (hiddenBooruPosts != null) actions.hide(context, hiddenBooruPosts!),
      ],
    );
  }

  @override
  void dispose() {
    gridSettings.cancel();
    source.destroy();
    gridStatus.destroy();

    super.dispose();
  }

  void _onBooruTagPressed(
    BuildContext _,
    Booru booru,
    String tag,
    SafeMode? safeMode,
  ) {
    BooruRestoredPage.open(
      context,
      booru: booru,
      tags: tag,
      overrideSafeMode: safeMode,
      rootNavigator: true,
      saveSelectedPage: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return ScaffoldSelectionBar(
      addScaffoldAndBar: true,
      child: GridPopScope(
        searchTextController: null,
        filter: null,
        child: ShellScope(
          stackInjector: gridStatus,
          configWatcher: gridSettings.watch,
          appBar: RawAppBarType(
            (context, settingsButton, bottomWidget) => SliverAppBar(
              floating: true,
              pinned: true,
              snap: true,
              stretch: true,
              bottom: bottomWidget ??
                  const PreferredSize(
                    preferredSize: Size.zero,
                    child: SizedBox.shrink(),
                  ),
              title: Text(
                widget.tags.isNotEmpty
                    ? "${l10n.popularPosts} #${widget.tags}"
                    : l10n.popularPosts,
              ),
              actions: [if (settingsButton != null) settingsButton],
            ),
          ),
          elements: [
            ElementPriority(
              BooruAPINotifier(
                api: widget.api,
                child: OnBooruTagPressed(
                  onPressed: (context, booru, value, safeMode) {
                    ExitOnPressRoute.maybeExitOf(context);

                    _onBooruTagPressed(context, booru, value, safeMode);
                  },
                  child: ShellElement(
                    // key: gridKey,
                    state: gridStatus,
                    animationsOnSourceWatch: false,
                    registerNotifiers: (child) => OnBooruTagPressed(
                      onPressed: (context, booru, value, safeMode) {
                        ExitOnPressRoute.maybeExitOf(context);

                        _onBooruTagPressed(context, booru, value, safeMode);
                      },
                      child: BooruAPINotifier(
                        api: widget.api,
                        child: child,
                      ),
                    ),
                    slivers: [
                      CurrentGridSettingsLayout<Post>(
                        source: source.backingStorage,
                        progress: source.progress,
                        gridSeed: gridSeed,
                        selection: ShellSelectionHolder.of(context),
                        // unselectOnUpdate: false,
                      ),
                      GridConfigPlaceholders(
                        progress: source.progress,
                        randomNumber: gridSeed,
                      ),
                      GridFooter<void>(storage: source.backingStorage),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PostsShellElement extends StatelessWidget {
  const PostsShellElement({
    super.key,
    required this.status,
    this.overrideSlivers,
    this.updateScrollPosition,
    this.initialScrollPosition = 0,
  });

  final List<Widget>? overrideSlivers;
  final SourceShellElementState<Post> status;
  final ScrollOffsetFn? updateScrollPosition;
  final double initialScrollPosition;

  @override
  Widget build(BuildContext context) {
    const gridSeed = 1;
    final navBarEvents = NavigationButtonEvents.maybeOf(context);

    return status.source.inject(
      ShellElement(
        animationsOnSourceWatch: false,
        state: status,
        scrollUpOn: navBarEvents != null ? [(navBarEvents, null)] : const [],
        updateScrollPosition: updateScrollPosition,
        initialScrollPosition: initialScrollPosition,
        scrollingState: ScrollingStateSinkProvider.maybeOf(context),
        slivers: overrideSlivers ??
            [
              Builder(
                builder: (context) {
                  final padding = MediaQuery.systemGestureInsetsOf(context);

                  return SliverPadding(
                    padding: EdgeInsets.only(
                      left: padding.left * 0.2,
                      right: padding.right * 0.2,
                    ),
                    sliver: CurrentGridSettingsLayout<Post>(
                      source: status.source.backingStorage,
                      progress: status.source.progress,
                      gridSeed: gridSeed,
                      selection: status.selection,
                      buildEmpty: (e) => EmptyWidget(
                        error: e.toString(),
                        gridSeed: gridSeed,
                        // buttonText: l10n.openInBrowser,
                        // onPressed: () {
                        //   url.launchUrl(
                        //     Uri.https(api.booru.url),
                        //     mode: url.LaunchMode.externalApplication,
                        //   );
                        // },
                      ),
                    ),
                  );
                },
              ),
              Builder(
                builder: (context) {
                  final padding = MediaQuery.systemGestureInsetsOf(context);

                  return SliverPadding(
                    padding: EdgeInsets.only(
                      left: padding.left * 0.2,
                      right: padding.right * 0.2,
                    ),
                    sliver: GridConfigPlaceholders(
                      progress: status.source.progress,
                      randomNumber: gridSeed,
                    ),
                  );
                },
              ),
              GridFooter<void>(storage: status.source.backingStorage),
            ],
      ),
    );
  }
}

class RandomPostsSliver extends StatelessWidget {
  const RandomPostsSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class _EmptyWidget extends StatefulWidget {
  const _EmptyWidget({
    // super.key,
    required this.progress,
  });

  final RefreshingProgress progress;

  @override
  State<_EmptyWidget> createState() => __EmptyWidgetState();
}

class __EmptyWidgetState extends State<_EmptyWidget> {
  late final StreamSubscription<void> subscr;

  @override
  void initState() {
    super.initState();

    subscr = widget.progress.watch(
      (t) {
        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    subscr.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    if (widget.progress.inRefreshing) {
      return const SizedBox.shrink();
    }

    return EmptyWidgetBackground(
      subtitle: l10n.emptyNoPosts,
    );
  }
}
