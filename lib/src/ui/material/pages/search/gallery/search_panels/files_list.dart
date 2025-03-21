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
    required this.localTags,
    required this.tagManager,
    required this.videoSettings,
    required this.galleryService,
  });

  final StreamController<String> filteringEvents;
  final TextEditingController searchController;

  final LocalTagsService? localTags;
  final TagManagerService? tagManager;
  final VideoSettingsService? videoSettings;

  final GalleryService galleryService;

  static const size = Size(160 / 1.3, 160);
  static const listPadding = EdgeInsets.symmetric(horizontal: 18 + 4);

  @override
  State<_FilesList> createState() => __FilesListState();
}

class __FilesListState extends State<_FilesList> {
  LocalTagsService? get localTags => widget.localTags;
  TagManagerService? get tagManager => widget.tagManager;
  VideoSettingsService? get videoSettings => widget.videoSettings;

  late final GenericListSource<File> fileSource;

  late _FilesLoadingStatus search;

  late final StreamSubscription<String> subscr;
  late final StreamSubscription<void> refreshingEvents;

  late final PigeonGalleryDataImpl impl;

  @override
  void initState() {
    super.initState();

    fileSource = GenericListSource(
      () {
        if (search.str.isEmpty) {
          return Future.value(const []);
        }

        return widget.galleryService.search.filesByName(search.str, 30);
      },
    );

    search = _FilesLoadingStatus(fileSource);

    impl = PigeonGalleryDataImpl(
      source: search.source,
      wrapNotifiers: (child) => ReturnFileCallbackNotifier(
        callback: null,
        child: child,
      ),
      watchTags: localTags != null && tagManager != null
          ? (c, f) => FileImpl.watchTags(
                c,
                f,
                localTags!,
                tagManager!.pinned,
              )
          : null,
      tags: localTags != null && tagManager != null
          ? (c) => FileImpl.imageTags(
                c,
                localTags!,
                tagManager!,
              )
          : null,
      videoSettings: videoSettings,
    );

    refreshingEvents = fileSource.progress.watch((_) {
      setState(() {});
    });

    subscr = widget.filteringEvents.stream.listen((str) {
      setState(() {
        if (search.str == str || fileSource.progress.inRefreshing) {
          return;
        }

        search = _FilesLoadingStatus(fileSource)..str = str;
        fileSource.clearRefresh();
      });
    });

    FlutterGalleryData.setUp(impl);
    GalleryVideoEvents.setUp(impl);
  }

  @override
  void dispose() {
    FlutterGalleryData.setUp(null);
    GalleryVideoEvents.setUp(null);

    impl.dispose();

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
                    search: search,
                    impl: impl,
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
    required this.impl,
  });

  final int idx;

  final _FilesLoadingStatus search;
  final PigeonGalleryDataImpl impl;
  final File file;

  void onPressed(BuildContext context) {
    final db = Services.of(context);

    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (context) {
          return ImageView(
            startingIndex: idx,
            stateController: impl,
            videoSettingsService: db.get<VideoSettingsService>(),
            galleryService: db.get<GalleryService>(),
            settingsService: db.require<SettingsService>(),
          );
        },
      ),
    );
  }

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
                thumbnail: file.thumbnail(context),
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
