// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/init_main/build_theme.dart";
import "package:azari/src/init_main/restart_widget.dart";
import "package:azari/src/logic/local_tags_helper.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/resource_source/filtering_mode.dart";
import "package:azari/src/logic/resource_source/source_storage.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/booru/bookmark_page.dart";
import "package:azari/src/ui/material/pages/booru/booru_page.dart";
import "package:azari/src/ui/material/pages/booru/booru_restored_page.dart";
import "package:azari/src/ui/material/pages/booru/downloads.dart";
import "package:azari/src/ui/material/pages/booru/favorite_posts_page.dart";
import "package:azari/src/ui/material/pages/booru/hidden_posts.dart";
import "package:azari/src/ui/material/pages/booru/visited_posts.dart";
import "package:azari/src/ui/material/pages/discover/discover.dart";
import "package:azari/src/ui/material/pages/gallery/blacklisted_directories.dart";
import "package:azari/src/ui/material/pages/gallery/directories.dart";
import "package:azari/src/ui/material/pages/gallery/files.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/pages/home/home_skeleton.dart";
import "package:azari/src/ui/material/pages/other/settings/settings_page.dart";
import "package:azari/src/ui/material/pages/search/booru/booru_search_page.dart";
import "package:azari/src/ui/material/pages/search/gallery/gallery_search_page.dart";
import "package:azari/src/ui/material/widgets/autocomplete_widget.dart";
import "package:azari/src/ui/material/widgets/gesture_dead_zones.dart";
import "package:azari/src/ui/material/widgets/grid_cell/cell.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view.dart";
import "package:azari/src/ui/material/widgets/post_cell.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/translation_notes.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:go_router/go_router.dart";

class AppMaterial extends StatefulWidget {
  const AppMaterial({super.key});

  @override
  State<AppMaterial> createState() => _AppMaterialState();
}

class _AppMaterialState extends State<AppMaterial> {
  final navigatorKey = GlobalKey<NavigatorState>();

  final selectionEvents = SelectionActions();

  late final router = makeRoutes(navigatorKey);

  @override
  void dispose() {
    selectionEvents.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const AppApi().accentColor;

    final d = buildTheme(Brightness.dark, accentColor);
    final l = buildTheme(Brightness.light, accentColor);

    final spaces = Spaces();

    return AlertServiceUI(
      navigatorKey: navigatorKey,
      child: spaces.inject(
        selectionEvents.inject(
          TimeTickerStatistics(
            child: MaterialApp.router(
              routerConfig: router,
              color: accentColor,
              themeAnimationCurve: Easing.standard,
              themeAnimationDuration: const Duration(milliseconds: 300),
              darkTheme: d,
              theme: l,
              debugShowCheckedModeBanner: false,
              onGenerateTitle: (context) => "Azari",
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        ),
      ),
    );
  }
}

class LabeledlDialog<T extends CellBuilder> extends StatefulWidget {
  const LabeledlDialog({
    super.key,
    required this.name,
    required this.storage,
    required this.onPressed,
    this.actions = const [],
  });

  final String name;
  final ReadOnlyStorage<int, T> storage;
  final List<Widget> actions;

  final void Function(T) onPressed;

  @override
  State<LabeledlDialog<T>> createState() => _LabeledlDialogState();
}

class _LabeledlDialogState<T extends CellBuilder>
    extends State<LabeledlDialog<T>> {
  late final StreamSubscription<int> events;

  @override
  void initState() {
    super.initState();

    events = widget.storage.watch((newCount) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    events.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    color: theme.colorScheme.surfaceContainerLow,
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      widget.name,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                ),
                IconButtonTheme(
                  data: IconButtonThemeData(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                          theme.colorScheme.surfaceContainerLow),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: widget.actions + widget.actions,
                  ),
                ),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.only(top: 20)),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 320,
                  maxWidth: 480,
                ),
                child: AnimatedCrossFade(
                  firstChild: Center(
                    child: Text(
                      "No elements",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  duration: Durations.long1,
                  reverseDuration: Durations.medium1,
                  firstCurve: Easing.standard,
                  secondChild: widget.storage.isEmpty
                      ? const SizedBox.shrink()
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                          ),
                          itemCount: widget.storage.count,
                          itemBuilder: (context, index) {
                            final cell = widget.storage[index];

                            return Material(
                              type: MaterialType.transparency,
                              child: InkWell(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(18)),
                                onTap: () => widget.onPressed(cell),
                                child: cell.buildCell(
                                  l10n,
                                  cellType: CellType.cellStatic,
                                  hideName: false,
                                ),
                              ),
                            );
                          },
                        ),
                  crossFadeState: widget.storage.isNotEmpty
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

GoRouter makeRoutes(GlobalKey<NavigatorState> key) {
  return GoRouter(
    navigatorKey: key,
    initialLocation: "/home",
    routes: [
      StatefulShellRoute.indexedStack(
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: "/home",
                name: "Home",
                builder: (context, state) {
                  return BooruPage(
                    pagingRegistry: PagingStateRegistry.of(context),
                    selectionController: SelectionActions.controllerOf(context),
                  );
                },
                routes: [
                  GoRoute(
                    path: "tags",
                    name: "BooruTagsSearch",
                    builder: (context, state) {
                      final data = state.extra! as BooruRestoredPageData;
                      final parameters = state.uri.queryParameters;
                      final String? name = parameters["name"];
                      // final bool wrapScaffold =
                      //     parameters["addScaffold"] == "1";
                      final bool bookmarksByTags =
                          parameters["bookmarksByTags"] == "1";
                      final String tags = parameters["tags"] ?? "";

                      return BooruRestoredPage(
                        data: data,
                        name: name,
                        tags: tags,
                        // wrapScaffold: wrapScaffold,
                        trySearchBookmarkByTags: bookmarksByTags,
                        selectionController:
                            SelectionActions.controllerOf(context),
                      );
                    },
                  ),
                  GoRoute(
                    path: "search",
                    name: "BooruSearch",
                    builder: (context, state) => const BooruSearchPage(),
                    routes: [
                      GoRoute(
                        path: "pinTagDialog",
                        name: "PinTagDialog",
                        pageBuilder: (context, state) {
                          final api = state.extra! as BooruAPI;

                          return _PinTagDialogPage(api);
                        },
                      ),
                      GoRoute(
                        path: "removePinnedTagDialog",
                        name: "RemovePinnedTagDialog",
                        pageBuilder: (context, state) {
                          final str = state.extra! as String;

                          return _RemovePinnedTagDialogPage(str);
                        },
                      ),
                      GoRoute(
                        path: "excludeTagDialog",
                        name: "ExcludeTagDialog",
                        pageBuilder: (context, state) {
                          final api = state.extra! as BooruAPI;

                          return _ExcludeTagDialogPage(api);
                        },
                      ),
                      GoRoute(
                        path: "removeExcludedTagDialog",
                        name: "RemoveExcludedTagDialog",
                        pageBuilder: (context, state) {
                          final str = state.extra! as String;

                          return _RemoveTagDialogPage(str);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: "/favorites",
                builder: (context, state) => FavoritePostsPage(
                  selectionController: SelectionActions.controllerOf(context),
                ),
              ),
              GoRoute(
                path: "/bookmarks",
                builder: (context, state) => BookmarkPage(
                  pagingRegistry: PagingStateRegistry.of(context),
                  saveSelectedPage: (_) {},
                  selectionController: SelectionActions.controllerOf(context),
                ),
              ),
              GoRoute(
                path: "/hiddenPosts",
                builder: (context, state) => HiddenPostsPage(
                  selectionController: SelectionActions.controllerOf(context),
                ),
              ),
              GoRoute(
                path: "/downloads",
                builder: (context, state) => DownloadsPage(
                  selectionController: SelectionActions.controllerOf(context),
                ),
              ),
              GoRoute(
                path: "/visited",
                builder: (context, state) => VisitedPostsPage(
                  selectionController: SelectionActions.controllerOf(context),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: "/more",
                builder: (context, state) => const DiscoverPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: "/gallery",
                name: "Directories",
                builder: (context, state) {
                  return DirectoriesPage(
                    selectionController: SelectionActions.controllerOf(context),
                  );
                },
                routes: [
                  GoRoute(
                    path: "search",
                    name: "GallerySearch",
                    builder: (context, state) => const GallerySearchPage(),
                  ),
                  GoRoute(
                    path: "files",
                    name: "Files",
                    onExit: (context, state) {
                      Spaces().get<Directories>().bindFiles?.close();
                      return true;
                    },
                    builder: (context, state) {
                      final parameters = state.uri.queryParameters;
                      final bool? secure = parameters.containsKey("secure")
                          ? parameters["secure"]! != "0"
                          : null;
                      final presetFilterValue = parameters["filterValue"] ?? "";
                      // final addScaffold = parameters["addScaffold"] == "1";

                      return FilesPage(
                        secure: secure ?? false,
                        presetFilteringValue: presetFilterValue,
                        navBarEvents: NavigationButtonEvents.maybeOf(context),
                        scrollingState:
                            ScrollingStateSinkProvider.maybeOf(context),
                        selectionController:
                            SelectionActions.controllerOf(context),
                      );
                    },
                    routes: [
                      GoRoute(
                        path: "imageView",
                        name: "FilesImageView",
                        builder: (context, state) {
                          final query = state.uri.queryParameters;
                          final int startingIndex = query.containsKey("index")
                              ? int.tryParse(query["index"]!) ?? 0
                              : 0;

                          return ImageView(
                            stateController: Spaces()
                                .get<Directories>()
                                .bindFiles!
                                .stateController,
                            startingIndex: startingIndex,
                            returnBack: () => FilesPage.open(context),
                          );
                        },
                      ),
                      GoRoute(
                        path: "emptyTrashDialog",
                        name: "EmptyTrashDialog",
                        pageBuilder: (context, state) {
                          final l10n = context.l10n();

                          return MaterialPage(
                            fullscreenDialog: true,
                            child: AlertDialog(
                              title: Text(l10n.emptyTrashTitle),
                              content: Text(
                                l10n.thisIsPermanent,
                                style: const TextStyle(color: Colors.red),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    const GalleryService().trash.empty();
                                    DirectoriesPage.open(context);
                                  },
                                  child: Text(l10n.yes),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      DirectoriesPage.open(context),
                                  child: Text(l10n.no),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      GoRoute(
                        path: "deleteFilesDialog",
                        name: "DeleteFilesDialog",
                        pageBuilder: (context, state) {
                          final (selected, toShow) =
                              state.extra! as (List<File>, DeleteDialogShow);

                          void delete() {
                            const GalleryService().trash.addAll(
                                  selected.map((e) => e.originalUri).toList(),
                                );

                            StatisticsGalleryService.addDeleted(
                                selected.length);
                          }

                          final l10n = context.l10n();

                          final text = selected.length == 1
                              ? "${l10n.tagDeleteDialogTitle} ${selected.first.name}"
                              : "${l10n.tagDeleteDialogTitle}"
                                  " ${selected.length}"
                                  " ${l10n.elementPlural}";

                          return MaterialPage(
                            fullscreenDialog: true,
                            child: AlertDialog(
                              title: Text(text),
                              content: Text(l10n.youCanRestoreFromTrash),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    delete();
                                    toShow.show = false;
                                    context.goNamed("Files");
                                  },
                                  child: Text(l10n.yesHide),
                                ),
                                TextButton(
                                  onPressed: () {
                                    delete();
                                    context.goNamed("Files");
                                  },
                                  child: Text(l10n.yes),
                                ),
                                TextButton(
                                  onPressed: () => context.goNamed("Files"),
                                  child: Text(l10n.no),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: "blacklisted",
                    name: "BlacklistedDirectories",
                    builder: (context, state) => BlacklistedDirectoriesPage(
                      selectionController:
                          SelectionActions.controllerOf(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
        builder: (context, state, navigationShell) =>
            _Skeleton(state: state, child: navigationShell),
      ),
      GoRoute(
        path: "/settings",
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: "/addTagsDialog",
        name: "AddTagDialog",
        pageBuilder: (context, state) {
          return MaterialPage(
            fullscreenDialog: true,
            child: AddTagDialog(
                onSubmit: state.extra! as void Function(String, bool)),
          );
        },
      ),
      GoRoute(
        path: "/postImageAsync",
        name: "PostImageAsync",
        pageBuilder: (context, state) {
          final data = state.extra! as CardDialogStaticData;

          return _CardDialogAsyncPage(data);
        },
      ),
      GoRoute(
        path: "/postImage",
        name: "PostImage",
        pageBuilder: (context, state) {
          final data = state.extra! as CardDialogData;

          return _CardDialogPage(data);
        },
      ),
      GoRoute(
        path: "/licensePage",
        name: "LicensePage",
        builder: (context, state) => const LicensePage(),
      ),
      GoRoute(
        path: "/colorChangeDialog",
        name: "ColorChangeDialog",
        pageBuilder: (context, state) {
          final l10n = context.l10n();
          final colorsNames = const ColorsNamesService().current;
          final e = state.extra! as FilteringColors;

          return MaterialPage(
            fullscreenDialog: true,
            child: AlertDialog(
              title: Text(
                "Change ${e.translatedString(l10n, colorsNames)} to",
              ),
              content: TextField(
                onSubmitted: (value) {
                  switch (e) {
                    case FilteringColors.red:
                      colorsNames.copy(red: value).maybeSave();
                    case FilteringColors.blue:
                      colorsNames.copy(blue: value).maybeSave();
                    case FilteringColors.yellow:
                      colorsNames.copy(yellow: value).maybeSave();
                    case FilteringColors.green:
                      colorsNames.copy(green: value).maybeSave();
                    case FilteringColors.purple:
                      colorsNames.copy(purple: value).maybeSave();
                    case FilteringColors.orange:
                      colorsNames.copy(orange: value).maybeSave();
                    case FilteringColors.pink:
                      colorsNames.copy(pink: value).maybeSave();
                    case FilteringColors.white:
                      colorsNames.copy(white: value).maybeSave();
                    case FilteringColors.brown:
                      colorsNames.copy(brown: value).maybeSave();
                    case FilteringColors.black:
                      colorsNames.copy(black: value).maybeSave();
                    case FilteringColors.noColor:
                  }

                  context.pop();
                },
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: "/translationNotes",
        name: "TranslationNotes",
        pageBuilder: (context, state) {
          final (postId, booru) = state.extra! as (int, Booru);

          return MaterialPage(
            child: TranslationNotes(
              postId: postId,
              booru: booru,
            ),
          );
        },
      ),
      GoRoute(
        path: "/deleteBookmark",
        name: "DeleteBookmark",
        pageBuilder: (context, state) {
          final l10n = context.l10n();
          final data = state.error! as DeleteBookmarkData;

          return MaterialPage(
            child: AlertDialog(
              title: Text(l10n.delete),
              content: ListTile(
                title: Text(data.state.tags),
                subtitle: Text(data.state.time.toString()),
              ),
              actions: [
                TextButton(
                  onPressed: data.gridDbs != null
                      ? () {
                          data.gridDbs!
                              .openSecondary(
                                data.state.booru,
                                data.state.name,
                                null,
                              )
                              .destroy()
                              .then(
                            (value) {
                              if (context.mounted) {
                                context.pop();
                              }

                              data.gridBookmarks.delete(data.state.name);
                            },
                          );
                        }
                      : null,
                  child: Text(l10n.yes),
                ),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(l10n.no),
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}

class _RemovePinnedTagDialogPage extends Page<void> {
  const _RemovePinnedTagDialogPage(this.str);

  final String str;

  @override
  Route<void> createRoute(BuildContext context) {
    return DialogRoute<void>(
      context: context,
      settings: this,
      builder: (context) {
        final l10n = context.l10n();

        return AlertDialog(
          title: Text(l10n.removeTag(str)),
          actions: [
            TextButton(
              onPressed: () {
                const TagManagerService().pinned.delete(str);
                BooruSearchPage.open(context);
              },
              child: Text(l10n.yes),
            ),
            TextButton(
              onPressed: () => BooruSearchPage.open(context),
              child: Text(l10n.no),
            ),
          ],
        );
      },
    );
  }
}

class _PinTagDialogPage extends Page<void> {
  const _PinTagDialogPage(this.api);

  final BooruAPI api;

  @override
  Route<void> createRoute(BuildContext context) {
    return DialogRoute(
      context: context,
      settings: this,
      builder: (context) {
        final l10n = context.l10n();

        return AlertDialog(
          title: Text(l10n.pinTag),
          content: AutocompleteWidget(
            null,
            (s) {},
            swapSearchIcon: false,
            (s) {
              const TagManagerService().pinned.add(s.trim());

              BooruSearchPage.open(context);
            },
            () {},
            api.searchTag,
            null,
            submitOnPress: true,
            roundBorders: true,
            plainSearchBar: true,
            showSearch: true,
          ),
        );
      },
    );
  }
}

class _ExcludeTagDialogPage extends Page<void> {
  const _ExcludeTagDialogPage(this.api);

  final BooruAPI api;

  @override
  Route<void> createRoute(BuildContext context) {
    // final theme = Theme.of(context);
    final l10n = context.l10n();

    return DialogRoute(
      context: context,
      settings: this,
      builder: (context) => AlertDialog(
        title: Text(l10n.addToExcluded),
        content: AutocompleteWidget(
          null,
          (s) {},
          swapSearchIcon: false,
          (s) {
            const TagManagerService().excluded.add(s.trim());

            BooruSearchPage.open(context);
          },
          () {},
          api.searchTag,
          null,
          submitOnPress: true,
          roundBorders: true,
          plainSearchBar: true,
          showSearch: true,
        ),
      ),
    );
  }
}

class _RemoveTagDialogPage extends Page<void> {
  const _RemoveTagDialogPage(this.str);

  final String str;

  @override
  Route<void> createRoute(BuildContext context) {
    // final theme = Theme.of(context);
    final l10n = context.l10n();

    return DialogRoute(
      context: context,
      settings: this,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeTag(str)),
        actions: [
          TextButton(
            onPressed: () {
              const TagManagerService().excluded.delete(str);
              BooruSearchPage.open(context);
            },
            child: Text(l10n.yes),
          ),
          TextButton(
            onPressed: () => BooruSearchPage.open(context),
            child: Text(l10n.no),
          ),
        ],
      ),
    );
  }
}

class _CardDialogAsyncPage extends Page<void> {
  const _CardDialogAsyncPage(this.data);

  final CardDialogStaticData data;

  @override
  Route<void> createRoute(BuildContext context) {
    return PageRouteBuilder(
      fullscreenDialog: true,
      barrierDismissible: true,
      settings: this,
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      pageBuilder: (context, animation, _) => OnBooruTagPressed(
        onPressed: data.onPressed,
        child: CardDialogStatic(
          animation: animation,
          getPost: () async {
            final dio = BooruAPI.defaultClientForBooru(data.booru);
            final api = BooruAPI.fromEnum(data.booru, dio);

            final Post post;
            try {
              post = await api.singlePost(data.postId);
            } catch (e) {
              rethrow;
            } finally {
              dio.close(force: true);
            }

            const VisitedPostsService().addAll([
              VisitedPost(
                booru: data.booru,
                id: data.postId,
                thumbUrl: post.previewUrl,
                rating: post.rating,
                date: DateTime.now(),
              ),
            ]);

            return post;
          },
        ),
      ),
    );
  }
}

class _CardDialogPage extends Page<void> {
  const _CardDialogPage(this.data);

  final CardDialogData data;

  @override
  Route<void> createRoute(BuildContext context) => PageRouteBuilder(
        fullscreenDialog: true,
        barrierDismissible: true,
        settings: this,
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.2),
        pageBuilder: (context, animation, _) => OnBooruTagPressed(
          onPressed: data.onPressed,
          child: Center(
            child: CardDialog(
              animation: animation,
              data: data,
            ),
          ),
        ),
        // Theme.of(context).colorScheme.surface.withValues(alpha: 0.35),
      );
}

class _Skeleton extends StatefulWidget {
  const _Skeleton({
    super.key,
    required this.state,
    required this.child,
  });

  final GoRouterState state;
  final StatefulNavigationShell child;

  @override
  State<_Skeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<_Skeleton>
    with
        NetworkStatusApi,
        NetworkStatusWatcher,
        SettingsWatcherMixin,
        TickerProviderStateMixin,
        AnimatedIconsMixin {
  bool showRail = false;
  final scrollingState = ScrollingStateSink();
  final pagingRegistry = PagingStateRegistry();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    showRail = MediaQuery.sizeOf(context).width >= 450;
  }

  @override
  void dispose() {
    scrollingState.dispose();
    pagingRegistry.recycle();

    super.dispose();
  }

  void onDestinationSelected(BuildContext context, CurrentRoute route) {
    final index = switch (route) {
      CurrentRoute.home => 0,
      CurrentRoute.discover => 1,
      CurrentRoute.gallery => 2,
    };
    widget.child.goBranch(index);

    SelectionActions.controllerOf(context).setCount(0);
    scrollingState.sink.add(true);
  }

  void onBooruDestination(BooruSubPage page) {
    SelectionActions.controllerOf(context).setCount(0);

    // final widget =
    //     context.dependOnInheritedWidgetOfExactType<_SelectedBooruPage>();

    // widget!.notifier!.value = page;

    return switch (page) {
      BooruSubPage.booru => context.go("/home"),
      BooruSubPage.favorites => context.go("/favorites"),
      BooruSubPage.bookmarks => context.go("/bookmarks"),
      BooruSubPage.hiddenPosts => context.go("/hiddenPosts"),
      BooruSubPage.downloads => context.go("/downloads"),
      BooruSubPage.visited => context.go("/visited"),
    };
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;
    final theme = Theme.of(context);

    final currentRoute = switch (widget.child.currentIndex) {
      0 => CurrentRoute.home,
      1 => CurrentRoute.discover,
      2 => CurrentRoute.gallery,
      int() => throw UnimplementedError(),
    };

    final currentBooru = switch (widget.state.matchedLocation) {
      "/home" => BooruSubPage.booru,
      "/hiddenPosts" => BooruSubPage.hiddenPosts,
      "/downloads" => BooruSubPage.downloads,
      "/visited" => BooruSubPage.visited,
      "/favorites" => BooruSubPage.favorites,
      "/bookmarks" => BooruSubPage.bookmarks,
      String() => BooruSubPage.booru,
    };
    final galleryPage = switch (widget.state.matchedLocation) {
      "/gallery/blacklisted" => GallerySubPage.blacklisted,
      String() => GallerySubPage.gallery,
    };

    print(widget.state.matchedLocation);

    final bool hideNavBar = switch (widget.state.matchedLocation) {
      "/gallery/files/imageView" || "/gallery/search" || "/home/search" => true,
      String() => false,
    };

    final bottomNavigationBar = showRail
        ? null
        : HomeNavigationBar(
            scrollingState: scrollingState,
            onDestinationSelected: onDestinationSelected,
            desitinations: icons(
              context,
              settings.selectedBooru,
            ),
          );

    final body = GestureDeadZones(
      right: true,
      left: true,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          _SkeletonBody(
            bottomPadding: bottomPadding,
            hasInternet: hasInternet,
            child: widget.child,
          ),
          if (!hasInternet) const NoNetworkIndicator(),
        ],
      ),
    );

    return galleryPage.inject(
      currentBooru.inject(
        currentRoute.inject(
          pagingRegistry.inject(
            AnnotatedRegion(
              value: navBarStyleForTheme(
                theme,
                highTone: false,
              ),
              child: Scaffold(
                extendBody: true,
                extendBodyBehindAppBar: true,
                drawerEnableOpenDragGesture: false,
                resizeToAvoidBottomInset: false,
                bottomNavigationBar: hideNavBar ? null : bottomNavigationBar,
                drawer: _Drawer(
                  selectDestination: onBooruDestination,
                  animatedIcons: this,
                  settingsService: const SettingsService(),
                  gridBookmarks: GridBookmarkService.safe(),
                  favoritePosts: FavoritePostSourceService.safe(),
                ),
                // backgroundColor: theme.colorScheme.surface.withValues(alpha: 0),
                body: switch (showRail) {
                  true => Row(
                      children: [
                        _NavigationRail(
                          onDestinationSelected: onDestinationSelected,
                          animatedIcons: this,
                          booru: settings.selectedBooru,
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: body),
                      ],
                    ),
                  false => body,
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Animate(
//   target: 0,
//   effects: [
//     FadeEffect(duration: 50.ms, begin: 1, end: 0),
//     const ThenEffect(delay: Duration(milliseconds: 50)),
//   ],
//   controller: icons.pageFadeAnimation,
//   child: switch (changePage._routeNotifier.value) {
//     CurrentRoute.home => !GridDbService.available
//         ? const SizedBox.shrink()
//         : _NavigatorShell(
//             navigatorKey: changePage.mainKey,
//             child: BooruPage(
//               pagingRegistry: changePage.pagingRegistry,
//               procPop: (pop) => changePage._procPopA(booruPage, icons, pop),
//               selectionController: SelectionActions.controllerOf(context),
//             ),
//           ),
//     CurrentRoute.gallery => !GridDbService.available ||
//             !GridSettingsService.available ||
//             !GalleryService.available
//         ? const SizedBox.shrink()
//         : _NavigatorShell(
//             navigatorKey: changePage.galleryKey,
//             child: DirectoriesPage(
//               procPop: (pop) => changePage._procPop(
//                 galleryPageNotifier,
//                 icons,
//                 pop,
//               ),
//               selectionController: SelectionActions.controllerOf(context),
//             ),
//           ),
//     CurrentRoute.discover => const DiscoverPage(),
//   },
// )

// if (route == _routeNotifier.value) {
//   navBarEvents.add(null);
//   return;
// }

// final currentRoute = _routeNotifier.value;

// if (route == CurrentRoute.home && currentRoute == CurrentRoute.home) {
//   Scaffold.of(context).openDrawer();
// } else if (route == CurrentRoute.gallery &&
//     currentRoute == CurrentRoute.gallery) {
//   final nav = galleryKey.currentState;
//   if (nav != null) {
//     while (nav.canPop()) {
//       nav.pop();
//     }
//   }

//   galleryPage.value = galleryPage.value == GallerySubPage.gallery
//       ? GallerySubPage.blacklisted
//       : GallerySubPage.gallery;

//   animateIcons(this);
// } else {
//   switchPage(this, route);
// }

class _SkeletonBody extends StatelessWidget {
  const _SkeletonBody({
    // super.key,
    required this.bottomPadding,
    required this.hasInternet,
    required this.child,
  });

  final double bottomPadding;
  final bool hasInternet;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);

    final padding = EdgeInsets.only(top: hasInternet ? 0 : 24);
    final viewPadding =
        data.viewPadding + EdgeInsets.only(bottom: bottomPadding);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Easing.standard,
      padding: padding,
      child: MediaQuery(
        data: data.copyWith(viewPadding: viewPadding),
        child: child,
      ),
    );
  }
}

class _NavigationRail extends StatefulWidget {
  const _NavigationRail({
    // super.key,
    required this.onDestinationSelected,
    required this.animatedIcons,
    required this.booru,
  });

  final AnimatedIconsMixin animatedIcons;

  final Booru booru;

  final DestinationCallback onDestinationSelected;

  @override
  State<_NavigationRail> createState() => __NavigationRailState();
}

class __NavigationRailState extends State<_NavigationRail>
    with DefaultSelectionEventsMixin {
  @override
  SelectionAreaSize get selectionSizes =>
      const SelectionAreaSize(base: 0, expanded: 0);

  List<NavigationRailDestination> railIcons(
    BuildContext context,
    AppLocalizations l10n,
    Booru selectedBooru,
  ) {
    NavigationRailDestination item(CurrentRoute e) => NavigationRailDestination(
          icon: e.icon(widget.animatedIcons),
          disabled: !e.hasServices(),
          label: Builder(
            builder: (context) {
              return Text(e.label(context, l10n, selectedBooru));
            },
          ),
        );

    return CurrentRoute.values.map(item).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
    final isExpanded = selectionActions.controller.isExpanded;

    final currentRoute = isExpanded ? 0 : CurrentRoute.of(context).index;

    void goToPage(int i) {
      widget.onDestinationSelected(
        context,
        CurrentRoute.fromIndex(i),
      );
    }

    void useAction(int i_) {
      int i = i_;

      if (i == 0) {
        selectionActions.controller.setCount(0);
      } else if (actions.isNotEmpty) {
        i -= 1;
        actions[i].consume();
      }
    }

    final destinations = switch (isExpanded) {
      true => [
          const NavigationRailDestination(
            icon: Icon(Icons.close_rounded),
            label: SizedBox.shrink(),
          ),
          ...actions.map(
            (e) => NavigationRailDestination(
              icon: Icon(e.icon),
              label: const SizedBox.shrink(),
            ),
          ),
        ],
      false => railIcons(context, l10n, widget.booru),
    };

    return NavigationRail(
      groupAlignment: -0.6,
      onDestinationSelected: isExpanded ? useAction : goToPage,
      destinations: destinations,
      selectedIndex: currentRoute,
    );
  }
}

class _Drawer extends StatefulWidget {
  const _Drawer({
    super.key,
    required this.settingsService,
    required this.animatedIcons,
    required this.gridBookmarks,
    required this.favoritePosts,
    required this.selectDestination,
  });

  final void Function(BooruSubPage subPage) selectDestination;
  final AnimatedIconsMixin animatedIcons;

  final GridBookmarkService? gridBookmarks;
  final FavoritePostSourceService? favoritePosts;

  final SettingsService settingsService;

  @override
  State<_Drawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<_Drawer> {
  GridBookmarkService? get gridBookmarks => widget.gridBookmarks;
  FavoritePostSourceService? get favoritePosts => widget.favoritePosts;

  late List<GridBookmark> bookmarks;
  late final StreamSubscription<void>? bookmarkEvents;

  late final SettingsData settings;

  final key = GlobalKey<AnimatedTagColumnState>();

  @override
  void initState() {
    super.initState();

    bookmarks = gridBookmarks?.firstNumber(5) ?? [];
    settings = widget.settingsService.current;

    bookmarkEvents = gridBookmarks?.watch(
      (_) {
        key.currentState?.diffAndAnimate(gridBookmarks!.firstNumber(5));
      },
      true,
    );
  }

  @override
  void dispose() {
    bookmarkEvents?.cancel();

    super.dispose();
  }

  void selectDestination(BuildContext context, int value) {
    widget.selectDestination(BooruSubPage.fromIdx(value));
    Scaffold.of(context).closeDrawer();

    switch (CurrentRoute.of(context)) {
      case CurrentRoute.home:
        widget.animatedIcons.homeIconController.reverse().then(
              (value) => widget.animatedIcons.homeIconController.forward(),
            );
      case CurrentRoute.gallery:
        widget.animatedIcons.galleryIconController.reverse().then(
              (value) => widget.animatedIcons.galleryIconController.forward(),
            );
      case CurrentRoute.discover:
        widget.animatedIcons.discoverIconController.reverse().then(
              (value) => widget.animatedIcons.discoverIconController.forward(),
            );
    }
  }

  void openSettings() => SettingsPage.open(context);

  @override
  Widget build(BuildContext context) {
    final selectedBooruPage = BooruSubPage.of(context);
    final l10n = context.l10n();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final statusBarColor = colorScheme.surface.withValues(alpha: 0);

    final brightnessReversed = theme.brightness == Brightness.light
        ? Brightness.dark
        : Brightness.light;

    final navigationDestinations = BooruSubPage.values.map(
      (e) => NavigationDrawerDestination(
        selectedIcon: Icon(e.selectedIcon),
        icon: Icon(e.icon),
        enabled: e.hasServices(),
        label: Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  e == BooruSubPage.booru
                      ? settings.selectedBooru.string
                      : e.translatedString(l10n),
                ),
                if (e == BooruSubPage.favorites && favoritePosts != null)
                  _DrawerNavigationBadgeStyle(
                    child: FavoritePostsCount(
                      favoritePosts: favoritePosts!,
                    ),
                  )
                else if (e == BooruSubPage.bookmarks && gridBookmarks != null)
                  _DrawerNavigationBadgeStyle(
                    child: BookmarksCount(
                      gridBookmarks: gridBookmarks!,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: statusBarColor,
        statusBarBrightness: brightnessReversed,
      ),
      child: NavigationDrawer(
        onDestinationSelected: (i) => selectDestination(context, i),
        selectedIndex: selectedBooruPage.index,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: AppLogoTitle(),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 8),
            child: Divider(),
          ),
          ...navigationDestinations,
          if (bookmarks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
              child: Text(
                l10n.latestBookmarks,
                style: theme.textTheme.titleSmall,
              ),
            ),
            AnimatedTagColumn(
              key: key,
              initalBookmarks: bookmarks,
            ),
          ],
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 8),
            child: Divider(),
          ),
          NavigationDrawerTile(
            icon: Icons.settings_outlined,
            label: l10n.settingsLabel,
            onPressed: openSettings,
          ),
          const Padding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }
}

class _DrawerNavigationBadgeStyle extends StatelessWidget {
  const _DrawerNavigationBadgeStyle({
    // super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface,
        ) ??
        const TextStyle();

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 24),
      child: DefaultTextStyle(
        style: textStyle,
        child: child,
      ),
    );
  }
}


  // Future<void> animateIcons(BuildContext context, AnimatedIconsMixin icons) {
  //   return switch (CurrentRoute.of(context)) {
  //     CurrentRoute.home => icons.homeIconController
  //         .reverse()
  //         .then((value) => icons.homeIconController.forward()),
  //     CurrentRoute.gallery => icons.galleryIconController
  //         .reverse()
  //         .then((value) => icons.galleryIconController.forward()),
  //     CurrentRoute.discover => icons.discoverIconController
  //         .reverse()
  //         .then((value) => icons.discoverIconController.forward()),
  //   };
  // }

    // final nav = widget.changePage.mainKey.currentState;
    // if (nav != null) {
    //   while (nav.canPop()) {
    //     nav.pop();
    //   }
    // }

    // BooruSubPage.selectOf(context, BooruSubPage.fromIdx(value));

    // animateIcons(context, widget.animatedIcons);
