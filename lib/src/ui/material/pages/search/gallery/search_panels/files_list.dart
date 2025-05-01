// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../gallery_search_page.dart";

class _FilesList extends StatefulWidget {
  const _FilesList({
    // super.key,
    required this.filteringEvents,
    required this.searchController,
  });

  final StreamController<String> filteringEvents;
  final TextEditingController searchController;

  static const size = Size(160 / 1.3, 160);
  static const listPadding = EdgeInsets.symmetric(horizontal: 18 + 4);

  @override
  State<_FilesList> createState() => __FilesListState();
}

class __FilesListState extends State<_FilesList> with GalleryApi {
  late final GenericListSource<File> fileSource;

  late _FilesLoadingStatus _search;

  late final StreamSubscription<String> subscr;
  late final StreamSubscription<void> refreshingEvents;

  // late final PlatformImageViewStateImpl impl;

  @override
  void initState() {
    super.initState();

    fileSource = GenericListSource(
      () {
        if (_search.str.isEmpty) {
          return Future.value(const []);
        }

        return search.filesByName(_search.str, 30);
      },
    );

    _search = _FilesLoadingStatus(fileSource);

    // impl = PlatformImageViewStateImpl(
    //   source: _search.source,
    //   onTagPressed: (context, tag) => BooruRestoredPage.open(
    //     context,
    //     booru: const SettingsService().current.selectedBooru,
    //     tags: tag,
    //     saveSelectedPage: (_) {},
    //     rootNavigator: true,
    //   ),
    //   onTagLongPressed: (context, tag) {
    //     final l10n = context.l10n();

    //     return radioDialog(
    //       context,
    //       SafeMode.values.map((e) => (e, e.translatedString(l10n))),
    //       const SettingsService().current.safeMode,
    //       (e) => BooruRestoredPage.open(
    //         context,
    //         booru: const SettingsService().current.selectedBooru,
    //         tags: tag,
    //         saveSelectedPage: (_) {},
    //         rootNavigator: true,
    //       ),
    //       title: l10n.chooseSafeMode,
    //     );
    //   },
    //   wrapNotifiers: (child) => child,
    // );

    refreshingEvents = fileSource.progress.watch((_) {
      setState(() {});
    });

    subscr = widget.filteringEvents.stream.listen((str) {
      setState(() {
        if (_search.str == str || fileSource.progress.inRefreshing) {
          return;
        }

        _search = _FilesLoadingStatus(fileSource)..str = str;
        fileSource.clearRefresh();
      });
    });
  }

  @override
  void dispose() {
    // impl.dispose();

    subscr.cancel();
    refreshingEvents.cancel();
    fileSource.destroy();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    if (fileSource.backingStorage.isEmpty) {
      return const SliverPadding(padding: EdgeInsets.zero);
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: FadingPanelLabel(
            horizontalPadding: const EdgeInsets.symmetric(horizontal: 18),
            label: l10n.filesLabel,
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: _FilesList.size.height,
            child: ListView.builder(
              padding: _FilesList.listPadding,
              scrollDirection: Axis.horizontal,
              itemCount: fileSource.count,
              itemBuilder: (context, i) {
                final cell = fileSource.backingStorage[i];

                return SizedBox(
                  width: _FilesList.size.width,
                  child: _FilesCell(
                    file: cell,
                    search: _search,
                    idx: i,
                  ),
                );
              },
            ).animate().fadeIn(),
          ),
        ),
      ],
    );
  }
}

class _FilesLoadingStatus {
  _FilesLoadingStatus(this.source);

  final GenericListSource<File> source;
  String str = "";
}

class _FilesCell extends StatelessWidget {
  const _FilesCell({
    // super.key,
    required this.file,
    required this.search,
    required this.idx,
    // required this.impl,
  });

  final int idx;

  final _FilesLoadingStatus search;
  // final PlatformImageViewStateImpl impl;
  final File file;

  void onPressed(BuildContext context) => GallerySearchPage.openImageView(
        context,
        startingIndex: idx,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final textTheme = theme.textTheme.bodyMedium
        ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.8));

    return Column(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => onPressed(context),
            customBorder: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            child: Card(
              elevation: 0,
              color: theme.cardColor.withValues(alpha: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              clipBehavior: Clip.antiAlias,
              child: GridCellImage(
                imageAlign: Alignment.topCenter,
                thumbnail: file.thumbnail(),
                blur: false,
              ),
            ),
          ),
        ),
        SizedBox(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                file.name,
                style: textTheme,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
