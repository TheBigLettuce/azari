// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/resource_source/source_storage.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/widgets/grid_cell_widget.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/cell_builder.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/grid_layout.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/placeholders.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";

class PoolsExpandedPage extends StatefulWidget {
  const PoolsExpandedPage({super.key, required this.source});

  final ResourceSource<int, BooruPool> source;

  static void open(
    BuildContext context,
    ResourceSource<int, BooruPool> source,
  ) {
    Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder(
        barrierDismissible: true,
        fullscreenDialog: true,
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.2),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: SafeArea(child: PoolsExpandedPage(source: source)),
          );
        },
      ),
    );
  }

  @override
  State<PoolsExpandedPage> createState() => _PoolsExpandedPageState();
}

class _PoolsExpandedPageState extends State<PoolsExpandedPage> {
  ReadOnlyStorage<int, BooruPool> get source => widget.source.backingStorage;

  final controller = ScrollController();
  late final StreamSubscription<bool> _progressEvents;
  final focusNode = FocusNode();
  late final _progress = _Progress(widget.source);
  final _notifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();

    _progressEvents = widget.source.progress.watch((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _notifier.dispose();
    focusNode.dispose();
    _progressEvents.cancel();
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.comfortable,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Hero(
                  tag: "poolsText",
                  child: Text("Pools", style: theme.textTheme.headlineMedium),
                ),
                IconButton(
                  onPressed: () {},
                  visualDensity: VisualDensity.comfortable,
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),

                    child: SizedBox(
                      height: 48,
                      child: SearchBar(
                        focusNode: focusNode,
                        onTapOutside: (event) => focusNode.unfocus(),
                        leading: const Icon(Icons.search_rounded),
                        hintText: "Name...",
                        overlayColor: WidgetStatePropertyAll(
                          theme.colorScheme.surfaceContainerHighest,
                        ),
                        backgroundColor: WidgetStatePropertyAll(
                          theme.colorScheme.surface,
                        ),
                        elevation: const WidgetStatePropertyAll(0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20) +
                  const EdgeInsets.only(bottom: 16),
              child: ShellScrollingLogicHolder(
                controller: controller,
                initalScrollPosition: 0,
                state: _progress,
                scrollingState: null,
                offsetSaveNotifier: _notifier,
                scrollUpOn: const [],
                updateScrollPosition: null,
                next: widget.source.next,
                child: RefreshIndicator(
                  onRefresh: widget.source.clearRefresh,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child: TrackedIndex.wrap(
                      GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 18),
                        itemCount:
                            source.count +
                            (widget.source.progress.inRefreshing ? 18 : 0),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.6,
                            ),
                        controller: controller,
                        itemBuilder: (context, idx) {
                          final l10n = context.l10n();
                          final cell = source.elementAtOrNull(idx);
                          if (cell == null) {
                            return const GridCellPlaceholder(
                              circle: false,
                              tightMode: true,
                              tightModeMargin: 0,
                              borderRadius: BorderRadius.zero,
                            );
                          }

                          return TrackingIndexHolder(
                            idx: idx,
                            child: ThisIndex(
                              idx: idx,
                              selectFrom: null,
                              child: Builder(
                                builder: (context) => cell.buildCell(
                                  l10n,
                                  cellType: CellType.cell,
                                  hideName: true,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Progress<T extends CellBuilder> extends ShellElementProgress {
  const _Progress(this.source);

  final ResourceSource<int, T> source;

  @override
  bool get canLoadMore => source.progress.canLoadMore;

  @override
  bool get hasNext => source.hasNext;

  @override
  bool get isRefreshing => source.progress.inRefreshing;
}
