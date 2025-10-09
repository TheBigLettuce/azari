// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/logic/booru_page_mixin.dart";
import "package:azari/src/logic/cancellable_grid_settings_data.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/resource_source/basic.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/base/home.dart";
import "package:azari/src/ui/material/pages/gallery/directories.dart";
import "package:azari/src/ui/material/pages/gallery/files.dart";
import "package:azari/src/ui/material/pages/home/booru_page.dart";
import "package:azari/src/ui/material/pages/home/booru_restored_page.dart";
import "package:azari/src/ui/material/widgets/empty_widget.dart";
import "package:azari/src/ui/material/widgets/scaffold_selection_bar.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_aspect_ratio.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_column.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/shell_app_bar_type.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
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
              label: Text(l10n.latestLabel),
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

enum BooruChipsState { latest, popular, random, videos }

class PopularPage extends StatefulWidget {
  const PopularPage({
    super.key,
    required this.api,
    required this.tags,
    required this.safeMode,
  });

  final String tags;

  final BooruAPI api;

  final SafeMode Function() safeMode;

  static bool hasServicesRequired(Services db) => true;

  static Future<void> open(
    BuildContext context, {
    required String tags,
    required BooruAPI api,
    required SafeMode Function() safeMode,
  }) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (context) =>
            PopularPage(api: api, tags: tags, safeMode: safeMode),
      ),
    );
  }

  @override
  State<PopularPage> createState() => _PopularPageState();
}

class _PopularPageState extends State<PopularPage> with SettingsWatcherMixin {
  final gridSettings = CancellableGridSettingsData.noPersist(
    hideName: true,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.two,
    layoutType: GridLayoutType.gridQuilted,
  );

  late final SourceShellScopeElementState gridStatus;

  final selectionActions = SelectionActions();

  final pageSaver = PageSaver.noPersist();

  late final GenericListSource<Post> source = GenericListSource<Post>(
    () async {
      pageSaver.page = 0;

      final ret = await widget.api.page(
        pageSaver.page,
        widget.tags,
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

    gridStatus = SourceShellScopeElementState(
      source: source,
      gridSettings: gridSettings,
      selectionController: selectionActions.controller,
      onEmpty: SourceOnEmptyInterface(
        source,
        (context) => context.l10n().emptyNoPosts,
      ),
      actions: makePostActions(context, widget.api.booru),
    );
  }

  @override
  void dispose() {
    selectionActions.dispose();
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return ScaffoldWithSelectionBar(
      actions: selectionActions,
      child: GridPopScope(
        searchTextController: null,
        filter: null,
        child: ShellScope(
          stackInjector: gridStatus,
          appBar: RawAppBarType(
            (context, settingsButton, bottomWidget) => SliverAppBar(
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
                    gridSettings: gridSettings,
                    state: gridStatus,
                    animationsOnSourceWatch: false,
                    registerNotifiers: (child) => OnBooruTagPressed(
                      onPressed: (context, booru, value, safeMode) {
                        ExitOnPressRoute.maybeExitOf(context);

                        _onBooruTagPressed(context, booru, value, safeMode);
                      },
                      child: BooruAPINotifier(api: widget.api, child: child),
                    ),
                    slivers: [
                      CurrentGridSettingsLayout<Post>(
                        source: source.backingStorage,
                        progress: source.progress,
                        // gridSeed: gridSeed,
                        selection: ShellSelectionHolder.of(context),
                        // unselectOnUpdate: false,
                      ),
                      GridConfigPlaceholders(
                        progress: source.progress,
                        // randomNumber: gridSeed,
                      ),
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
    required this.gridSettings,
    this.overrideSlivers,
    this.updateScrollPosition,
    this.initialScrollPosition = 0,
  });

  final List<Widget>? overrideSlivers;
  final SourceShellElementState<Post> status;
  final ScrollOffsetFn? updateScrollPosition;
  final double initialScrollPosition;

  final GridSettingsData gridSettings;

  @override
  Widget build(BuildContext context) {
    const gridSeed = 1;
    final navBarEvents = NavigationButtonEvents.maybeOf(context);

    return status.source.inject(
      ShellElement(
        animationsOnSourceWatch: false,
        state: status,
        gridSettings: gridSettings,
        scrollUpOn: navBarEvents != null ? [(navBarEvents, null)] : const [],
        updateScrollPosition: updateScrollPosition,
        initialScrollPosition: initialScrollPosition,
        scrollingState: ScrollingStateSinkProvider.maybeOf(context),
        slivers:
            overrideSlivers ??
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
                      buildEmpty: (e) =>
                          EmptyWidget(error: e.toString(), gridSeed: gridSeed),
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

    subscr = widget.progress.watch((t) {
      setState(() {});
    });
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

    return EmptyWidgetBackground(subtitle: l10n.emptyNoPosts);
  }
}
