// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "gallery.dart";

mixin GalleryFile
    implements
        FileBase,
        ContentableCell,
        ContentWidgets,
        Pressable<GalleryFile>,
        Thumbnailable,
        Infoable,
        ImageViewActionable,
        AppBarButtonable,
        Stickerable {
  @override
  CellStaticData description() => const CellStaticData(
        tightMode: true,
      );

  @override
  String alias(bool isList) => name;

  @override
  List<Widget> appBarButtons(BuildContext context) {
    final res = DisassembleResult.fromFilename(name).maybeValue();

    return [
      if (res != null)
        IconButton(
          onPressed: () {
            launchUrl(
              res.booru.browserLink(res.id),
              mode: LaunchMode.externalApplication,
            );
          },
          icon: const Icon(Icons.public),
        ),
      IconButton(
        onPressed: () => PlatformApi.current().shareMedia(originalUri),
        icon: const Icon(Icons.share),
      ),
    ];
  }

  @override
  Widget info(BuildContext context) => GalleryFileInfo(file: this);

  @override
  List<ImageViewAction> actions(BuildContext context) {
    final (api, callback) = FilesDataNotifier.of(context);
    final db = DatabaseConnectionNotifier.of(context);
    final tagManager = TagManager.of(context);

    return callback != null
        ? <ImageViewAction>[
            ImageViewAction(
              Icons.check,
              (selected) {
                callback(this);
                if (callback.returnBack) {
                  Navigator.of(context)
                    ..pop(context)
                    ..pop(context)
                    ..pop(context);
                }
              },
            ),
          ]
        : api.type.isTrash()
            ? <ImageViewAction>[
                ImageViewAction(
                  Icons.restore_from_trash,
                  (selected) {
                    GalleryManagementApi.current().trash.removeAll(
                      [originalUri],
                    );
                  },
                ),
              ]
            : <ImageViewAction>[
                ImageViewAction(
                  Icons.star_border_rounded,
                  (selected) {
                    favoriteOrUnfavorite(
                      context,
                      [this],
                      db.favoriteFiles,
                    );
                  },
                  animate: true,
                  watch: (f, [bool fire = false]) {
                    return db.favoriteFiles
                        .streamSingle(id, fire)
                        .map<(IconData?, Color?, bool?)>((e) {
                      return (
                        e ? Icons.star_rounded : Icons.star_border_rounded,
                        e ? Colors.yellow.shade900 : null,
                        !e
                      );
                    }).listen(f);
                  },
                ),
                ImageViewAction(
                  Icons.delete,
                  (selected) {
                    deleteFilesDialog(context, [this]);
                  },
                ),
                ImageViewAction(
                  Icons.copy,
                  (selected) {
                    moveOrCopyFnc(
                      context,
                      api.directories.length == 1
                          ? api.directories.first.bucketId
                          : "",
                      [this],
                      false,
                      tagManager,
                      db.favoriteFiles,
                      db.localTags,
                      api.parent,
                    );
                  },
                ),
                ImageViewAction(
                  Icons.forward_rounded,
                  (selected) {
                    moveOrCopyFnc(
                      context,
                      api.directories.length == 1
                          ? api.directories.first.bucketId
                          : "",
                      [this],
                      true,
                      tagManager,
                      db.favoriteFiles,
                      db.localTags,
                      api.parent,
                    );
                  },
                ),
              ];
  }

  @override
  Contentable content() {
    final size = Size(width.toDouble(), height.toDouble());

    if (isVideo) {
      return AndroidVideo(
        this,
        uri: originalUri,
        size: size,
      );
    }

    if (isGif) {
      return AndroidGif(
        this,
        uri: originalUri,
        size: size,
      );
    }

    return AndroidImage(
      this,
      uri: originalUri,
      size: size,
    );
  }

  @override
  ImageProvider<Object> thumbnail() => GalleryThumbnailProvider(
        id,
        isVideo,
        PinnedThumbnailService.db(),
        ThumbnailService.db(),
      );

  @override
  Key uniqueKey() => ValueKey(id);

  @override
  List<Sticker> stickers(BuildContext context, bool excludeDuplicate) {
    final db = DatabaseConnectionNotifier.of(context);

    if (excludeDuplicate) {
      final stickers = <Sticker>[
        ...defaultStickersFile(context, this, db.localTags),
      ];

      return stickers.isEmpty ? const [] : stickers;
    }

    return [
      ...defaultStickersFile(context, this, db.localTags),
      if (db.favoriteFiles.cachedValues.containsKey(id))
        const Sticker(Icons.star_rounded, important: true),
    ];
  }

  @override
  void onPress(
    BuildContext context,
    GridFunctionality<GalleryFile> functionality,
    GalleryFile cell,
    int idx,
  ) {
    final db = DatabaseConnectionNotifier.of(context);
    final tagManager = TagManager.of(context);

    ImageView.defaultForGrid<GalleryFile>(
      context,
      functionality,
      ImageViewDescription(
        statistics: StatisticsGalleryService.asImageViewStatistics(),
      ),
      idx,
      (c) => _tags(c, db.localTags, tagManager),
      (c, f) => _watchTags(c, f, db.localTags, tagManager),
    );
  }

  List<ImageTag> _tags(
    Contentable c,
    LocalTagsService localTags,
    TagManager tagManager,
  ) {
    final postTags = localTags.get(c.widgets.alias(false));
    if (postTags.isEmpty) {
      return const [];
    }

    return postTags
        .map((e) => ImageTag(e, tagManager.pinned.exists(e)))
        .toList();
  }

  StreamSubscription<List<ImageTag>> _watchTags(
    Contentable c,
    void Function(List<ImageTag> l) f,
    LocalTagsService localTags,
    TagManager tagManager,
  ) =>
      tagManager.pinned
          .watchImageLocal(c.widgets.alias(false), f, localTag: localTags);
}

class FileBase {
  const FileBase({
    required this.tagsFlat,
    required this.id,
    required this.bucketId,
    required this.name,
    required this.isVideo,
    required this.isGif,
    required this.size,
    required this.height,
    required this.isDuplicate,
    required this.width,
    required this.lastModified,
    required this.originalUri,
  });

  @Index(unique: true)
  final int id;
  final String bucketId;
  @Index()
  final String name;
  @Index()
  final int lastModified;
  final String originalUri;

  final int height;
  final int width;

  @Index()
  final int size;

  final bool isVideo;
  final bool isGif;

  final String tagsFlat;
  final bool isDuplicate;
}

class GalleryFileInfo extends StatefulWidget {
  const GalleryFileInfo({super.key, required this.file});

  final GalleryFile file;

  @override
  State<GalleryFileInfo> createState() => _GalleryFileInfoState();
}

class _GalleryFileInfoState extends State<GalleryFileInfo> {
  int currentPage = 0;

  GalleryFile get file => widget.file;

  final filesExtended = MiscSettingsService.db().current.filesExtendedActions;

  final plug = chooseGalleryPlug();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _launchGrid(BuildContext context, String t, [SafeMode? safeMode]) {
    OnBooruTagPressed.pressOf(
      context,
      t,
      ImageTagsNotifier.resOf(context)!.booru,
      overrideSafeMode: safeMode,
    );
  }

  int currentPageF() => currentPage;

  void setPage(int i) {
    setState(() {
      currentPage = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filename = file.name;
    final res = ImageTagsNotifier.resOf(context);

    final l10n = AppLocalizations.of(context)!;

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(left: 16),
          sliver: LabelSwitcherWidget(
            pages: [
              PageLabel(l10n.infoHeadline),
              PageLabel(
                l10n.tagsInfoPage,
                count: ImageTagsNotifier.of(context).length,
              ),
            ],
            currentPage: currentPageF,
            switchPage: setPage,
            sliver: true,
            noHorizontalPadding: true,
          ),
        ),
        if (currentPage == 0)
          SliverList.list(
            children: [
              MenuWrapper(
                title: filename,
                child: addInfoTile(
                  title: l10n.nameTitle,
                  subtitle: filename,
                  trailing: plug.temporary
                      ? null
                      : IconButton(
                          onPressed: () {
                            Navigator.push<void>(
                              context,
                              DialogRoute(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(l10n.enterNewNameTitle),
                                    content: TextFormField(
                                      autofocus: true,
                                      initialValue: filename,
                                      autovalidateMode: AutovalidateMode.always,
                                      decoration: const InputDecoration(
                                        errorMaxLines: 2,
                                      ),
                                      validator: (value) {
                                        if (value == null) {
                                          return l10n.valueIsNull;
                                        }

                                        final res =
                                            DisassembleResult.fromFilename(
                                          value,
                                        );
                                        if (res.hasError) {
                                          return res.asError(l10n);
                                        }

                                        return null;
                                      },
                                      onFieldSubmitted: (value) {
                                        GalleryManagementApi.current()
                                            .files
                                            .rename(file.originalUri, value);

                                        Navigator.pop(context);
                                      },
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit),
                        ),
                ),
              ),
              addInfoTile(
                title: l10n.dateModified,
                subtitle: l10n.date(
                  DateTime.fromMillisecondsSinceEpoch(file.lastModified * 1000),
                ),
              ),
              addInfoTile(
                title: l10n.widthInfoPage,
                subtitle: l10n.pixels(file.width),
              ),
              addInfoTile(
                title: l10n.heightInfoPage,
                subtitle: l10n.pixels(file.height),
              ),
              addInfoTile(
                title: l10n.sizeInfoPage,
                subtitle: kbMbSize(context, file.size),
              ),
              if (res != null)
                RedownloadTile(key: file.uniqueKey(), file: file, res: res),
              if (!file.isVideo && !file.isGif) SetWallpaperTile(id: file.id),
            ],
          )
        else if (res != null) ...[
          SliverPadding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton.filledTonal(
                    onPressed: () {
                      final notifier =
                          GlobalProgressTab.maybeOf(context)?.loadTags();
                      final db =
                          DatabaseConnectionNotifier.of(context).localTags;

                      db.delete(filename);

                      notifier?.value = Future(() {})
                          .whenComplete(() => notifier.value = null);
                    },
                    icon: const Icon(Icons.delete_rounded),
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                  ),
                  IconButton.filledTonal(
                    onPressed: () {
                      final db =
                          DatabaseConnectionNotifier.of(context).localTags;

                      openAddTagDialog(
                        context,
                        (v, delete) {
                          if (delete) {
                            db.removeSingle([filename], v);
                          } else {
                            db.addMultiple([filename], v);
                          }
                        },
                        l10n,
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SearchTextField(
              filename,
              key: ValueKey(filename),
            ),
          ),
          TagsListWidget(
            key: ValueKey(filename),
            filename,
            res: res,
            launchGrid: _launchGrid,
            addRemoveTag: true,
            db: TagManager.of(context),
          ),
        ] else
          const SliverToBoxAdapter(
            child: EmptyWidget(
              gridSeed: 2,
            ),
          ),
      ],
    );
  }
}

class RedownloadTile extends StatefulWidget {
  const RedownloadTile({super.key, required this.file, required this.res});

  final GalleryFile file;
  final DisassembleResult? res;

  @override
  State<RedownloadTile> createState() => _RedownloadTileState();
}

class _RedownloadTileState extends State<RedownloadTile> {
  ValueNotifier<Future<void>?>? notifier;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (notifier == null) {
      notifier = GlobalProgressTab.maybeOf(context)
          ?.get<Future<void>?>("redownloadTile", () => ValueNotifier(null));

      notifier?.addListener(listener);
    }
  }

  void listener() {
    setState(() {});
  }

  @override
  void dispose() {
    notifier?.removeListener(listener);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.res;
    final l10n = AppLocalizations.of(context)!;

    return RawChip(
      isEnabled: notifier != null && notifier?.value == null,
      onPressed: notifier == null || notifier?.value != null
          ? null
          : () {
              final dio = BooruAPI.defaultClientForBooru(res!.booru);
              final api =
                  BooruAPI.fromEnum(res.booru, dio, PageSaver.noPersist());

              final downloadManager = DownloadManager.of(context);
              final postTags = PostTags.fromContext(context);

              notifier?.value = api.singlePost(res.id).then((post) {
                GalleryManagementApi.current().files.deleteAll([widget.file]);

                post.download(downloadManager, postTags);

                return null;
              }).onError((e, trace) {
                Logger.root.warning("RedownloadTile", e, trace);

                return null;
              }).whenComplete(() {
                dio.close(force: true);
                notifier?.value = null;
              });
            },
      avatar: const Icon(Icons.download_outlined),
      label: Text(l10n.redownloadLabel),
    );
  }
}

class SetWallpaperTile extends StatefulWidget {
  const SetWallpaperTile({
    super.key,
    required this.id,
  });

  final int id;

  @override
  State<SetWallpaperTile> createState() => _SetWallpaperTileState();
}

class _SetWallpaperTileState extends State<SetWallpaperTile> {
  Future<void>? _status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: RawChip(
        avatar: const Icon(Icons.wallpaper_rounded),
        onPressed: _status != null
            ? null
            : () {
                _status = PlatformApi.current()
                    .setWallpaper(widget.id)
                    .onError((e, trace) {
                  Logger.root.warning("setWallpaper", e, trace);
                }).whenComplete(() {
                  _status = null;

                  setState(() {});
                });

                setState(() {});
              },
        label: _status != null
            ? const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(l10n.setAsWallpaper),
      ),
    );
  }
}
