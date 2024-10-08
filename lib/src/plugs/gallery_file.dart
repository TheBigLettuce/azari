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
  List<NavigationAction> appBarButtons(BuildContext context) {
    final res = ParsedFilenameResult.fromFilename(name).maybeValue();

    return [
      if (res != null)
        NavigationAction(Icons.public, () {
          launchUrl(
            res.booru.browserLink(res.id),
            mode: LaunchMode.externalApplication,
          );
        }),
      NavigationAction(
        Icons.share,
        () => PlatformApi.current().shareMedia(originalUri),
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
    final toShowDelete = DeleteDialogShowNotifier.of(context);

    final buttonProgress =
        GlobalProgressTab.maybeOf(context)?.favoritePostButton();

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
                  Icons.favorite_border_rounded,
                  res == null || buttonProgress == null
                      ? null
                      : (selected) {
                          if (db.favoritePosts.contains(res!.$1, res!.$2)) {
                            db.favoritePosts.backingStorage.removeAll([res!]);

                            return;
                          }

                          if (buttonProgress.value != null) {
                            return;
                          }

                          buttonProgress.value = () async {
                            final client =
                                BooruAPI.defaultClientForBooru(res!.$2);
                            final api = BooruAPI.fromEnum(
                              res!.$2,
                              client,
                              PageSaver.noPersist(),
                            );

                            try {
                              final ret = await api.singlePost(res!.$1);

                              db.favoritePosts.backingStorage.add(
                                FavoritePost(
                                  id: ret.id,
                                  md5: ret.md5,
                                  tags: ret.tags,
                                  width: ret.width,
                                  height: ret.height,
                                  fileUrl: ret.fileUrl,
                                  previewUrl: ret.previewUrl,
                                  sampleUrl: ret.sampleUrl,
                                  sourceUrl: ret.sourceUrl,
                                  rating: ret.rating,
                                  score: ret.score,
                                  createdAt: ret.createdAt,
                                  booru: ret.booru,
                                  type: ret.type,
                                ),
                              );
                            } catch (e, trace) {
                              Logger.root
                                  .warning("favoritePostButton", e, trace);
                            } finally {
                              buttonProgress.value = null;
                              client.close(force: true);
                            }
                          }();
                        },
                  longLoadingNotifier: buttonProgress,
                  watch: res == null
                      ? null
                      : (f, [bool fire = false]) {
                          return db.favoritePosts
                              .streamSingle(res!.$1, res!.$2, fire)
                              .map<(IconData?, Color?, bool?)>((e) {
                            return (
                              e
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              e ? Colors.red.shade900 : null,
                              !e
                            );
                          }).listen(f);
                        },
                ),
                ImageViewAction(
                  Icons.delete,
                  (selected) {
                    deleteFilesDialog(
                      context,
                      [this],
                      toShowDelete,
                    );
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
                      db.localTags,
                      api.parent,
                      toShowDelete,
                    );
                  },
                ),
                ImageViewAction(
                  Icons.forward_rounded,
                  (selected) async {
                    return moveOrCopyFnc(
                      context,
                      api.directories.length == 1
                          ? api.directories.first.bucketId
                          : "",
                      [this],
                      true,
                      tagManager,
                      db.localTags,
                      api.parent,
                      toShowDelete,
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

    final filteringData = FilteringData.maybeOf(context);

    if (excludeDuplicate) {
      final stickers = <Sticker>[
        ...defaultStickersFile(context, this, db.localTags),
        if (filteringData != null &&
            (filteringData.sortingMode == SortingMode.size ||
                filteringData.filteringMode == FilteringMode.same))
          Sticker(Icons.square_foot_rounded, subtitle: kbMbSize(context, size)),
      ];

      return stickers.isEmpty ? const [] : stickers;
    }

    return [
      ...defaultStickersFile(context, this, db.localTags),
      if (res != null && db.favoritePosts.contains(res!.$1, res!.$2))
        const Sticker(Icons.favorite_rounded, important: true),
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
      null,
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
        .map(
          (e) => ImageTag(
            e,
            favorite: tagManager.pinned.exists(e),
            excluded: tagManager.excluded.exists(e),
          ),
        )
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

extension FavoritePostsGlobalProgress on GlobalProgressTab {
  ValueNotifier<Future<void>?> favoritePostButton() =>
      get("favoritePostButton", () => ValueNotifier(null));
}

class FileBase {
  const FileBase({
    required this.tags,
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
    required this.res,
  });

  final int id;
  final String bucketId;

  final String name;

  final int lastModified;
  final String originalUri;

  final int height;
  final int width;

  final int size;

  final bool isVideo;
  final bool isGif;

  final Map<String, void> tags;
  final bool isDuplicate;

  final (int, Booru)? res;
}

class GalleryFileInfo extends StatefulWidget {
  const GalleryFileInfo({super.key, required this.file});

  final GalleryFile file;

  @override
  State<GalleryFileInfo> createState() => _GalleryFileInfoState();
}

class _GalleryFileInfoState extends State<GalleryFileInfo> {
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

  @override
  Widget build(BuildContext context) {
    final filename = file.name;
    final res = ImageTagsNotifier.resOf(context);

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tagManager = TagManager.of(context);
    final settings = SettingsService.db().current;

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          sliver: TagsRibbon(
            emptyWidget: res == null
                ? const SliverPadding(padding: EdgeInsets.zero)
                : LoadTags(
                    filename: filename,
                    res: res,
                  ),
            selectTag: (str, controller) {
              HapticFeedback.mediumImpact();

              Navigator.pop(context);

              radioDialog<SafeMode>(
                context,
                SafeMode.values.map(
                  (e) => (e, e.translatedString(l10n)),
                ),
                settings.safeMode,
                (s) {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) {
                        return BooruRestoredPage(
                          booru: settings.selectedBooru,
                          tags: str,
                          saveSelectedPage: (e) {},
                          overrideSafeMode: s ?? settings.safeMode,
                          db: DatabaseConnectionNotifier.of(context),
                        );
                      },
                    ),
                  );
                },
                title: l10n.chooseSafeMode,
                allowSingle: true,
              );
              _launchGrid(context, str);
            },
            tagManager: TagManager.of(context),
            showPin: false,
            items: (tag, controller) => [
              PopupMenuItem(
                onTap: () {
                  if (tagManager.pinned.exists(tag)) {
                    tagManager.pinned.delete(tag);
                  } else {
                    tagManager.pinned.add(tag);
                  }

                  ImageViewInfoTilesRefreshNotifier.refreshOf(context);

                  controller.animateTo(
                    0,
                    duration: Durations.medium3,
                    curve: Easing.standard,
                  );
                },
                child: Text(
                  tagManager.pinned.exists(tag) ? l10n.unpinTag : l10n.pinTag,
                ),
              ),
              launchGridSafeModeItem(
                context,
                tag,
                _launchGrid,
                l10n,
              ),
              PopupMenuItem(
                onTap: () {
                  if (tagManager.excluded.exists(tag)) {
                    tagManager.excluded.delete(tag);
                  } else {
                    tagManager.excluded.add(tag);
                  }
                },
                child: Text(
                  tagManager.excluded.exists(tag)
                      ? l10n.removeFromExcluded
                      : l10n.addToExcluded,
                ),
              ),
            ],
          ),
        ),
        SliverList.list(
          children: [
            MenuWrapper(
              title: filename,
              child: addInfoTile(
                title: filename,
                subtitle: null,
                onPressed: plug.temporary
                    ? null
                    : () {
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
                                        ParsedFilenameResult.fromFilename(
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
              ),
            ),
            DimensionsRow(
              l10n: l10n,
              width: file.width,
              height: file.height,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Wrap(
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  if (res != null)
                    RedownloadButton(
                      key: file.uniqueKey(),
                      file: file,
                      res: res,
                    ),
                  if (!file.isVideo && !file.isGif)
                    SetWallpaperButton(id: file.id),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 2,
              ),
              child: Text.rich(
                TextSpan(
                  text: kbMbSize(context, file.size),
                  children: [
                    TextSpan(
                      text: "\n${l10n.date(
                        DateTime.fromMillisecondsSinceEpoch(
                          file.lastModified * 1000,
                        ),
                      )}",
                    ),
                  ],
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(
                      0.7,
                    ),
                  ),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class RedownloadButton extends StatefulWidget {
  const RedownloadButton({
    super.key,
    required this.file,
    required this.res,
  });

  final GalleryFile file;
  final ParsedFilenameResult? res;

  @override
  State<RedownloadButton> createState() => _RedownloadButtonState();
}

class _RedownloadButtonState extends State<RedownloadButton> {
  ValueNotifier<Future<void>?>? notifier;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (notifier == null) {
      notifier = GlobalProgressTab.maybeOf(context)?.redownloadFiles();

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
    final l10n = AppLocalizations.of(context)!;

    return TextButton.icon(
      onPressed: notifier == null || notifier?.value != null
          ? null
          : () {
              redownloadFiles(context, [widget.file]);
            },
      label: Text(l10n.redownloadLabel),
      icon: const Icon(
        Icons.download_outlined,
        size: 18,
      ),
    );
  }
}

extension RedownloadFilesGlobalNotifier on GlobalProgressTab {
  ValueNotifier<Future<void>?> redownloadFiles() {
    return get("redownloadFiles", () => ValueNotifier(null));
  }
}

Future<void> redownloadFiles(BuildContext context, List<GalleryFile> files) {
  final l10n = AppLocalizations.of(context)!;

  final notifier = GlobalProgressTab.maybeOf(context)?.redownloadFiles();
  if (notifier == null) {
    return Future.value();
  } else if (notifier.value != null) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(l10n.redownloadInProgress),
      ),
    );

    return Future.value();
  }

  final downloadManager = DownloadManager.of(context);
  final postTags = PostTags.fromContext(context);

  final clients = <Booru, Dio>{};
  final apis = <Booru, BooruAPI>{};

  final notif = chooseNotificationPlug().newProgress(
    id: NotificationPlug.redownloadFilesId,
    title: l10n.redownloadFetchingUrls,
    group: NotificationGroup.misc,
    channel: NotificationChannel.misc,
    body: l10n.redownloadRedowloadingFiles(files.length),
  );

  return notifier.value = Future(() async {
    final progress = await notif;
    progress.setTotal(files.length);

    final posts = <Post>[];
    final actualFiles = <GalleryFile>[];

    for (final (index, file) in files.indexed) {
      progress.update(index, "$index / ${files.length}");

      final res = ParsedFilenameResult.fromFilename(file.name).maybeValue();
      if (res == null) {
        continue;
      }

      final dio = clients.putIfAbsent(
        res.booru,
        () => BooruAPI.defaultClientForBooru(res.booru),
      );
      final api = apis.putIfAbsent(
        res.booru,
        () => BooruAPI.fromEnum(res.booru, dio, PageSaver.noPersist()),
      );

      try {
        posts.add(await api.singlePost(res.id));
        actualFiles.add(file);
      } catch (e, trace) {
        Logger.root.warning("RedownloadTile", e, trace);
      }
    }

    GalleryManagementApi.current().files.deleteAll(actualFiles);

    posts.downloadAll(downloadManager, postTags);
  }).whenComplete(() {
    for (final client in clients.values) {
      client.close();
    }

    notif.then((v) {
      v.done();
    });

    notifier.value = null;
  });
}

class SetWallpaperButton extends StatefulWidget {
  const SetWallpaperButton({
    super.key,
    required this.id,
  });

  final int id;

  @override
  State<SetWallpaperButton> createState() => _SetWallpaperButtonState();
}

class _SetWallpaperButtonState extends State<SetWallpaperButton> {
  Future<void>? _status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextButton.icon(
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
      icon: const Icon(
        Icons.wallpaper_rounded,
        size: 18,
      ),
    );
  }
}
