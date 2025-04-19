// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/logic/directories_mixin.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/resource_source/chained_filter.dart";
import "package:azari/src/logic/resource_source/filtering_mode.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/trash_cell.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/booru/booru_page.dart";
import "package:azari/src/ui/material/pages/gallery/blacklisted_directories.dart";
import "package:azari/src/ui/material/pages/gallery/files.dart";
import "package:azari/src/ui/material/pages/gallery/gallery_return_callback.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/pages/search/gallery/gallery_search_page.dart";
import "package:azari/src/ui/material/widgets/empty_widget.dart";
import "package:azari/src/ui/material/widgets/grid_cell/cell.dart";
import "package:azari/src/ui/material/widgets/grid_cell_widget.dart";
import "package:azari/src/ui/material/widgets/scaffold_selection_bar.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/shell_app_bar_type.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/shell_fab_type.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/segment_layout.dart";
import "package:azari/src/ui/material/widgets/shell/parts/shell_settings_button.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:azari/src/ui/material/widgets/shimmer_placeholders.dart";
import "package:azari/src/ui/material/widgets/wrap_future_restartable.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:local_auth/local_auth.dart";
import "package:logging/logging.dart";

class DirectoriesPage extends StatefulWidget {
  const DirectoriesPage({
    super.key,
    required this.selectionController,
    this.callback,
    this.wrapGridPage = false,
    this.showBackButton = false,
    this.providedApi,
    this.procPop,
  });

  final bool showBackButton;
  final bool wrapGridPage;

  final void Function(bool)? procPop;

  final GalleryReturnCallback? callback;

  final Directories? providedApi;

  final SelectionController selectionController;

  static bool hasServicesRequired() =>
      GridSettingsService.available &&
      GridDbService.available &&
      GalleryService.available;

  static Future<void> open(
    BuildContext context, {
    bool showBackButton = false,
    bool wrapGridPage = false,
    void Function(bool)? procPop,
    GalleryReturnCallback? callback,
    Directories? providedApi,
  }) {
    if (!hasServicesRequired()) {
      // TODO: change
      addAlert("DirectoriesPage", "Gallery functionality isn't available");

      return Future.value();
    }

    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => DirectoriesPage(
          // l10n: l10n,
          showBackButton: showBackButton,
          wrapGridPage: wrapGridPage,
          procPop: procPop,
          callback: callback,
          providedApi: providedApi,
          selectionController: SelectionActions.controllerOf(context),
        ),
      ),
    );
  }

  @override
  State<DirectoriesPage> createState() => _DirectoriesPageState();
}

class _DirectoriesPageState extends State<DirectoriesPage>
    with
        SettingsWatcherMixin,
        DirectoriesMixin,
        SingleTickerProviderStateMixin {
  @override
  GalleryReturnCallback? get callback => widget.callback;

  @override
  Directories? get providedApi => widget.providedApi;

  @override
  SelectionController get selectionController => widget.selectionController;

  @override
  void onRequireAuth(BuildContext context, void Function() launchLocalAuth) {
    final l10n = context.l10n();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.directoriesAuthMessage),
        action: SnackBarAction(
          label: l10n.authLabel,
          onPressed: launchLocalAuth,
        ),
      ),
    );
  }

  Widget child(BuildContext context) {
    final l10n = context.l10n();
    final navBarEvents = NavigationButtonEvents.maybeOf(context);

    final settingsButton = ShellSettingsButton(
      add: addShellConfig,
      watch: gridSettings.watch,
      localizeHideNames: (context) => l10n.hideNames(l10n.hideNamesDirectories),
    );

    // SliverAppBar(
    //               actionsPadding: EdgeInsets.zero,
    //               titleSpacing: 0,
    //               floating: true,
    //               snap: true,
    //               centerTitle: true,
    //               title: ConstrainedBox(
    //                 constraints: BoxConstraints(maxWidth: 520),
    //                 child: TabBar(
    //                   dividerHeight: 0,
    //                   controller: tabController,
    //                   // indicatorSize: TabBarIndicatorSize.tab,
    //                   // splashBorderRadius: BorderRadius.all(Radius.circular(19)),
    //                   tabs: const [
    //                     Tab(
    //                       icon: Icon(Icons.photo_outlined),
    //                     ),
    //                     Tab(
    //                       icon: Icon(Icons.photo_library_outlined),
    //                     ),
    //                   ],
    //                 ),
    //               ),
    //             )

    return GridPopScope(
      filter: filter,
      rootNavigatorPopCond: widget.callback?.isFile ?? false,
      searchTextController: searchTextController,
      rootNavigatorPop: widget.procPop,
      child: ShellScope(
        stackInjector: status,
        configWatcher: gridSettings.watch,
        footer: widget.callback?.preview,
        fab: widget.callback == null
            ? const NoShellFab()
            : const DefaultShellFab(),
        settingsButton: widget.callback == null ? settingsButton : null,
        appBar: widget.callback != null
            ? SearchBarAppBarType.fromFilter(
                filter,
                textEditingController: searchTextController,
                complete: completeDirectoryNameTag,
                focus: searchFocus,
                trailingItems: [
                  if (widget.callback!.isDirectory)
                    IconButton(
                      onPressed: () => FilesApi.safe()
                          ?.chooseDirectory(l10n, temporary: true)
                          .then((value) {
                        widget.callback!.toDirectory(
                          (
                            bucketId: "",
                            path: value!.path,
                            volumeName: "",
                          ),
                          true,
                        );
                      }).onError((e, trace) {
                        Logger.root.severe(
                          "new folder in android_directories",
                          e,
                          trace,
                        );
                      }).whenComplete(() {
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      }),
                      icon: const Icon(Icons.create_new_folder_outlined),
                    )
                  else
                    IconButton(
                      onPressed: () {
                        GallerySubPage.selectOf(
                          context,
                          GallerySubPage.blacklisted,
                        );
                      },
                      icon: const Icon(Icons.folder_off_outlined),
                    ),
                ],
              )
            : RawAppBarType(
                (context, settingsButton, bottomWidget) {
                  final theme = Theme.of(context);

                  return SliverAppBar(
                    automaticallyImplyLeading: false,
                    systemOverlayStyle: SystemUiOverlayStyle(
                      statusBarIconBrightness:
                          theme.brightness == Brightness.light
                              ? Brightness.dark
                              : Brightness.light,
                      statusBarColor:
                          theme.colorScheme.surface.withValues(alpha: 0.95),
                    ),
                    bottom: bottomWidget ??
                        const PreferredSize(
                          preferredSize: Size.zero,
                          child: SizedBox.shrink(),
                        ),
                    title: const AppLogoTitle(),
                    actions: [
                      IconButton(
                        onPressed: () => GallerySearchPage.open(context),
                        icon: const Icon(Icons.search_rounded),
                      ),
                      IconButton(
                        onPressed: () {
                          GallerySubPage.selectOf(
                            context,
                            GallerySubPage.blacklisted,
                          );
                        },
                        icon: const Icon(Icons.folder_off_outlined),
                      ),
                      if (settingsButton != null) settingsButton,
                    ],
                  );
                },
              ),
        elements: [
          // if (widget.callback != null)
          //   ElementPriority(
          //   ,
          //     hideOnEmpty: false,
          //   ),
          ElementPriority(
            ShellElement(
              state: status,
              scrollingState: ScrollingStateSinkProvider.maybeOf(context),
              scrollUpOn: navBarEvents == null
                  ? const []
                  : [(navBarEvents, () => api.bindFiles == null)],
              registerNotifiers: (child) => DirectoriesDataNotifier(
                api: api,
                callback: widget.callback,
                segmentFnc: segmentCell,
                child: child,
              ),
              slivers: [
                // TODO: latest suggestions widget is broken
                // if (widget.callback?.isFile ?? false)
                //   SliverToBoxAdapter(
                //     child: _LatestImagesWidget(
                //       selectionActions: SelectionActions.of(context),
                //       parent: api,
                //       callback: widget.callback?.toFile,
                //       gallerySearch: const GalleryService().search,
                //       directoryMetadata: DirectoryMetadataService.safe(),
                //       directoryTags: DirectoryTagService.safe(),
                //       favoritePosts: FavoritePostSourceService.safe(),
                //       localTagsService: LocalTagsService.safe(),
                //     ),
                //   ),
                SegmentLayout(
                  segments: makeSegments(
                    context,
                    l10n: l10n,
                  ),
                  gridSeed: 1,
                  suggestionPrefix: (widget.callback?.isDirectory ?? false)
                      ? widget.callback!.toDirectory.suggestFor
                      : const [],
                  storage: filter.backingStorage,
                  progress: filter.progress,
                  l10n: l10n,
                  selection: status.selection,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subpage = GallerySubPage.maybeOf(context);
    if (subpage == null) {
      return widget.wrapGridPage || widget.callback != null
          ? ScaffoldSelectionBar(
              addScaffoldAndBar: true,
              child: Builder(
                builder: child,
              ),
            )
          : child(context);
    }

    return switch (subpage) {
      GallerySubPage.gallery => widget.wrapGridPage || widget.callback != null
          ? ScaffoldSelectionBar(
              child: Builder(
                builder: child,
              ),
            )
          : child(context),
      GallerySubPage.blacklisted => BlacklistedDirectoryService.available
          ? DirectoriesDataNotifier(
              api: api,
              callback: widget.callback,
              segmentFnc: segmentCell,
              child: GridPopScope(
                searchTextController: null,
                filter: null,
                rootNavigatorPop: widget.procPop,
                child: BlacklistedDirectoriesPage(
                  footer: widget.callback?.preview,
                  popScope: widget.procPop ??
                      (_) => GallerySubPage.selectOf(
                            context,
                            GallerySubPage.gallery,
                          ),
                  selectionController: widget.selectionController,
                ),
              ),
            )
          : const SizedBox.shrink(),
    };
  }
}

// class _LatestImagesWidget extends StatefulWidget {
//   const _LatestImagesWidget({
//     // super.key,
//     required this.parent,
//     required this.callback,
//     required this.selectionActions,
//     required this.gallerySearch,
//     required this.directoryMetadata,
//     required this.directoryTags,
//     required this.favoritePosts,
//     required this.localTagsService,
//   });

//   final Directories parent;
//   final ReturnFileCallback? callback;

//   final Search gallerySearch;
//   final SelectionActions selectionActions;

//   final DirectoryMetadataService? directoryMetadata;
//   final DirectoryTagService? directoryTags;
//   final FavoritePostSourceService? favoritePosts;
//   final LocalTagsService? localTagsService;

//   @override
//   State<_LatestImagesWidget> createState() => __LatestImagesWidgetState();
// }

// class __LatestImagesWidgetState extends State<_LatestImagesWidget> {
//   Search get gallerySearch => widget.gallerySearch;

//   late final StreamSubscription<void>? _directoryCapsChanged;

//   late final filesApi = Files.fake(
//     clearRefresh: () {
//       final c = <String, DirectoryMetadata>{};

//       return gallerySearch.filesByName("", 20).then((l) {
//         final ll = _fromDirectoryFileFiltered(l, c);

//         if (ll.length < 10) {
//           return gallerySearch
//               .filesByName("", 20)
//               .then((e) => ll + _fromDirectoryFileFiltered(l, c));
//         }

//         return ll;
//       });
//     },
//     parent: widget.parent,
//     directoryMetadata: widget.directoryMetadata,
//     directoryTags: widget.directoryTags,
//     favoritePosts: widget.favoritePosts,
//     localTags: widget.localTagsService,
//   );

//   late final gridSelection = ShellSelectionHolder.source(
//     widget.selectionActions.controller,
//     const [],
//     // noAppBar: true,
//     source: filesApi.source.backingStorage,
//   );

//   final focus = FocusNode();

//   late final SourceShellElementState<File> status;

//   final ValueNotifier<bool> scrollNotifier = ValueNotifier(false);
//   final controller = ScrollController();

//   List<File> _fromDirectoryFileFiltered(
//     List<File> l,
//     Map<String, DirectoryMetadata> c,
//   ) {
//     return l
//         .where(
//           (e) => filterAuthBlur(
//             c,
//             e,
//             directoryMetadata: widget.directoryMetadata,
//             directoryTag: widget.directoryTags,
//           ),
//         )
//         .toList();
//   }

//   @override
//   void initState() {
//     super.initState();

//     _directoryCapsChanged = widget.directoryMetadata?.cache.watch((_) {
//       filesApi.source.clearRefresh();
//     });

//     status = SourceShellElementState(
//       source: filesApi.source,
//       onEmpty: SourceOnEmptyInterface(filesApi.source, (context) => ""),
//       selectionController: widget.selectionActions.controller,
//       actions: const [],
//     );
//   }

//   @override
//   void dispose() {
//     status.destroy();
//     _directoryCapsChanged?.cancel();
//     focus.dispose();
//     filesApi.close();
//     scrollNotifier.dispose();
//     controller.dispose();

//     super.dispose();
//   }

//   bool filterAuthBlur(
//     Map<String, DirectoryMetadata> m,
//     File? dir, {
//     required DirectoryTagService? directoryTag,
//     required DirectoryMetadataService? directoryMetadata,
//   }) {
//     final segment = defaultSegmentCell(
//       dir!.name,
//       dir.bucketId,
//       directoryTag,
//     );

//     DirectoryMetadata? data = m[segment];
//     if (data == null) {
//       final d = directoryMetadata?.cache.get(segment);
//       if (d == null) {
//         return true;
//       }

//       data = d;
//       m[segment] = d;
//     }

//     return !data.requireAuth && !data.blur;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return ShellScrollNotifier(
//       saveScrollNotifier: scrollNotifier,
//       fabNotifier: scrollNotifier,
//       controller: controller,
//       scrollSizeCalculator: (contentSize, idx, layoutType, columns) =>
//           0, // TODO: change
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(15),
//         child: DecoratedBox(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(15),
//             color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.8),
//           ),
//           child: FadingPanel(
//             label: "",
//             source: filesApi.source,
//             enableHide: false,
//             horizontalPadding: _LatestList.listPadding,
//             childSize: _LatestList.size,
//             child: _LatestList(source: filesApi.source),
//           ),
//         ),
//       ),
//     );
//   }
// }

class _LatestList extends StatefulWidget {
  const _LatestList({
    // super.key,
    required this.source,
  });

  final ResourceSource<int, File> source;

  static const size = Size(140 / 1.5, 140 + 16);
  static const listPadding = EdgeInsets.symmetric(horizontal: 12);

  @override
  State<_LatestList> createState() => __LatestListState();
}

class __LatestListState extends State<_LatestList> {
  ResourceSource<int, File> get source => widget.source;

  late final StreamSubscription<void> subscription;

  @override
  void initState() {
    super.initState();

    subscription = source.backingStorage.watch((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    subscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return SizedBox(
      width: double.infinity,
      height: _LatestList.size.height,
      child: WrapFutureRestartable<int>(
        bottomSheetVariant: true,
        placeholder: const ShimmerPlaceholdersHorizontal(
          childSize: _LatestList.size,
          padding: _LatestList.listPadding,
        ),
        newStatus: () {
          if (source.backingStorage.isNotEmpty) {
            return Future.value(source.backingStorage.count);
          }

          return source.clearRefresh();
        },
        builder: (context, _) {
          return ListView.builder(
            padding: _LatestList.listPadding,
            scrollDirection: Axis.horizontal,
            itemCount: source.backingStorage.count,
            itemBuilder: (context, i) {
              final cell = source.backingStorage[i];

              return InkWell(
                onTap: () => cell.openImage(context),
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  width: _LatestList.size.width,
                  child: GridCell(
                    uniqueKey: cell.uniqueKey(),
                    title: cell.title(l10n),
                    thumbnail: cell.thumbnail(),
                    imageAlign: Alignment.topCenter,
                    alignStickersTopCenter: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class GridPopScope extends StatefulWidget {
  const GridPopScope({
    super.key,
    this.rootNavigatorPop,
    required this.searchTextController,
    required this.filter,
    this.rootNavigatorPopCond = false,
    required this.child,
  });

  final bool rootNavigatorPopCond;

  final TextEditingController? searchTextController;
  final ChainedFilterResourceSource<dynamic, dynamic>? filter;

  final void Function(bool)? rootNavigatorPop;

  final Widget child;

  @override
  State<GridPopScope> createState() => _GridPopScopeState();
}

mixin ShellPopScopeMixin<W extends StatefulWidget> on State<W> {
  bool get rootNavigatorPopCond;

  TextEditingController? get searchTextController;
  ChainedFilterResourceSource<dynamic, dynamic>? get filter;
  late SelectionController controller;

  void Function(bool)? get rootNavigatorPop;

  late final StreamSubscription<void>? _watcher;

  bool get canPop => rootNavigatorPop != null
      ? rootNavigatorPopCond
      : false ||
          !controller.isExpanded &&
              (searchTextController == null ||
                  searchTextController!.text.isEmpty) &&
              (filter == null ||
                  filter!.allowedFilteringModes.isEmpty ||
                  (filter!.allowedFilteringModes
                          .contains(FilteringMode.noFilter) &&
                      filter!.filteringMode == FilteringMode.noFilter));

  @override
  void initState() {
    super.initState();

    _watcher = filter?.backingStorage.watch((_) {
      setState(() {});
    });

    searchTextController?.addListener(listener);
  }

  @override
  void dispose() {
    searchTextController?.removeListener(listener);

    _watcher?.cancel();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    controller = SelectionActions.controllerOf(context);
  }

  void onPopInvoked(bool didPop, void _) {
    if (controller.isExpanded) {
      controller.setCount(0);

      return;
    } else if (searchTextController != null &&
        searchTextController!.text.isNotEmpty) {
      searchTextController!.text = "";
      filter?.clearRefresh();

      return;
    } else if (filter != null &&
        filter!.allowedFilteringModes.contains(FilteringMode.noFilter) &&
        filter!.filteringMode != FilteringMode.noFilter) {
      filter!.filteringMode = FilteringMode.noFilter;
    }

    rootNavigatorPop?.call(didPop);
  }

  void listener() {
    setState(() {});
  }
}

class _GridPopScopeState extends State<GridPopScope> with ShellPopScopeMixin {
  @override
  ChainedFilterResourceSource<dynamic, dynamic>? get filter => widget.filter;

  @override
  void Function(bool p1)? get rootNavigatorPop => widget.rootNavigatorPop;

  @override
  bool get rootNavigatorPopCond => widget.rootNavigatorPopCond;

  @override
  TextEditingController? get searchTextController =>
      widget.searchTextController;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: onPopInvoked,
      child: widget.child,
    );
  }
}

class DirectoriesDataNotifier extends InheritedWidget {
  const DirectoriesDataNotifier({
    super.key,
    required this.api,
    required this.callback,
    required this.segmentFnc,
    required super.child,
  });

  final Directories api;
  final GalleryReturnCallback? callback;
  final String Function(Directory cell) segmentFnc;

  static (
    Directories,
    GalleryReturnCallback?,
    String Function(Directory cell),
  ) of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<DirectoriesDataNotifier>();

    return (
      widget!.api,
      widget.callback,
      widget.segmentFnc,
    );
  }

  @override
  bool updateShouldNotify(DirectoriesDataNotifier oldWidget) =>
      api != oldWidget.api ||
      callback != oldWidget.callback ||
      segmentFnc != oldWidget.segmentFnc;
}

class _EmptyWidget extends StatefulWidget {
  const _EmptyWidget({
    // super.key,
    required this.trashCell,
  });

  final TrashCell? trashCell;

  @override
  State<_EmptyWidget> createState() => __EmptyWidgetState();
}

class __EmptyWidgetState extends State<_EmptyWidget> {
  late final StreamSubscription<void>? subscr;

  bool haveTrashCell = true;

  @override
  void initState() {
    super.initState();

    subscr = widget.trashCell?.watch(
      (t) {
        setState(() {
          haveTrashCell = t != null;
        });
      },
      true,
    );
  }

  @override
  void dispose() {
    subscr?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    if (haveTrashCell) {
      return const SizedBox.shrink();
    }

    return EmptyWidgetBackground(
      subtitle: l10n.emptyDevicePictures,
    );
  }
}

SelectionBarAction blacklist(
  BuildContext context,
  String Function(Directory) segment,
) {
  return SelectionBarAction(
    Icons.hide_image_outlined,
    (selected) {
      final requireAuth = <BlacklistedDirectoryData>[];
      final noAuth = <BlacklistedDirectoryData>[];

      for (final (e as Directory) in selected) {
        final m = DirectoryMetadataService.safe()?.cache.get(segment(e));
        if (m != null && m.requireAuth) {
          requireAuth.add(
            BlacklistedDirectoryData(bucketId: e.bucketId, name: e.name),
          );
        } else {
          noAuth.add(
            BlacklistedDirectoryData(bucketId: e.bucketId, name: e.name),
          );
        }
      }

      if (noAuth.isNotEmpty) {
        if (requireAuth.isNotEmpty && !const AppApi().canAuthBiometric) {
          const BlacklistedDirectoryService()
              .backingStorage
              .addAll(noAuth + requireAuth);
          return;
        }

        const BlacklistedDirectoryService().backingStorage.addAll(noAuth);
      }

      if (requireAuth.isNotEmpty) {
        final l10n = context.l10n();

        if (const AppApi().canAuthBiometric) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.directoriesAuthMessage),
              action: SnackBarAction(
                label: l10n.authLabel,
                onPressed: () async {
                  final success = await LocalAuthentication().authenticate(
                    localizedReason: l10n.hideDirectoryReason,
                  );
                  if (!success) {
                    return;
                  }

                  const BlacklistedDirectoryService()
                      .backingStorage
                      .addAll(requireAuth);
                },
              ),
            ),
          );
        } else {
          const BlacklistedDirectoryService()
              .backingStorage
              .addAll(requireAuth);
        }
      }
    },
    true,
  );
}

SelectionBarAction joinedDirectories(
  BuildContext context,
  Directories api,
  ReturnFileCallback? callback,
  String Function(Directory) segment,
) {
  return SelectionBarAction(
    Icons.merge_rounded,
    (selected) {
      joinedDirectoriesFnc(
        context,
        selected.length == 1
            ? (selected.first as Directory).name
            : "${selected.length} ${context.l10n().directoriesPlural}",
        selected.cast(),
        api,
        callback,
        segment,
      );
    },
    true,
  );
}

Future<void> joinedDirectoriesFnc(
  BuildContext context,
  String label,
  List<Directory> dirs,
  Directories api,
  ReturnFileCallback? callback,
  String Function(Directory) segment, {
  String tag = "",
  FilteringMode? filteringMode,
  bool addScaffold = false,
}) {
  bool requireAuth = false;

  for (final e in dirs) {
    final auth =
        DirectoryMetadataService.safe()?.cache.get(segment(e))?.requireAuth ??
            false;
    if (auth) {
      requireAuth = true;
      break;
    }
  }

  Future<void> onSuccess(bool success) {
    if (!success || !context.mounted) {
      return Future.value();
    }

    StatisticsGalleryService.addJoined(1);

    return FilesPage.open(
      context,
      secure: requireAuth,
      api: api,
      directories: dirs,
      callback: callback,
      addScaffold: addScaffold,
      dirName: label,
      presetFilteringValue: tag,
      filteringMode: filteringMode,
    );
  }

  if (requireAuth && const AppApi().canAuthBiometric) {
    final l10n = context.l10n();

    return LocalAuthentication()
        .authenticate(localizedReason: l10n.joinDirectoriesReason)
        .then(onSuccess);
  } else {
    return onSuccess(true);
  }
}

SelectionBarAction addToGroup<T extends CellBuilder>(
  BuildContext context,
  String? Function(List<T>) initalValue,
  Future<void Function(BuildContext)?> Function(List<T>, String, bool)
      onSubmitted,
  bool showPinButton, {
  Future<List<BooruTag>> Function(String str)? completeDirectoryNameTag,
}) {
  return SelectionBarAction(
    Icons.group_work_outlined,
    (selected) {
      if (selected.isEmpty) {
        return;
      }

      Navigator.of(context, rootNavigator: true).push(
        DialogRoute<void>(
          context: context,
          builder: (context) {
            return _GroupDialogWidget<T>(
              initalValue: initalValue,
              onSubmitted: onSubmitted,
              selected: selected.cast(),
              showPinButton: showPinButton,
              completeDirectoryNameTag: completeDirectoryNameTag,
            );
          },
        ),
      );
    },
    false,
  );
}

class _GroupDialogWidget<T> extends StatefulWidget {
  const _GroupDialogWidget({
    super.key,
    required this.initalValue,
    required this.onSubmitted,
    required this.selected,
    required this.showPinButton,
    required this.completeDirectoryNameTag,
  });

  final List<T> selected;
  final String? Function(List<T>) initalValue;
  final Future<void Function(BuildContext)?> Function(List<T>, String, bool)
      onSubmitted;
  final Future<List<BooruTag>> Function(String str)? completeDirectoryNameTag;
  final bool showPinButton;

  @override
  State<_GroupDialogWidget<T>> createState() => __GroupDialogWidgetState();
}

class __GroupDialogWidgetState<T> extends State<_GroupDialogWidget<T>> {
  bool toPin = false;

  final focus = FocusNode();
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    focus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return AlertDialog(
      title: Text(l10n.group),
      actions: [
        IconButton.filled(
          onPressed: () {
            toPin = !toPin;

            setState(() {});
          },
          icon: const Icon(Icons.push_pin_rounded),
          isSelected: toPin,
        ),
      ],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SearchBarAutocompleteWrapper(
            search: SearchBarAppBarType(
              textEditingController: controller,
              onChanged: null,
              complete: widget.completeDirectoryNameTag,
            ),
            child: (context, controller, focus, onSubmitted) {
              return TextFormField(
                autofocus: true,
                focusNode: focus,
                controller: controller,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
                onFieldSubmitted: (value) {
                  onSubmitted();
                  widget.onSubmitted(widget.selected, value, toPin).then((e) {
                    if (context.mounted) {
                      e?.call(context);

                      Navigator.pop(context);
                    }
                  });
                },
              );
            },
            searchFocus: focus,
          ),
        ],
      ),
    );
  }
}
