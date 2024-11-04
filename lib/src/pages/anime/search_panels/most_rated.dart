// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../search_page.dart";

class _MostRatedList extends StatefulWidget {
  const _MostRatedList({
    super.key,
    required this.filteringEvents,
    required this.api,
    required this.searchController,
  });

  final StreamController<String> filteringEvents;
  final TextEditingController searchController;

  final AnimeAPI api;

  static const size = Size(160 / 1.5, 160);
  static const listPadding = EdgeInsets.symmetric(horizontal: 18 + 4);

  @override
  State<_MostRatedList> createState() => __MostRatedListState();
}

class __MostRatedListState extends State<_MostRatedList> {
  _MostRatedLoadingStatus search = _MostRatedLoadingStatus();

  late final StreamSubscription<String> subscr;

  @override
  void initState() {
    super.initState();

    subscr = widget.filteringEvents.stream.listen((str) {
      if (search.str == str) {
        return;
      }

      _search(str);
    });

    _search("");
  }

  void _search(String str) {
    setState(() {
      search.f?.ignore();

      final newSearch = _MostRatedLoadingStatus()..str = str;
      newSearch.f = widget.api.search(str, 0, null, AnimeSafeMode.safe)
        ..then((e) => newSearch.list = e).whenComplete(
          () => setState(() {
            newSearch.f = null;
          }),
        );

      search = newSearch;
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
    final theme = Theme.of(context);

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: FadingPanelLabel(
            trailing: (
              Icons.keyboard_double_arrow_right_outlined,
              () {
                final copy = search.list.toList();
                final str = search.str;

                Navigator.of(context, rootNavigator: true).push<void>(
                  MaterialPageRoute(
                    builder: (context) => _MostRatedPage(
                      api: widget.api,
                      prefill: copy,
                      searchText: str,
                    ),
                  ),
                );
              },
            ),
            horizontalPadding: const EdgeInsets.symmetric(horizontal: 18),
            label: l10n.mostRatedLabel,
          ),
        ),
        if (search.f != null)
          const SliverToBoxAdapter(
            child: ShimmerPlaceholdersHorizontal(
              childSize: _MostRatedList.size,
              padding: _MostRatedList.listPadding,
            ),
          )
        else
          search.list.isEmpty
              ? SliverPadding(
                  padding: _MostRatedList.listPadding +
                      const EdgeInsets.symmetric(horizontal: 4),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      l10n.startInputingText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                )
              : SliverToBoxAdapter(
                  child: SizedBox(
                    height: _MostRatedList.size.height,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: _MostRatedList.listPadding,
                      itemCount: search.list.length,
                      itemBuilder: (context, index) {
                        final entry = search.list[index];

                        return SizedBox(
                          width: _MostRatedList.size.width,
                          child: CustomGridCellWrapper(
                            onPressed: (context) {
                              entry.openInfoPage(context);
                            },
                            child: GridCell(
                              cell: entry,
                              hideTitle: false,
                              imageAlign: Alignment.topCenter,
                              overrideDescription: const CellStaticData(
                                titleAtBottom: true,
                                titleLines: 3,
                                ignoreStickers: true,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
      ],
    );
  }
}

class _MostRatedLoadingStatus {
  _MostRatedLoadingStatus();

  Future<void>? f;
  List<AnimeSearchEntry> list = const [];
  String str = "";
}

class _MostRatedPage extends StatefulWidget {
  const _MostRatedPage({
    super.key,
    required this.api,
    required this.prefill,
    required this.searchText,
  });

  final String searchText;

  final AnimeAPI api;

  final List<AnimeSearchEntry> prefill;

  @override
  State<_MostRatedPage> createState() => __MostRatedPageState();
}

class __MostRatedPageState extends State<_MostRatedPage> {
  late final GenericListSource<AnimeEntryData> source = GenericListSource(
    () {
      page.page = 0;

      return widget.api.search(
        widget.searchText,
        0,
        null,
        AnimeSafeMode.safe,
      );
    },
    next: () {
      return widget.api
          .search(
        widget.searchText,
        page.page + 1,
        null,
        AnimeSafeMode.safe,
      )
          .then((e) {
        page.page += 1;

        return e;
      });
    },
  );

  final page = PageSaver.noPersist();
  final gridConfig = CancellableWatchableGridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.zeroSeven,
    columns: GridColumn.three,
    layoutType: GridLayoutType.grid,
  );

  @override
  void initState() {
    super.initState();

    source.backingStorage.addAll(widget.prefill, true);
    if (widget.prefill.isNotEmpty) {
      page.page = 1;
    }
  }

  @override
  void dispose() {
    source.destroy();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GridConfiguration(
      watch: gridConfig.watch,
      child: WrapGridPage(
        addScaffold: true,
        child: Builder(
          builder: (context) => GridFrame<AnimeEntryData>(
            key: null,
            slivers: [
              GridLayout(
                source: source.backingStorage,
                progress: source.progress,
                unselectOnUpdate: false,
              ),
              GridConfigPlaceholders(
                progress: source.progress,
                randomNumber: 0,
              ),
            ],
            functionality: GridFunctionality(
              source: source,
              selectionGlue: GlueProvider.generateOf(context)(),
            ),
            description: GridDescription(
              actions: const [],
              gridSeed: 0,
              showLoadingIndicator: false,
              animationsOnSourceWatch: false,
              pageName:
                  "${l10n.mostRatedLabel}${widget.searchText.isNotEmpty ? ' ${widget.searchText}' : ''}",
            ),
          ),
        ),
      ),
    );
  }
}
