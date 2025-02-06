// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "gallery_api.dart";

class FlutterGalleryDataImpl
    implements
        FlutterGalleryData,
        ImageViewStateController,
        GalleryVideoEvents {
  FlutterGalleryDataImpl({
    required this.source,
    required this.wrapNotifiers,
    required this.watchTags,
    required this.tags,
    required this.db,
  }) {
    _events = source.backingStorage.watch((_) {
      if (Platform.isAndroid) {
        PlatformGalleryEvents().metadataChanged();
      }
      _indexChanges.add(currentIndex);
    });
  }

  final NotifierWrapper? wrapNotifiers;
  final WatchTagsCallback? watchTags;

  final VideoSettingsService db;

  final List<ImageTag> Function(ContentWidgets)? tags;

  late final StreamSubscription<void> _events;
  final _indexChanges = StreamController<int>.broadcast();
  final _videoChanges = StreamController<_VideoPlayerEvent>.broadcast();

  @override
  int currentIndex = 0;

  @override
  int get count => source.count;

  final ResourceSource<int, File> source;

  @override
  Stream<int> get countEvents => source.backingStorage.countEvents;

  @override
  Stream<int> get indexEvents => _indexChanges.stream;

  @override
  Future<DirectoryFile> atIndex(int index) =>
      Future.value(source.forIdxUnsafe(index).toDirectoryFile());

  @override
  Future<GalleryMetadata> metadata() =>
      Future.value(GalleryMetadata(count: source.count));

  @override
  void setCurrentIndex(int index) {
    currentIndex = index;
    _indexChanges.add(index);
  }

  void dispose() {
    _events.cancel();
    _indexChanges.close();
    _videoChanges.close();
  }

  @override
  void bind(
    BuildContext context, {
    required int startingIndex,
    required VoidCallback playAnimationLeft,
    required VoidCallback playAnimationRight,
    required VoidCallback flipShowAppBar,
  }) {
    currentIndex = startingIndex;
    _indexChanges.add(currentIndex);
  }

  @override
  void seekTo(int i) {
    PlatformGalleryEvents().seekToIndex(i);
  }

  @override
  void unbind() {}

  @override
  Widget buildBody(BuildContext context) {
    return _ImageViewBodyPlatformView(
      videoEvents: _videoChanges.stream,
      controls: VideoControlsNotifier.of(context),
      startingCell: currentIndex,
      db: DbConn.of(context),
    );
  }

  @override
  Widget injectMetadataProvider(Widget child) {
    final ret = ImageViewTagsProvider(
      currentPage: indexEvents,
      currentCell: () => (source.forIdxUnsafe(currentIndex), currentIndex),
      tags: tags,
      watchTags: watchTags,
      child: _FileMetadataProvider(
        indexEvents: indexEvents,
        currentIndex: currentIndex,
        currentCount: count,
        countEvents: countEvents,
        wrapNotifiers: wrapNotifiers,
        source: source,
        child: child,
      ),
    );

    if (wrapNotifiers == null) {
      return ret;
    }

    return wrapNotifiers!(ret);
  }

  @override
  void refreshImage() {}

  @override
  void durationEvent(int duration) {
    _videoChanges.add(_DurationEvent(duration));
  }

  @override
  void playbackStateEvent(VideoPlaybackState state) {
    _videoChanges.add(_PlaybackStateEvent(state));
  }

  @override
  void volumeEvent(double volume) {
    _videoChanges.add(_VolumeEvent(volume));
  }

  @override
  void progressEvent(int progress) {
    _videoChanges.add(_ProgressEvent(progress));
  }

  @override
  void loopingEvent(bool looping) {
    _videoChanges.add(_LoopingEvent(looping));
  }

  @override
  Future<double?> initialVolume() => Future.value(db.current.volume);
}

sealed class _VideoPlayerEvent {
  const _VideoPlayerEvent();
}

class _VolumeEvent implements _VideoPlayerEvent {
  const _VolumeEvent(this.volume);

  final double volume;
}

class _DurationEvent implements _VideoPlayerEvent {
  const _DurationEvent(this.duration);

  final int duration;
}

class _PlaybackStateEvent implements _VideoPlayerEvent {
  const _PlaybackStateEvent(this.state);

  final VideoPlaybackState state;
}

class _ProgressEvent implements _VideoPlayerEvent {
  const _ProgressEvent(this.duration);

  final int duration;
}

class _LoopingEvent implements _VideoPlayerEvent {
  const _LoopingEvent(this.looping);

  final bool looping;
}

class _FileMetadataProvider extends StatefulWidget {
  const _FileMetadataProvider({
    // super.key,
    required this.currentIndex,
    required this.indexEvents,
    required this.source,
    required this.wrapNotifiers,
    required this.currentCount,
    required this.countEvents,
    required this.child,
  });

  final int currentIndex;
  final int currentCount;

  final ResourceSource<int, File> source;

  final Stream<int> indexEvents;
  final Stream<int> countEvents;

  final NotifierWrapper? wrapNotifiers;

  final Widget child;

  @override
  State<_FileMetadataProvider> createState() => __FileMetadataProviderState();
}

class __FileMetadataProviderState extends State<_FileMetadataProvider> {
  late final StreamSubscription<int> _eventsIndex;
  late final StreamSubscription<int> _eventsCount;

  late _FileToMetadata metadata;
  int refreshTimes = 0;

  @override
  void initState() {
    super.initState();

    metadata = _FileToMetadata(
      file: widget.source.forIdxUnsafe(widget.currentIndex),
      index: widget.currentIndex,
      count: widget.currentCount,
      wrapNotifiers: widget.wrapNotifiers,
    );

    _eventsIndex = widget.indexEvents.listen((newIndex) {
      metadata = _FileToMetadata(
        file: widget.source.forIdxUnsafe(newIndex),
        count: metadata.count,
        index: newIndex,
        wrapNotifiers: widget.wrapNotifiers,
      );

      refreshTimes += 1;

      setState(() {});
    });

    _eventsCount = widget.countEvents.listen((newCount) {
      metadata = _FileToMetadata(
        file: metadata.file,
        index: metadata.index,
        count: newCount,
        wrapNotifiers: widget.wrapNotifiers,
      );

      refreshTimes += 1;

      setState(() {});
    });
  }

  @override
  void dispose() {
    _eventsIndex.cancel();
    _eventsCount.cancel();

    super.dispose();
  }

  ImageProvider _getThumbnail(int i) =>
      widget.source.forIdxUnsafe(i).thumbnail(null);

  @override
  Widget build(BuildContext context) {
    return ThumbnailsNotifier(
      provider: _getThumbnail,
      child: CurrentIndexMetadataNotifier(
        metadata: metadata,
        refreshTimes: refreshTimes,
        child: widget.child,
      ),
    );
  }
}

class _FileToMetadata implements CurrentIndexMetadata {
  const _FileToMetadata({
    required this.file,
    required this.index,
    required this.wrapNotifiers,
    required this.count,
  });

  final NotifierWrapper? wrapNotifiers;
  final File file;

  @override
  final int index;

  @override
  final int count;

  @override
  bool get isVideo => file.isVideo;

  @override
  Key get uniqueKey => file.uniqueKey();

  @override
  List<ImageViewAction> actions(BuildContext context) => file.actions(context);

  @override
  List<NavigationAction> appBarButtons(BuildContext context) =>
      file.appBarButtons(context);

  @override
  Widget? openMenuButton(BuildContext context) {
    return ImageViewFab(
      openBottomSheet: (context) {
        return showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (sheetContext) {
            final child = ExitOnPressRoute(
              exit: () {
                Navigator.of(sheetContext).pop();
                ExitOnPressRoute.exitOf(context);
              },
              child: PauseVideoNotifierHolder(
                state: PauseVideoNotifier.stateOf(context),
                child: ImageTagsNotifier(
                  tags: ImageTagsNotifier.of(context),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 8,
                      bottom: MediaQuery.viewPaddingOf(context).bottom + 12,
                    ),
                    child: SizedBox(
                      width: MediaQuery.sizeOf(sheetContext).width,
                      child: file.info(context),
                    ),
                  ),
                ),
              ),
            );

            if (wrapNotifiers != null) {
              return wrapNotifiers!(child);
            }

            return child;
          },
        );
      },
    );
  }

  @override
  List<Sticker> stickers(BuildContext context) => file.stickers(context, true);
}

class _ImageViewBodyPlatformView extends StatefulWidget {
  const _ImageViewBodyPlatformView({
    // super.key,
    required this.controls,
    required this.startingCell,
    required this.videoEvents,
    required this.db,
  });

  final Stream<_VideoPlayerEvent> videoEvents;
  final VideoControlsController controls;
  final int startingCell;

  final DbConn db;

  @override
  State<_ImageViewBodyPlatformView> createState() =>
      __ImageViewBodyPlatformViewState();
}

class __ImageViewBodyPlatformViewState
    extends State<_ImageViewBodyPlatformView> {
  late final StreamSubscription<_VideoPlayerEvent> events;
  late final StreamSubscription<VideoControlsEvent> controlsEvents;

  @override
  void initState() {
    super.initState();

    final galleryEvents = PlatformGalleryEvents();

    controlsEvents = widget.controls.events.listen(
      (e) => switch (e) {
        VolumeButton() => galleryEvents.volumeButtonPressed(null),
        FullscreenButton() => null,
        PlayButton() => galleryEvents.playButtonPressed(),
        LoopingButton() => galleryEvents.loopingButtonPressed(),
        AddDuration() =>
          galleryEvents.durationChanged(e.durationSeconds.ceil() * 1000),
      },
    );

    events = widget.videoEvents.listen(
      (e) {
        return switch (e) {
          _VolumeEvent() => widget.controls.setVolume(e.volume),
          _DurationEvent() =>
            widget.controls.setDuration(Duration(milliseconds: e.duration)),
          _ProgressEvent() =>
            widget.controls.setProgress(Duration(milliseconds: e.duration)),
          _LoopingEvent() => widget.db.videoSettings
              .add(widget.db.videoSettings.current.copy(looping: e.looping)),
          _PlaybackStateEvent() => widget.controls.setPlayState(
              switch (e.state) {
                VideoPlaybackState.stopped => PlayState.stopped,
                VideoPlaybackState.playing => PlayState.isPlaying,
                VideoPlaybackState.buffering => PlayState.buffering,
              },
            ),
        };
      },
    );
  }

  @override
  void dispose() {
    events.cancel();
    controlsEvents.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: PlatformViewLink(
          viewType: "gallery",
          surfaceFactory: (context, controller) {
            return AndroidViewSurface(
              controller: controller as AndroidViewController,
              hitTestBehavior: PlatformViewHitTestBehavior.translucent,
              gestureRecognizers: {
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
            );
          },
          onCreatePlatformView: (params) {
            return PlatformViewsService.initExpensiveAndroidView(
              id: params.id,
              viewType: params.viewType,
              creationParams: {
                "id": widget.startingCell,
              },
              creationParamsCodec: const StandardMessageCodec(),
              layoutDirection: TextDirection.ltr,
            )
              ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
              ..create();
          },
        ),
      ),
    );
  }
}

extension FileToDirectoryFileExt on File {
  DirectoryFile toDirectoryFile() => DirectoryFile(
        id: id,
        bucketId: bucketId,
        bucketName: name,
        name: name,
        originalUri: originalUri,
        lastModified: lastModified,
        height: height,
        width: width,
        size: size,
        isVideo: isVideo,
        isGif: isGif,
      );
}

abstract class File
    implements
        CellBase,
        ContentWidgets,
        SelectionWrapperBuilder,
        Pressable<File>,
        Thumbnailable,
        Infoable,
        ImageViewActionable,
        AppBarButtonable,
        Stickerable {
  const File({
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

  @override
  Widget buildSelectionWrapper<T extends CellBase>({
    required BuildContext context,
    required int thisIndx,
    required List<int>? selectFrom,
    required GridSelection<T>? selection,
    required CellStaticData description,
    required GridFunctionality<T> functionality,
    required VoidCallback? onPressed,
    required Widget child,
  }) {
    return WrapSelection(
      thisIndx: thisIndx,
      description: description,
      selectFrom: selectFrom,
      selection: selection,
      functionality: functionality,
      onPressed: onPressed,
      child: child,
    );
  }

  @override
  Widget buildCell<T extends CellBase>(
    BuildContext context,
    int idx,
    T cell, {
    required bool isList,
    required bool hideTitle,
    bool animated = false,
    bool blur = false,
    required Alignment imageAlign,
    required Widget Function(Widget child) wrapSelection,
  }) =>
      _FileCell(
        file: this,
        isList: isList,
        hideTitle: hideTitle,
        animated: animated,
        blur: blur,
        imageAlign: imageAlign,
        wrapSelection: wrapSelection,
      );

  @override
  CellStaticData description() => const CellStaticData(
        tightMode: true,
      );

  @override
  String alias(bool isList) => name;

  @override
  List<NavigationAction> appBarButtons(BuildContext context) {
    final l10n = context.l10n();

    return [
      if (res != null)
        NavigationAction(
          Icons.public,
          () {
            launchUrl(
              res!.$2.browserLink(res!.$1),
              mode: LaunchMode.externalApplication,
            );
          },
          l10n.openOnBooru(res!.$2.string),
        ),
      NavigationAction(
        Icons.share,
        () => PlatformApi().shareMedia(originalUri),
        l10n.shareLabel,
      ),
    ];
  }

  @override
  Widget info(BuildContext context) => GalleryFileInfo(
        key: uniqueKey(),
        file: this,
        tags: ImageTagsNotifier.of(context),
      );

  @override
  List<ImageViewAction> actions(BuildContext context) {
    final api = FilesDataNotifier.maybeOf(context);
    final db = DbConn.of(context);
    final tagManager = TagManager.of(context);

    final buttonProgress =
        GlobalProgressTab.maybeOf(context)?.favoritePostButton();

    final favoriteAction = ImageViewAction(
      Icons.favorite_border_rounded,
      res == null || buttonProgress == null
          ? null
          : (selected) {
              if (db.favoritePosts.cache.isFavorite(res!.$1, res!.$2)) {
                db.favoritePosts.removeAll([res!]);

                return;
              }

              if (buttonProgress.value != null) {
                return;
              }

              buttonProgress.value = () async {
                final client = BooruAPI.defaultClientForBooru(res!.$2);
                final api = BooruAPI.fromEnum(
                  res!.$2,
                  client,
                );

                try {
                  final ret = await api.singlePost(res!.$1);

                  db.favoritePosts.addAll([
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
                      size: ret.size,
                    ),
                  ]);
                } catch (e, trace) {
                  Logger.root.warning("favoritePostButton", e, trace);
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
              return db.favoritePosts.cache
                  .streamSingle(res!.$1, res!.$2, fire)
                  .map<(IconData?, Color?, bool?)>((e) {
                return (
                  e ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  e ? Colors.red.shade900 : null,
                  !e
                );
              }).listen(f);
            },
    );

    final callback = ReturnFileCallbackNotifier.maybeOf(context);

    if (callback != null) {
      return <ImageViewAction>[
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
      ];
    }

    if (api == null) {
      return <ImageViewAction>[
        favoriteAction,
      ];
    }

    final toShowDelete =
        DeleteDialogShowNotifier.maybeOf(context) ?? DeleteDialogShow();

    return api.type.isTrash()
        ? <ImageViewAction>[
            ImageViewAction(
              Icons.restore_from_trash,
              (selected) {
                GalleryApi().trash.removeAll(
                  [originalUri],
                );
              },
            ),
          ]
        : <ImageViewAction>[
            favoriteAction,
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
                AppBarVisibilityNotifier.maybeToggleOf(context, true);

                return moveOrCopyFnc(
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
                AppBarVisibilityNotifier.maybeToggleOf(context, true);

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
  ImageProvider<Object> thumbnail(BuildContext? context) =>
      GalleryThumbnailProvider(
        id,
        isVideo,
        // PinnedThumbnailService.db(),
        ThumbnailService.db(),
      );

  @override
  Key uniqueKey() => ValueKey(id);

  @override
  List<Sticker> stickers(BuildContext context, bool excludeDuplicate) {
    final db = DbConn.of(context);

    final filteringData = ChainedFilter.maybeOf(context);

    if (excludeDuplicate) {
      final stickers = <Sticker>[
        ...defaultStickersFile(context, this, db.localTags),
        if (filteringData != null &&
            (filteringData.sortingMode == SortingMode.size ||
                filteringData.filteringMode == FilteringMode.same)) ...[
          Sticker(Icons.square_foot_rounded, subtitle: kbMbSize(context, size)),
          if (res != null)
            Sticker(Icons.arrow_outward_rounded, subtitle: res!.$2.string),
        ],
      ];

      return stickers.isEmpty ? const [] : stickers;
    }

    return [
      ...defaultStickersFile(context, this, db.localTags),
      if (res != null && db.favoritePosts.cache.isFavorite(res!.$1, res!.$2))
        const Sticker(Icons.favorite_rounded, important: true),
    ];
  }

  @override
  void onPress(
    BuildContext context,
    GridFunctionality<File> functionality,
    int idx,
  ) {
    final db = DbConn.of(context);
    final tagManager = TagManager.of(context);

    final impl = FlutterGalleryDataImpl(
      source: functionality.source,
      wrapNotifiers: functionality.registerNotifiers,
      watchTags: (c, f) => watchTags(c, f, db.localTags, tagManager),
      tags: (c) => imageTags(c, db.localTags, tagManager),
      db: db.videoSettings,
    );

    FlutterGalleryData.setUp(impl);
    GalleryVideoEvents.setUp(impl);

    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (context) {
          return ImageView(
            startingIndex: idx,
            stateController: impl,
          );
        },
      ),
    ).whenComplete(() {
      impl.dispose();
      FlutterGalleryData.setUp(null);
      GalleryVideoEvents.setUp(null);
    });
  }

  static List<ImageTag> imageTags(
    ContentWidgets c,
    LocalTagsService localTags,
    TagManager tagManager,
  ) {
    final postTags = localTags.get(c.alias(false));
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

  static StreamSubscription<List<ImageTag>> watchTags(
    ContentWidgets c,
    void Function(List<ImageTag> l) f,
    LocalTagsService localTags,
    TagManager tagManager,
  ) =>
      tagManager.pinned.watchImageLocal(c.alias(false), f, localTag: localTags);
}

extension FavoritePostsGlobalProgress on GlobalProgressTab {
  ValueNotifier<Future<void>?> favoritePostButton() =>
      get("favoritePostButton", () => ValueNotifier(null));
}

class GalleryFileInfo extends StatefulWidget {
  const GalleryFileInfo({
    super.key,
    required this.file,
    required this.tags,
  });

  final File file;
  final ImageViewTags tags;

  @override
  State<GalleryFileInfo> createState() => _GalleryFileInfoState();
}

class _GalleryFileInfoState extends State<GalleryFileInfo> {
  File get file => widget.file;
  ImageViewTags get tags => widget.tags;

  late final StreamSubscription<void> events;

  bool hasTranslation = false;

  final filesExtended = MiscSettingsService.db().current.filesExtendedActions;

  @override
  void initState() {
    super.initState();

    if (tags.list.indexWhere((e) => e.tag == "translated") != -1) {
      hasTranslation = true;
    }

    events = widget.tags.stream.listen((_) {
      if (tags.list.indexWhere((e) => e.tag == "translated") != -1) {
        hasTranslation = true;
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    events.cancel();

    super.dispose();
  }

  void _launchGrid(BuildContext context, String t, [SafeMode? safeMode]) {
    OnBooruTagPressed.pressOf(
      context,
      t,
      tags.res!.booru,
      overrideSafeMode: safeMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filename = file.name;

    final l10n = context.l10n();
    final tagManager = TagManager.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: TagsRibbon(
            tagNotifier: ImageTagsNotifier.of(context),
            sliver: false,
            emptyWidget: tags.res == null
                ? const Padding(padding: EdgeInsets.zero)
                : LoadTags(
                    filename: filename,
                    res: tags.res!,
                  ),
            selectTag: !GlobalProgressTab.presentInScope(context)
                ? null
                : (str, controller) {
                    HapticFeedback.mediumImpact();

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
              if (GlobalProgressTab.presentInScope(context))
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
        ListBody(
          children: [
            DimensionsName(
              l10n: l10n,
              width: file.width,
              height: file.height,
              name: file.name,
              icon: file.isVideo
                  ? const Icon(Icons.slideshow_outlined)
                  : const Icon(Icons.photo_outlined),
              onTap: () {
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

                            final res = ParsedFilenameResult.fromFilename(
                              value,
                            );
                            if (res.hasError) {
                              return res.asError(l10n);
                            }

                            return null;
                          },
                          onFieldSubmitted: (value) {
                            GalleryApi().files.rename(file.originalUri, value);

                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                );
              },
              onLongTap: () {
                Clipboard.setData(ClipboardData(text: file.name));
              },
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
            ),
            if (file.res != null) FileBooruInfoTile(res: file.res!),
            FileInfoTile(file: file),
            const Padding(padding: EdgeInsets.only(top: 4)),
            const Divider(indent: 24, endIndent: 24),
            FileActionChips(
              file: file,
              tags: tags,
              hasTranslation: hasTranslation,
            ),
          ],
        ),
      ],
    );
  }
}

class FileBooruInfoTile extends StatelessWidget {
  const FileBooruInfoTile({
    super.key,
    required this.res,
  });

  final (int, Booru) res;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasNotifiers = GlobalProgressTab.presentInScope(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListTile(
        onTap: !hasNotifiers
            ? null
            : () {
                Navigator.pop(context);

                Post.imageViewSingle(context, res.$2, res.$1);
              },
        tileColor: theme.colorScheme.surfaceContainerHigh,
        leading: const Icon(Icons.description_outlined),
        title: Text(res.$2.string),
        subtitle: Text(res.$1.toString()),
      ),
    );
  }
}

class FileInfoTile extends StatelessWidget {
  const FileInfoTile({
    super.key,
    required this.file,
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(15),
        bottomRight: Radius.circular(15),
      ),
    ),
  });

  final File file;

  final ShapeBorder shape;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListTile(
        shape: shape,
        tileColor: theme.colorScheme.surfaceContainerHigh,
        leading: const Icon(Icons.description_outlined),
        title: Text(kbMbSize(context, file.size)),
        subtitle: Text(
          l10n.date(
            DateTime.fromMillisecondsSinceEpoch(
              file.lastModified * 1000,
            ),
          ),
        ),
      ),
    );
  }
}

class FileActionChips extends StatelessWidget {
  const FileActionChips({
    super.key,
    required this.file,
    required this.tags,
    required this.hasTranslation,
  });

  final bool hasTranslation;

  final File file;
  final ImageViewTags tags;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (tags.res != null)
            RedownloadChip(
              key: file.uniqueKey(),
              file: file,
              res: tags.res,
            ),
          if (!file.isVideo && !file.isGif) SetWallpaperChip(id: file.id),
          if (tags.res != null && hasTranslation)
            TranslationNotesChip(
              postId: tags.res!.id,
              booru: tags.res!.booru,
            ),
        ],
      ),
    );
  }
}

class RedownloadChip extends StatefulWidget {
  const RedownloadChip({
    super.key,
    required this.file,
    required this.res,
  });

  final File file;
  final ParsedFilenameResult? res;

  @override
  State<RedownloadChip> createState() => _RedownloadChipState();
}

class _RedownloadChipState extends State<RedownloadChip> {
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
    final l10n = context.l10n();

    return ActionChip(
      onPressed: notifier == null || notifier?.value != null
          ? null
          : () {
              redownloadFiles(context, [widget.file]);
            },
      label: Text(l10n.redownloadLabel),
      avatar: const Icon(
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

Future<void> redownloadFiles(BuildContext context, List<File> files) {
  final l10n = context.l10n();

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

  final notif = NotificationApi().show(
    id: NotificationApi.redownloadFilesId,
    title: l10n.redownloadFetchingUrls,
    group: NotificationGroup.misc,
    channel: NotificationChannel.misc,
    body: l10n.redownloadRedowloadingFiles(files.length),
  );

  return notifier.value = Future(() async {
    final progress = await notif;
    progress.setTotal(files.length);

    final posts = <Post>[];
    final actualFiles = <File>[];

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
        () => BooruAPI.fromEnum(res.booru, dio),
      );

      try {
        posts.add(await api.singlePost(res.id));
        actualFiles.add(file);
      } catch (e, trace) {
        Logger.root.warning("RedownloadTile", e, trace);
      }
    }

    GalleryApi().files.deleteAll(actualFiles);

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

class SetWallpaperChip extends StatefulWidget {
  const SetWallpaperChip({
    super.key,
    required this.id,
  });

  final int id;

  @override
  State<SetWallpaperChip> createState() => _SetWallpaperChipState();
}

class _SetWallpaperChipState extends State<SetWallpaperChip> {
  Future<void>? _status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return ActionChip(
      onPressed: _status != null
          ? null
          : () {
              _status =
                  PlatformApi().setWallpaper(widget.id).onError((e, trace) {
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
              child: CircularProgressIndicator(
                strokeWidth: 2,
                year2023: false,
              ),
            )
          : Text(l10n.setAsWallpaper),
      avatar: const Icon(
        Icons.wallpaper_rounded,
        size: 18,
      ),
    );
  }
}

class _FileCell extends StatelessWidget {
  const _FileCell({
    // super.key,
    required this.file,
    required this.isList,
    required this.hideTitle,
    required this.animated,
    required this.blur,
    required this.imageAlign,
    required this.wrapSelection,
  });

  final File file;

  final bool isList;
  final bool hideTitle;
  final bool animated;
  final bool blur;
  final Alignment imageAlign;
  final Widget Function(Widget child) wrapSelection;

  @override
  Widget build(BuildContext context) {
    final description = file.description();
    final alias = hideTitle ? "" : file.alias(isList);

    final stickers =
        description.ignoreStickers ? null : file.stickers(context, false);
    final thumbnail = file.thumbnail(context);

    final theme = Theme.of(context);

    final filteringData = ChainedFilter.maybeOf(context);

    Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Card(
            margin: description.tightMode ? const EdgeInsets.all(0.5) : null,
            elevation: 0,
            color: theme.cardColor.withValues(alpha: 0),
            child: ClipPath(
              clipper: ShapeBorderClipper(
                shape: description.circle
                    ? const CircleBorder()
                    : RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
              ),
              child: wrapSelection(
                Stack(
                  children: [
                    GridCellImage(
                      imageAlign: imageAlign,
                      thumbnail: thumbnail,
                      blur: blur,
                    ),
                    if (stickers != null && stickers.isNotEmpty)
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.end,
                            direction: Axis.vertical,
                            children: stickers.map(StickerWidget.new).toList(),
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: VideoGifRow(
                          isVideo: file.isVideo,
                          isGif: file.isGif,
                        ),
                      ),
                    ),
                    if (alias.isNotEmpty)
                      GridCellName(
                        title: alias,
                        lines: description.titleLines,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (filteringData != null &&
            (filteringData.filteringMode == FilteringMode.tag ||
                filteringData.filteringMode == FilteringMode.tagReversed))
          _Tags(
            file: file,
            db: DbConn.of(context),
          ),
      ],
    );

    if (animated) {
      child = child.animate(key: file.uniqueKey()).fadeIn();
    }

    return child;
  }
}

class _Tags extends StatefulWidget {
  const _Tags({
    // super.key,
    required this.file,
    required this.db,
  });

  final File file;

  final DbConn db;

  @override
  State<_Tags> createState() => __TagsState();
}

class __TagsState extends State<_Tags> with PinnedSortedTagsArrayMixin {
  @override
  List<String> postTags = const [];

  @override
  void initState() {
    super.initState();

    final res = widget.file.res;
    if (res != null) {
      postTags = widget.db.localTags.get(widget.file.name);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.file.res;

    if (res == null || postTags.isEmpty) {
      return const SizedBox.shrink();
    }

    final (id, booru) = res;

    return SizedBox(
      height: 21,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ListView.builder(
          clipBehavior: Clip.antiAlias,
          scrollDirection: Axis.horizontal,
          itemCount: tags.length,
          itemBuilder: (context, index) {
            final e = tags[index];

            return OutlinedTagChip(
              tag: e.tag,
              letterCount: 8,
              isPinned: e.pinned,
              onLongPressed: () {
                context.openSafeModeDialog((safeMode) {
                  OnBooruTagPressed.pressOf(
                    context,
                    e.tag,
                    booru,
                    overrideSafeMode: safeMode,
                  );
                });
              },
              onPressed: () => OnBooruTagPressed.pressOf(
                context,
                e.tag,
                booru,
              ),
            );
          },
        ),
      ),
    );
  }
}
