// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../search_page.dart";

class _DirectoryList extends StatefulWidget {
  const _DirectoryList({
    // super.key,
    required this.filteringEvents,
    required this.source,
    required this.searchController,
    required this.blurMap,
    required this.onDirectoryPressed,
  });

  final StreamController<String> filteringEvents;
  final TextEditingController searchController;

  final ResourceSource<int, Directory> source;

  final Map<String, bool> blurMap;

  final void Function(Directory) onDirectoryPressed;

  @override
  State<_DirectoryList> createState() => __DirectoryListState();
}

class __DirectoryListState extends State<_DirectoryList> {
  String filteringValue = "";

  late final ChainedFilterResourceSource<int, Directory> filter;

  late final StreamSubscription<String> subscr;

  @override
  void initState() {
    super.initState();

    filter = ChainedFilterResourceSource.basic(
      widget.source,
      ListStorage(),
      filter: (e, filteringMode, sortingMode, end, [data]) {
        if (filteringValue.isEmpty) {
          return (const [], null);
        }

        return (
          e.where(
            (e) =>
                e.name.contains(filteringValue) ||
                e.tag.startsWith(filteringValue),
          ),
          null
        );
      },
    );

    subscr = widget.filteringEvents.stream.listen((str) {
      setState(() {
        filteringValue = str;

        filter.clearRefresh();
      });
    });
  }

  @override
  void dispose() {
    filter.destroy();
    subscr.cancel();

    super.dispose();
  }

  bool _toBlur(Directory cell) {
    for (final booru in Booru.values) {
      if (booru.url == cell.name) {
        return false;
      }
    }

    if (cell.tag.isNotEmpty) {
      return widget.blurMap.containsKey(cell.tag);
    }

    return widget.blurMap[cell.name.split(" ").first.toLowerCase()] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: FadingPanelLabel(
            horizontalPadding: const EdgeInsets.symmetric(horizontal: 18),
            label: l10n.directoriesHint,
          ),
        ),
        if (filter.count == 0)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18) +
                const EdgeInsets.only(left: 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                l10n.startInputingText,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18 + 4),
            sliver: SliverGrid.builder(
              itemCount: filter.count,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: GridAspectRatio.zeroSeven.value,
              ),
              itemBuilder: (context, index) {
                final cell = filter.forIdxUnsafe(index);

                return CustomGridCellWrapper(
                  onPressed: (context) {
                    Navigator.pop(context);

                    widget.onDirectoryPressed(cell);
                  },
                  child: GridCell(
                    data: cell,
                    blur: _toBlur(cell),
                    hideTitle: false,
                    imageAlign: Alignment.topCenter,
                    overrideDescription: const CellStaticData(
                      titleAtBottom: true,
                      titleLines: 2,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
