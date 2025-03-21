// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/init_main/restart_widget.dart";
import "package:azari/src/platform/gallery_thumbnail_provider.dart";
import "package:azari/src/services/resource_source/chained_filter.dart";
import "package:azari/src/services/resource_source/filtering_mode.dart";
import "package:azari/src/services/resource_source/resource_source.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/ui/material/pages/booru/booru_page.dart";
import "package:azari/src/ui/material/pages/gallery/files.dart";
import "package:azari/src/platform/gallery_api.dart";
import "package:azari/src/platform/gallery_file_functions.dart";
import "package:azari/src/platform/pigeon_gallery_data_impl.dart";
import "package:azari/src/platform/platform_api.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/ui/material/widgets/file_cell.dart";
import "package:azari/src/ui/material/widgets/file_info.dart";
import "package:azari/src/ui/material/widgets/grid_cell/cell.dart";
import "package:azari/src/ui/material/widgets/grid_cell/contentable.dart";
import "package:azari/src/ui/material/widgets/grid_cell/sticker.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/ui/material/widgets/post_info.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:url_launcher/url_launcher.dart" as url;

abstract class FileImpl
    implements
        FileBase,
        CellBase,
        ContentWidgets,
        SelectionWrapperBuilder,
        Thumbnailable,
        Infoable,
        ImageViewActionable,
        AppBarButtonable,
        Stickerable {
  const FileImpl();

  ResourceSource<int, File> getSource(BuildContext context) =>
      ResourceSource.maybeOf<int, File>(context)!;

  @override
  Widget buildSelectionWrapper<T extends CellBase>({
    required BuildContext context,
    required int thisIndx,
    required List<int>? selectFrom,
    required CellStaticData description,
    required VoidCallback? onPressed,
    required Widget child,
  }) {
    return WrapSelection(
      thisIndx: thisIndx,
      description: description,
      selectFrom: selectFrom,
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
  }) {
    final db = Services.of(context);

    return FileCell(
      file: this,
      isList: isList,
      hideTitle: hideTitle,
      animated: animated,
      blur: blur,
      imageAlign: imageAlign,
      wrapSelection: wrapSelection,
      localTags: db.get<LocalTagsService>(),
      settingsService: db.require<SettingsService>(),
    );
  }

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
            url.launchUrl(
              res!.$2.browserLink(res!.$1),
              mode: url.LaunchMode.externalApplication,
            );
          },
          l10n.openOnBooru(res!.$2.string),
        ),
      NavigationAction(
        Icons.share,
        () => PlatformApi().shareMedia(originalUri),
        l10n.shareLabel,
      ),
      if (res != null)
        NavigationAction(
          Icons.star,
          null,
          "",
          StarsButton(
            idBooru: res!,
            favoritePosts: Services.getOf<FavoritePostSourceService>(context),
          ),
        ),
    ];
  }

  @override
  Widget info(BuildContext context) {
    final db = Services.of(context);

    return FileInfo(
      key: uniqueKey(),
      file: this as File,
      tags: ImageTagsNotifier.of(context),
      tagManager: db.get<TagManagerService>(),
      localTags: db.get<LocalTagsService>(),
      settingsService: db.require<SettingsService>(),
      downloadManager: DownloadManager.of(context),
      galleryService: db.get<GalleryService>()!, // should exist at this point
    );
  }

  @override
  List<ImageViewAction> actions(BuildContext context) {
    final api = FilesDataNotifier.maybeOf(context);
    final db = Services.of(context);
    final (favoritePosts, localTags, tagManager) = (
      db.get<FavoritePostSourceService>(),
      db.get<LocalTagsService>(),
      db.get<TagManagerService>(),
    );

    final buttonProgress =
        GlobalProgressTab.maybeOf(context)?.favoritePostButton();

    final favoriteAction = ImageViewAction(
      Icons.favorite_border_rounded,
      res == null || buttonProgress == null || favoritePosts == null
          ? null
          : (selected) {
              if (favoritePosts.cache.isFavorite(res!.$1, res!.$2)) {
                favoritePosts.removeAll([res!]);

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

                  favoritePosts.addAll([
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
                      stars: FavoriteStars.zero,
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
      watch: res == null || favoritePosts == null
          ? null
          : (f, [bool fire = false]) {
              return favoritePosts.cache
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
            callback(this as File);
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

    final galleryService = Services.getOf<GalleryService>(context)!;

    return api.type.isTrash()
        ? <ImageViewAction>[
            ImageViewAction(
              Icons.restore_from_trash,
              (selected) {
                galleryService.trash.removeAll(
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
                  [this as File],
                  toShowDelete,
                  galleryService.trash,
                );
              },
            ),
            if (tagManager != null && localTags != null)
              ImageViewAction(
                Icons.copy,
                (selected) {
                  AppBarVisibilityNotifier.maybeToggleOf(context, true);

                  return moveOrCopyFnc(
                    context,
                    api.directories.length == 1
                        ? api.directories.first.bucketId
                        : "",
                    [this as File],
                    false,
                    api.parent,
                    toShowDelete,
                    tagManager: tagManager,
                    localTags: localTags,
                    galleryService: galleryService,
                  );
                },
              ),
            if (tagManager != null && localTags != null)
              ImageViewAction(
                Icons.forward_rounded,
                (selected) async {
                  AppBarVisibilityNotifier.maybeToggleOf(context, true);

                  return moveOrCopyFnc(
                    context,
                    api.directories.length == 1
                        ? api.directories.first.bucketId
                        : "",
                    [this as File],
                    true,
                    api.parent,
                    toShowDelete,
                    tagManager: tagManager,
                    localTags: localTags,
                    galleryService: galleryService,
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
      );

  @override
  Key uniqueKey() => ValueKey(id);

  @override
  List<Sticker> stickers(BuildContext context, bool excludeDuplicate) {
    final favoritePosts = Services.getOf<FavoritePostSourceService>(context);
    final filteringData = ChainedFilter.maybeOf(context);

    if (excludeDuplicate) {
      final stickers = <Sticker>[
        ...defaultStickersFile(context, this),
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
      ...defaultStickersFile(context, this),
      if (res != null &&
          favoritePosts != null &&
          favoritePosts.cache.isFavorite(res!.$1, res!.$2))
        const Sticker(Icons.favorite_rounded, important: true),
    ];
  }

  static List<ImageTag> imageTags(
    ContentWidgets c,
    LocalTagsService localTags,
    TagManagerService tagManager,
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
    BooruTagging<Pinned> pinnedTags,
  ) =>
      pinnedTags.watchImageLocal(c.alias(false), f, localTag: localTags);
}

mixin PigeonFilePressable implements Pressable<File>, FileImpl {
  @override
  void onPressed(
    BuildContext context,
    int idx,
  ) {
    final api = FilesDataNotifier.maybeOf(context);
    final fnc = OnBooruTagPressed.of(context);
    final callback = ReturnFileCallbackNotifier.maybeOf(context);

    final db = Services.of(context);
    final (
      localTags,
      tagManager,
      videoSettings,
      settingsService,
      galleryService
    ) = (
      db.get<LocalTagsService>(),
      db.get<TagManagerService>(),
      db.get<VideoSettingsService>(),
      db.require<SettingsService>(),
      db.get<GalleryService>()
    );

    final impl = PigeonGalleryDataImpl(
      source: getSource(context),
      wrapNotifiers: (child) {
        Widget child_ = OnBooruTagPressed(
          onPressed: fnc,
          child: child,
        );

        if (api != null) {
          child_ = FilesDataNotifier(
            api: api,
            child: child_,
          );
        }

        if (callback != null) {
          child_ = ReturnFileCallbackNotifier(
            callback: callback,
            child: child_,
          );
        }

        return child_;
      },
      watchTags: localTags != null && tagManager != null
          ? (c, f) => FileImpl.watchTags(c, f, localTags, tagManager.pinned)
          : null,
      tags: localTags != null && tagManager != null
          ? (c) => FileImpl.imageTags(c, localTags, tagManager)
          : null,
      videoSettings: videoSettings,
    );

    FlutterGalleryData.setUp(impl);
    GalleryVideoEvents.setUp(impl);

    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (context) {
          return ImageView(
            startingIndex: idx,
            stateController: impl,
            videoSettingsService: videoSettings,
            settingsService: settingsService,
            galleryService: galleryService,
          );
        },
      ),
    ).whenComplete(() {
      impl.dispose();
      FlutterGalleryData.setUp(null);
      GalleryVideoEvents.setUp(null);
    });
  }
}
