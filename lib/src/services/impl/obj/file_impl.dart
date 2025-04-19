// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/generated/platform/platform_api.g.dart" as platform;
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/resource_source/chained_filter.dart";
import "package:azari/src/logic/resource_source/filtering_mode.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/impl/io/pigeon_gallery_data_impl.dart";
import "package:azari/src/services/impl/io/platform_thumbnail_provider.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/booru/booru_page.dart";
import "package:azari/src/ui/material/pages/booru/booru_restored_page.dart";
import "package:azari/src/ui/material/pages/gallery/files.dart";
import "package:azari/src/ui/material/pages/other/settings/radio_dialog.dart";
import "package:azari/src/ui/material/widgets/file_cell.dart";
import "package:azari/src/ui/material/widgets/file_info.dart";
import "package:azari/src/ui/material/widgets/grid_cell/cell.dart";
import "package:azari/src/ui/material/widgets/grid_cell/sticker.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/ui/material/widgets/post_info.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:url_launcher/url_launcher.dart" as url;

abstract class FileImpl
    with CellBuilderData, FileImageViewWidgets
    implements FileBase, CellBuilder, ImageViewWidgets {
  const FileImpl();

  ResourceSource<int, File> getSource(BuildContext context) =>
      ResourceSource.maybeOf<int, File>(context)!;

  @override
  Key uniqueKey() => ValueKey(id);

  @override
  ImageProvider<Object> thumbnail() => PlatformThumbnailProvider(id);

  @override
  String title(AppLocalizations l10n) => name;

  @override
  List<Sticker> stickers(
    BuildContext context, [
    bool includeDuplicate = true,
  ]) {
    final favoritePosts = FavoritePostSourceService.safe();
    final filteringData = ChainedFilter.maybeOf(context);

    if (includeDuplicate) {
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

  @override
  Widget buildCell(
    AppLocalizations l10n, {
    required CellType cellType,
    required bool hideName,
    Alignment imageAlign = Alignment.center,
  }) =>
      FileCell(
        key: uniqueKey(),
        file: this,
        isList: cellType == CellType.list,
        hideName: hideName,
        imageAlign: imageAlign,
      );

  // static List<ImageTag> imageTags(BuildContext context, String filename) {
  //   final postTags = const LocalTagsService().get(filename);
  //   if (postTags.isEmpty) {
  //     return const [];
  //   }

  //   final onBooruTagPressed = OnBooruTagPressed.of(context);
  //   final booru = const SettingsService().current.selectedBooru;

  //   return postTags
  //       .map(
  //         (e) => ImageTag(
  //           e,
  //           type: const TagManagerService().pinned.exists(e)
  //               ? ImageTagType.favorite
  //               : const TagManagerService().excluded.exists(e)
  //                   ? ImageTagType.excluded
  //                   : ImageTagType.normal,
  //           onTap: () => onBooruTagPressed(context, booru, e, null),
  //           onLongTap: () => onBooruTagPressed(context, booru, e, null),
  //         ),
  //       )
  //       .toList();
  // }

  Future<void> openImage(BuildContext context) {
    final thisIdx = ThisIndex.of(context);
    final providedState = FlutterGalleryDataNotifier.maybeOf(context);
    if (providedState != null) {
      return ImageView.open(context, providedState, startingCell: thisIdx.$1);
    }

    final stateController = PlatformImageViewStateImpl(
      source: getSource(context),
      wrapNotifiers: (child) => child,
      onTagLongPressed: (context, tag) => BooruRestoredPage.open(
        context,
        booru: const SettingsService().current.selectedBooru,
        tags: tag,
        saveSelectedPage: (_) {},
        rootNavigator: true,
      ),
      onTagPressed: (context, tag) {
        final l10n = context.l10n();

        return radioDialog(
          context,
          SafeMode.values.map((e) => (e, e.translatedString(l10n))),
          const SettingsService().current.safeMode,
          (e) => BooruRestoredPage.open(
            context,
            booru: const SettingsService().current.selectedBooru,
            tags: tag,
            saveSelectedPage: (_) {},
            rootNavigator: true,
            overrideSafeMode: e,
          ),
          title: l10n.chooseSafeMode,
        );
      },
    );

    platform.FlutterGalleryData.setUp(stateController);
    platform.GalleryVideoEvents.setUp(stateController);

    return ImageView.open(context, stateController, startingCell: thisIdx.$1)
        .whenComplete(() {
      stateController.dispose();

      platform.FlutterGalleryData.setUp(null);
      platform.GalleryVideoEvents.setUp(null);
    });
  }
}

List<Sticker> defaultStickersFile(
  BuildContext? context,
  FileImpl file,
) {
  return [
    if (file.tags.containsKey("original")) Sticker(FilteringMode.original.icon),
    if (file.isDuplicate) Sticker(FilteringMode.duplicate.icon),
    if (file.tags.containsKey("translated"))
      const Sticker(Icons.translate_outlined),
  ];
}

Sticker sizeSticker(int size) {
  if (size == 0) {
    return const Sticker(IconData(0x4B));
  }

  final kb = size / 1000;
  if (kb < 1000) {
    if (kb > 500) {
      return const Sticker(IconData(0x4B));
    } else {
      return const Sticker(IconData(0x6B));
    }
  } else {
    final mb = kb / 1000;
    if (mb > 2) {
      return const Sticker(IconData(0x4D));
    } else {
      return const Sticker(IconData(0x6D));
    }
  }
}

String kbMbSize(BuildContext context, int bytes) {
  if (bytes == 0) {
    return "0";
  }
  final res = bytes / 1000;
  if (res > 1000) {
    return context.l10n().megabytes(res / 1000);
  }

  return context.l10n().kilobytes(res);
}

mixin FileImageViewWidgets implements ImageViewWidgets, FileBase {
  @override
  bool videoContent() => isVideo;

  @override
  List<Widget> appBarButtons(BuildContext context) {
    return [
      if (res != null && FavoritePostSourceService.available)
        StarsButton(idBooru: res!),
      IconButton(
        icon: const Icon(Icons.share),
        onPressed: () => const AppApi().shareMedia(originalUri),
      ),
      if (res != null)
        IconButton(
          onPressed: () {
            url.launchUrl(
              res!.$2.browserLink(res!.$1),
              mode: url.LaunchMode.externalApplication,
            );
          },
          icon: const Icon(Icons.public),
        ),
    ];
  }

  @override
  Future<void> Function(BuildContext context) openInfo() {
    return (context) {
      final imageTags = ImageTagsNotifier.of(context);
      final onBooruTagPressed = OnBooruTagPressed.maybeOf(context) ??
          (
            BuildContext context,
            Booru booru,
            String tag,
            SafeMode? safeMode,
          ) {
            BooruRestoredPage.open(
              context,
              booru: booru,
              tags: tag,
              saveSelectedPage: (_) {},
              overrideSafeMode: safeMode,
              rootNavigator: true,
            );
          };

      void exit() => ExitOnPressRoute.maybeExitOf(context);

      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => OnBooruTagPressed(
          onPressed: onBooruTagPressed,
          child: ExitOnPressRoute(
            exit: exit,
            child: FileInfo(
              key: uniqueKey(),
              file: this as File,
              tags: imageTags,
            ),
          ),
        ),
      );
    };
  }

  @override
  List<ImageViewAction> actions(BuildContext context) {
    final api = FilesDataNotifier.maybeOf(context);

    final favoriteAction = ImageViewAction(
      Icons.favorite_border_rounded,
      res != null && FavoritePostSourceService.available
          ? () {
              if (const FavoritePostSourceService()
                  .cache
                  .isFavorite(res!.$1, res!.$2)) {
                const FavoritePostSourceService().removeAll([res!]);

                return;
              }

              const TasksService().add<FavoritePostSourceService>(
                () async {
                  final client = BooruAPI.defaultClientForBooru(res!.$2);
                  final api = BooruAPI.fromEnum(
                    res!.$2,
                    client,
                  );

                  try {
                    final ret = await api.singlePost(res!.$1);

                    const FavoritePostSourceService().addAll([
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
                        filteringColors: FilteringColors.noColor,
                      ),
                    ]);
                  } catch (e, trace) {
                    Logger.root.warning("favoritePostButton", e, trace);
                  } finally {
                    client.close(force: true);
                  }
                },
              );
            }
          : null,
      watch: res != null && FavoritePostSourceService.available
          ? (f, [bool fire = false]) {
              return const FavoritePostSourceService()
                  .cache
                  .streamSingle(res!.$1, res!.$2, fire)
                  .map<(IconData?, Color?, bool?)>((e) {
                return (
                  e ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  e ? Colors.red.shade900 : null,
                  !e
                );
              }).listen(f);
            }
          : null,
      taskTag: FavoritePostSourceService,
    );

    final callback = ReturnFileCallbackNotifier.maybeOf(context);

    if (callback != null) {
      return <ImageViewAction>[
        ImageViewAction(
          Icons.check,
          () {
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

    return api.type.isTrash()
        ? <ImageViewAction>[
            ImageViewAction(
              Icons.restore_from_trash,
              () {
                const GalleryService().trash.removeAll([originalUri]);
              },
            ),
          ]
        : <ImageViewAction>[
            favoriteAction,
            ImageViewAction(
              Icons.delete,
              () {
                deleteFilesDialog(
                  context,
                  [this as File],
                  toShowDelete,
                );
              },
            ),
            if (TagManagerService.available && LocalTagsService.available)
              ImageViewAction(
                Icons.copy,
                () {
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
                  );
                },
              ),
            if (TagManagerService.available && LocalTagsService.available)
              ImageViewAction(
                Icons.forward_rounded,
                () async {
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
                  );
                },
              ),
          ];
  }
}

// mixin PigeonFilePressable implements Pressable<File>, FileImpl {
//   @override
//   void onPressed(
//     BuildContext context,
//     int idx,
//   ) {
//     final api = FilesDataNotifier.maybeOf(context);
//     final fnc = OnBooruTagPressed.of(context);
//     final callback = ReturnFileCallbackNotifier.maybeOf(context);

//     final impl = PlatformImageViewStateImpl(
//       source: getSource(context),
//       wrapNotifiers: (child) {
//         Widget child_ = OnBooruTagPressed(
//           onPressed: fnc,
//           child: child,
//         );

//         if (api != null) {
//           child_ = FilesDataNotifier(
//             api: api,
//             child: child_,
//           );
//         }

//         if (callback != null) {
//           child_ = ReturnFileCallbackNotifier(
//             callback: callback,
//             child: child_,
//           );
//         }

//         return child_;
//       },
//       watchTags: LocalTagsService.available && TagManagerService.available
//           ? FileImpl.watchTags
//           : null,
//       tags: LocalTagsService.available && TagManagerService.available
//           ? FileImpl.imageTags
//           : null,
//     );

//     platform.FlutterGalleryData.setUp(impl);
//     platform.GalleryVideoEvents.setUp(impl);

//     Navigator.of(context, rootNavigator: true).push<void>(
//       MaterialPageRoute(
//         builder: (context) {
//           return ImageView(
//             startingIndex: idx,
//             stateController: impl,
//           );
//         },
//       ),
//     ).whenComplete(() {
//       impl.dispose();
//       platform.FlutterGalleryData.setUp(null);
//       platform.GalleryVideoEvents.setUp(null);
//     });
//   }
// }


  // @override
  // Widget buildSelectionWrapper<T extends CellBuilder>({
  //   required BuildContext context,
  //   required int thisIndx,
  //   required List<int>? selectFrom,
  //   required CellBuilderData description,
  //   required VoidCallback? onPressed,
  //   required Widget child,
  // }) =>
    


// Future<void> loadNetworkThumb(
//   BuildContext context,
//   String filename,
//   int id,
//   ThumbnailService thumbnails,
//   PinnedThumbnailService pinnedThumbnails, [
//   bool addToPinned = true,
// ]) {
//   final notifier = GlobalProgressTab.maybeOf(context)
//       ?.get("loadNetworkThumb", () => ValueNotifier<Future<void>?>(null));
//   if (notifier == null ||
//       notifier.value != null ||
//       pinnedThumbnails.get(id) != null) {
//     return Future.value();
//   }

//   return notifier.value = Future(() async {
//     final notif = await NotificationApi().show(
//       id: NotificationApi.savingThumbId,
//       title: "",
//       channel: NotificationChannel.misc,
//       group: NotificationGroup.misc,
//     );

//     notif.update(0, filename);

//     final res = ParsedFilenameResult.fromFilename(filename).maybeValue();
//     if (res != null) {
//       final client = BooruAPI.defaultClientForBooru(res.booru);
//       final api = BooruAPI.fromEnum(res.booru, client);

//       try {
//         final post = await api.singlePost(res.id);

//         final t =
//             await GalleryApi().thumbs.saveFromNetwork(post.previewUrl, id);

//         thumbnails.delete(id);
//         pinnedThumbnails.add(id, t.path, t.differenceHash);
//       } catch (e, trace) {
//         Logger.root.warning("loadNetworkThumb", e, trace);
//       }

//       client.close(force: true);
//     }

//     notif.done();
//   }).whenComplete(() => notifier.value = null);
// }
