// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/logic/directories_mixin.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/resource_source/chained_filter.dart";
import "package:azari/src/logic/resource_source/filtering_mode.dart";
import "package:azari/src/logic/trash_cell.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/booru/booru_page.dart";
import "package:azari/src/ui/material/pages/gallery/files.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/pages/search/gallery/gallery_search_page.dart";
import "package:azari/src/ui/material/widgets/empty_widget.dart";
import "package:azari/src/ui/material/widgets/grid_cell/cell.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/shell_app_bar_type.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/segment_layout.dart";
import "package:azari/src/ui/material/widgets/shell/parts/shell_settings_button.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:go_router/go_router.dart";
import "package:local_auth/local_auth.dart";

class DirectoriesPage extends StatefulWidget {
  const DirectoriesPage({
    super.key,
    required this.selectionController,
  });

  final SelectionController selectionController;

  static bool hasServicesRequired() =>
      GridSettingsService.available &&
      GridDbService.available &&
      GalleryService.available;

  static void open(
    BuildContext context, {
    bool showBackButton = false,
    bool wrapGridPage = false,
  }) {
    if (!hasServicesRequired()) {
      // TODO: change
      addAlert("DirectoriesPage", "Gallery functionality isn't available");

      return;
    }

    context.goNamed(
      "Directories",
      queryParameters: {
        "showBackButton": showBackButton ? "1" : "0",
        "addScaffold": wrapGridPage ? "1" : "0",
      },
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
    final navBarEvents = NavigationButtonEvents.maybeOf(context);

    final settingsButton = ShellSettingsButton(
      add: addShellConfig,
      watch: gridSettings.watch,
      localizeHideNames: (context) => l10n.hideNames(l10n.hideNamesDirectories),
    );

    return ShellScope(
      stackInjector: status,
      configWatcher: gridSettings.watch,
      settingsButton: settingsButton,
      appBar: RawAppBarType(
        (context, settingsButton, bottomWidget) {
          final theme = Theme.of(context);

          return SliverAppBar(
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarIconBrightness: theme.brightness == Brightness.light
                  ? Brightness.dark
                  : Brightness.light,
              statusBarColor: theme.colorScheme.surface.withValues(alpha: 0.95),
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
        ElementPriority(
          ShellElement(
            state: status,
            scrollingState: ScrollingStateSinkProvider.maybeOf(context),
            scrollUpOn: navBarEvents == null
                ? const []
                : [(navBarEvents, () => api.bindFiles == null)],
            slivers: [
              SegmentLayout(
                segments: makeSegments(
                  context,
                  l10n: l10n,
                ),
                gridSeed: 1,
                suggestionPrefix: const [],
                storage: filter.backingStorage,
                progress: filter.progress,
                l10n: l10n,
                selection: status.selection,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// class _LatestList extends StatefulWidget {
//   const _LatestList({
//     // super.key,
//     required this.source,
//   });

//   final ResourceSource<int, File> source;

//   static const size = Size(140 / 1.5, 140 + 16);
//   static const listPadding = EdgeInsets.symmetric(horizontal: 12);

//   @override
//   State<_LatestList> createState() => __LatestListState();
// }

// class __LatestListState extends State<_LatestList> {
//   ResourceSource<int, File> get source => widget.source;

//   late final StreamSubscription<void> subscription;

//   @override
//   void initState() {
//     super.initState();

//     subscription = source.backingStorage.watch((_) {
//       setState(() {});
//     });
//   }

//   @override
//   void dispose() {
//     subscription.cancel();

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = context.l10n();

//     return SizedBox(
//       width: double.infinity,
//       height: _LatestList.size.height,
//       child: WrapFutureRestartable<int>(
//         bottomSheetVariant: true,
//         placeholder: const ShimmerPlaceholdersHorizontal(
//           childSize: _LatestList.size,
//           padding: _LatestList.listPadding,
//         ),
//         newStatus: () {
//           if (source.backingStorage.isNotEmpty) {
//             return Future.value(source.backingStorage.count);
//           }

//           return source.clearRefresh();
//         },
//         builder: (context, _) {
//           return ListView.builder(
//             padding: _LatestList.listPadding,
//             scrollDirection: Axis.horizontal,
//             itemCount: source.backingStorage.count,
//             itemBuilder: (context, i) {
//               final cell = source.backingStorage[i];

//               return InkWell(
//                 onTap: () => cell.openImage(context),
//                 borderRadius: BorderRadius.circular(15),
//                 child: SizedBox(
//                   width: _LatestList.size.width,
//                   child: GridCell(
//                     uniqueKey: cell.uniqueKey(),
//                     title: cell.title(l10n),
//                     thumbnail: cell.thumbnail(),
//                     imageAlign: Alignment.topCenter,
//                     alignStickersTopCenter: true,
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

class GridPopScope extends StatefulWidget {
  const GridPopScope({
    super.key,
    // this.rootNavigatorPop,
    required this.searchTextController,
    required this.filter,
    // this.rootNavigatorPopCond = false,
    required this.child,
  });

  // final bool rootNavigatorPopCond;

  final TextEditingController? searchTextController;
  final ChainedFilterResourceSource<dynamic, dynamic>? filter;

  // final void Function(bool)? rootNavigatorPop;

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
                      filter!.filteringMode == FilteringMode.noFilter)) &&
              (filter == null ||
                  filter!.filteringColors == null ||
                  filter!.filteringColors == FilteringColors.noColor);

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
        filter!.filteringColors != null &&
        filter!.filteringColors != FilteringColors.noColor) {
      filter!.setColors!(FilteringColors.noColor);
      return;
    } else if (filter != null &&
        filter!.allowedFilteringModes.contains(FilteringMode.noFilter) &&
        filter!.filteringMode != FilteringMode.noFilter) {
      filter!.filteringMode = FilteringMode.noFilter;
      return;
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
  void Function(bool p1)? get rootNavigatorPop => null;

  @override
  bool get rootNavigatorPopCond => false;

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
  String Function(Directory) segment,
) {
  return SelectionBarAction(
    Icons.merge_rounded,
    (selected) {
      api.files(selected.cast());
      FilesPage.open(context);
    },
    true,
  );
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
