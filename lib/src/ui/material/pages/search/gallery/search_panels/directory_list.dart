// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../gallery_search_page.dart";

class _DirectoryList extends StatefulWidget {
  const _DirectoryList({
    // super.key,
    required this.filteringEvents,
    required this.source,
    required this.searchController,
    required this.onDirectoryPressed,
  });

  final StreamController<String> filteringEvents;
  final TextEditingController searchController;

  final ResourceSource<int, Directory> source;

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
      filter: (e, filteringMode, sortingMode, colors, end, data) {
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
      return DirectoryMetadataService.safe()?.cache.get(cell.tag)?.blur ??
          false;
    }

    return DirectoryMetadataService.safe()
            ?.cache
            .get(cell.name.split(" ").first.toLowerCase())
            ?.blur ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
    final theme = Theme.of(context);

    final textTheme = theme.textTheme.titleMedium?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );

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
                style: textTheme,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18 + 4),
            sliver: SliverGrid.builder(
              itemCount: filter.count,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final cell = filter.forIdxUnsafe(index);

                return _DirectoryCell(
                  directory: cell,
                  toBlur: _toBlur(cell),
                  onDirectoryPressed: widget.onDirectoryPressed,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _DirectoryCell extends StatelessWidget {
  const _DirectoryCell({
    // super.key,
    required this.directory,
    required this.toBlur,
    required this.onDirectoryPressed,
  });

  final bool toBlur;

  final Directory directory;
  final void Function(Directory) onDirectoryPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final textTheme = theme.textTheme.labelLarge
        ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.8));

    return Column(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => onDirectoryPressed(directory),
            customBorder: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            child: Card(
              // margin: description.tightMode ? const EdgeInsets.all(0.5) : null,
              elevation: 0,
              color: theme.cardColor.withValues(alpha: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              clipBehavior: Clip.antiAlias,
              child: GridCellImage(
                imageAlign: Alignment.topCenter,
                thumbnail: directory.thumbnail(),
                blur: toBlur,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              directory.name,
              style: textTheme,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
