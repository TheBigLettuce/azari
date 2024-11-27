// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../search_page.dart";

class _FilesList extends StatefulWidget {
  const _FilesList({
    // super.key,
    required this.filteringEvents,
    required this.searchController,
    required this.db,
    required this.callback,
  });

  final StreamController<String> filteringEvents;
  final TextEditingController searchController;

  final ReturnFileCallback? callback;

  final DbConn db;

  static const size = Size(160 / 1.3, 160);
  static const listPadding = EdgeInsets.symmetric(horizontal: 18 + 4);

  @override
  State<_FilesList> createState() => __FilesListState();
}

class __FilesListState extends State<_FilesList> {
  _FilesLoadingStatus search = _FilesLoadingStatus();

  late final StreamSubscription<String> subscr;

  @override
  void initState() {
    super.initState();

    subscr = widget.filteringEvents.stream.listen((str) {
      setState(() {
        if (search.str == str) {
          return;
        }

        search.f?.ignore();

        if (str.isEmpty) {
          search = _FilesLoadingStatus();

          return;
        }

        final newSearch = _FilesLoadingStatus()..str = str;
        newSearch.f = GalleryApi().search.filesByName(str, 30)
          ..then(
            (e) => newSearch.files = e,
          ).whenComplete(
            () => setState(() {
              newSearch.f = null;
            }),
          );

        search = newSearch;
      });
    });
  }

  @override
  void dispose() {
    subscr.cancel();

    search.f?.ignore();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if ((search.f == null || search.f != null) && search.files.isEmpty) {
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
              itemCount: search.files.length,
              itemBuilder: (context, i) {
                final cell = search.files[i];

                return CustomGridCellWrapper(
                  onPressed: (context) {
                    ImageView.launchWrapped(
                      context,
                      search.files.length,
                      (i) => search.files[i].content(),
                      imageDesctipion: ImageViewDescription(
                        statistics:
                            StatisticsGalleryService.asImageViewStatistics(),
                      ),
                      startingCell: i,
                      wrapNotifiers: (child) => ReturnFileCallbackNotifier(
                        callback: widget.callback,
                        child: child,
                      ),
                      tags: (c) => File.imageTags(
                        c,
                        widget.db.localTags,
                        widget.db.tagManager,
                      ),
                      watchTags: (c, f) => File.watchTags(
                        c,
                        f,
                        widget.db.localTags,
                        widget.db.tagManager,
                      ),
                    );
                  },
                  child: SizedBox(
                    width: _FilesList.size.width,
                    child: GridCell(
                      data: cell,
                      imageAlign: Alignment.topCenter,
                      hideTitle: false,
                      overrideDescription: const CellStaticData(
                        titleAtBottom: true,
                        titleLines: 3,
                      ),
                    ),
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
  _FilesLoadingStatus();

  Future<void>? f;
  List<File> files = const [];
  String str = "";
}
