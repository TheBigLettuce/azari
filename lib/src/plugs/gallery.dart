// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:developer";

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/main.dart";
import "package:gallery/src/db/base/gallery_file_functionality_mixin.dart";
import "package:gallery/src/db/base/post_base.dart";
import "package:gallery/src/db/base/system_gallery_thumbnail_provider.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/db/tags/post_tags.dart";
import "package:gallery/src/interfaces/booru/booru_api.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/interfaces/cell/contentable.dart";
import "package:gallery/src/interfaces/cell/sticker.dart";
import "package:gallery/src/interfaces/gallery/gallery_api_directories.dart";
import "package:gallery/src/net/download_manager/download_manager.dart";
import "package:gallery/src/pages/booru/booru_page.dart";
import "package:gallery/src/pages/gallery/directories.dart";
import "package:gallery/src/pages/gallery/files.dart";
import "package:gallery/src/plugs/gallery/dummy_.dart"
    if (dart.library.io) "package:gallery/src/plugs/gallery/io.dart"
    if (dart.library.html) "package:gallery/src/plugs/gallery/web.dart";
import "package:gallery/src/plugs/gallery_management_api.dart";
import "package:gallery/src/plugs/platform_functions.dart";
import "package:gallery/src/widgets/empty_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/page_switcher.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/image_view/image_view.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:gallery/src/widgets/make_tags.dart";
import "package:gallery/src/widgets/menu_wrapper.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:gallery/src/widgets/notifiers/tag_refresh.dart";
import "package:gallery/src/widgets/search_bar/search_text_field.dart";
import "package:gallery/src/widgets/set_wallpaper_tile.dart";
import "package:isar/isar.dart";
import "package:local_auth/local_auth.dart";
import "package:logging/logging.dart";
import "package:url_launcher/url_launcher.dart";

abstract class GalleryPlug {
  GalleryAPIDirectories galleryApi(
    BlacklistedDirectoryService blacklistedDirectory,
    DirectoryTagService directoryTag, {
    required bool temporaryDb,
    bool setCurrentApi = true,
    required AppLocalizations l8n,
  });

  void notify(String? target);
  bool get temporary;
  Future<int> get version;
}

GalleryPlug chooseGalleryPlug() => getApi();

void initalizeGalleryPlug(bool temporary) => initApi(temporary);

class GalleryDirectoryBase {
  const GalleryDirectoryBase({
    required this.bucketId,
    required this.name,
    required this.tag,
    required this.volumeName,
    required this.relativeLoc,
    required this.lastModified,
    required this.thumbFileId,
  });

  final int thumbFileId;
  @Index(unique: true)
  final String bucketId;

  @Index()
  final String name;

  final String relativeLoc;
  final String volumeName;

  @Index()
  final int lastModified;

  @Index()
  final String tag;
}

class AndroidGalleryDirectory extends GalleryDirectoryBase
    with GalleryDirectory {
  const AndroidGalleryDirectory({
    required super.bucketId,
    required super.name,
    required super.tag,
    required super.volumeName,
    required super.relativeLoc,
    required super.lastModified,
    required super.thumbFileId,
  });
}

mixin GalleryDirectory
    implements
        GalleryDirectoryBase,
        CellBase,
        Pressable<GalleryDirectory>,
        Thumbnailable {
  static GalleryDirectory forPlatform({
    required int thumbFileId,
    required String bucketId,
    required String name,
    required String relativeLoc,
    required String volumeName,
    required int lastModified,
    required String tag,
  }) =>
      AndroidGalleryDirectory(
        bucketId: bucketId,
        name: name,
        tag: tag,
        volumeName: volumeName,
        relativeLoc: relativeLoc,
        lastModified: lastModified,
        thumbFileId: thumbFileId,
      );

  @override
  CellStaticData description() => const CellStaticData();

  @override
  ImageProvider<Object> thumbnail() => GalleryThumbnailProvider(
        thumbFileId,
        true,
        PinnedThumbnailService.db(),
        ThumbnailService.db(),
      );

  @override
  Key uniqueKey() => ValueKey(bucketId);

  @override
  String alias(bool isList) => name;

  @override
  Future<void> onPress(
    BuildContext context,
    GridFunctionality<GalleryDirectory> functionality,
    GalleryDirectory cell,
    int idx,
  ) {
    final l8n = AppLocalizations.of(context)!;

    final (api, callback, nestedCallback, segmentFnc) =
        DirectoriesDataNotifier.of(context);

    if (callback != null) {
      Navigator.pop(context);
      callback(cell, null);

      return Future.value();
    } else {
      bool requireAuth = false;

      Future<void> onSuccess(bool success) {
        if (!success || !context.mounted) {
          return Future.value();
        }

        StatisticsGalleryService.db().current.add(viewedDirectories: 1).save();
        final d = cell;

        final db = DatabaseConnectionNotifier.of(context);

        final apiFiles = switch (cell.bucketId) {
          "trash" => api.files(
              d,
              GalleryFilesPageType.trash,
              db.directoryTags,
              db.directoryMetadata,
              db.favoriteFiles,
              db.localTags,
            ),
          "favorites" => api.files(
              d,
              GalleryFilesPageType.favorites,
              db.directoryTags,
              db.directoryMetadata,
              db.favoriteFiles,
              db.localTags,
            ),
          String() => api.files(
              d,
              GalleryFilesPageType.normal,
              db.directoryTags,
              db.directoryMetadata,
              db.favoriteFiles,
              db.localTags,
            ),
        };

        final glue = GlueProvider.generateOf(context);

        return Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (context) => switch (cell.bucketId) {
              "favorites" => GalleryFiles(
                  generateGlue: glue,
                  api: apiFiles,
                  secure: requireAuth,
                  callback: nestedCallback,
                  dirName: l8n.galleryDirectoriesFavorites,
                  bucketId: "favorites",
                  db: DatabaseConnectionNotifier.of(context),
                  tagManager: TagManager.of(context),
                ),
              "trash" => GalleryFiles(
                  api: apiFiles,
                  generateGlue: glue,
                  secure: requireAuth,
                  callback: nestedCallback,
                  dirName: l8n.galleryDirectoryTrash,
                  bucketId: "trash",
                  db: DatabaseConnectionNotifier.of(context),
                  tagManager: TagManager.of(context),
                ),
              String() => GalleryFiles(
                  generateGlue: glue,
                  api: apiFiles,
                  secure: requireAuth,
                  dirName: d.name,
                  callback: nestedCallback,
                  bucketId: d.bucketId,
                  db: DatabaseConnectionNotifier.of(context),
                  tagManager: TagManager.of(context),
                )
            },
          ),
        );
      }

      requireAuth = DatabaseConnectionNotifier.of(context)
              .directoryMetadata
              .get(segmentFnc(cell))
              ?.requireAuth ??
          false;

      if (canAuthBiometric && requireAuth) {
        return LocalAuthentication()
            .authenticate(
              localizedReason: l8n.openDirectory,
            )
            .then(onSuccess);
      } else {
        return onSuccess(true);
      }
    }
  }
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

class AndroidGalleryFile extends FileBase with GalleryFile {
  const AndroidGalleryFile({
    required super.id,
    required super.bucketId,
    required super.name,
    required super.isVideo,
    required super.isGif,
    required super.size,
    required super.height,
    required super.isDuplicate,
    required super.width,
    required super.lastModified,
    required super.originalUri,
    required super.tagsFlat,
  });
}

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
  static GalleryFile forPlatform({
    required String tagsFlat,
    required int id,
    required String bucketId,
    required String name,
    required int lastModified,
    required String originalUri,
    required int height,
    required int width,
    required int size,
    required bool isVideo,
    required bool isGif,
    required bool isDuplicate,
  }) =>
      AndroidGalleryFile(
        id: id,
        bucketId: bucketId,
        name: name,
        isVideo: isVideo,
        isGif: isGif,
        size: size,
        height: height,
        isDuplicate: isDuplicate,
        width: width,
        lastModified: lastModified,
        originalUri: originalUri,
        tagsFlat: tagsFlat,
      );

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
    final (api, callback, actions) = FilesDataNotifier.of(context);
    final db = DatabaseConnectionNotifier.of(context);
    final tagManager = TagManager.of(context);

    return callback != null
        ? <ImageViewAction>[
            actions.chooseAction().asImageView(this),
          ]
        : api.type.isTrash()
            ? <ImageViewAction>[
                actions.restoreFromTrash().asImageView(this),
              ]
            : <ImageViewAction>[
                ImageViewAction(
                  Icons.star_rounded,
                  (selected) {
                    FilesActionsMixin.favoriteOrUnfavorite(
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
                actions.deleteAction().asImageView(this),
                ImageViewAction(
                  Icons.copy,
                  (selected) {
                    actions.moveOrCopyFnc(
                      context,
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
                    actions.moveOrCopyFnc(
                      context,
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

    final l8n = AppLocalizations.of(context)!;

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(left: 16),
          sliver: LabelSwitcherWidget(
            pages: [
              PageLabel(l8n.infoHeadline),
              PageLabel(
                l8n.tagsInfoPage,
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
                  title: l8n.nameTitle,
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
                                    title: Text(l8n.enterNewNameTitle),
                                    content: TextFormField(
                                      autofocus: true,
                                      initialValue: filename,
                                      autovalidateMode: AutovalidateMode.always,
                                      decoration: const InputDecoration(
                                        errorMaxLines: 2,
                                      ),
                                      validator: (value) {
                                        if (value == null) {
                                          return l8n.valueIsNull;
                                        }

                                        final res =
                                            DisassembleResult.fromFilename(
                                          value,
                                        );
                                        if (res.hasError) {
                                          return res.asError(l8n);
                                        }

                                        return null;
                                      },
                                      onFieldSubmitted: (value) {
                                        GalleryManagementApi.current()
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
                title: l8n.dateModified,
                subtitle: l8n.date(
                  DateTime.fromMillisecondsSinceEpoch(file.lastModified * 1000),
                ),
              ),
              addInfoTile(
                title: l8n.widthInfoPage,
                subtitle: l8n.pixels(file.width),
              ),
              addInfoTile(
                title: l8n.heightInfoPage,
                subtitle: l8n.pixels(file.height),
              ),
              addInfoTile(
                title: l8n.sizeInfoPage,
                subtitle: kbMbSize(context, file.size),
              ),
              // if (res != null && file.tagsFlat.contains("translated"))
              // TranslationNotes.tile(context, res.id, res.booru),
              if (res != null && filesExtended)
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
                      final notifier = TagRefreshNotifier.maybeOf(context);
                      final db =
                          DatabaseConnectionNotifier.of(context).localTags;

                      db.delete(filename);
                      notifier?.call();
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
                        l8n,
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
          DrawerTagsWidget(
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
  Future<void>? _status;

  @override
  void dispose() {
    _status?.ignore();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.res;
    final l8n = AppLocalizations.of(context)!;

    return RawChip(
      isEnabled: _status == null,
      onPressed: _status != null
          ? null
          : () {
              final dio = BooruAPI.defaultClientForBooru(res!.booru);
              final api = BooruAPI.fromEnum(res.booru, dio, EmptyPageSaver());

              final downloadManager = DownloadManager.of(context);
              final postTags = PostTags.fromContext(context);

              _status = api.singlePost(res.id).then((post) {
                GalleryManagementApi.current().deleteFiles([widget.file]);

                post.download(downloadManager, postTags);

                return null;
              }).onError((error, stackTrace) {
                log(
                  "loading post for download",
                  level: Level.SEVERE.value,
                  error: error,
                  stackTrace: stackTrace,
                );

                return null;
              }).whenComplete(() {
                dio.close(force: true);
              });

              setState(() {});
            },
      avatar: const Icon(Icons.download_outlined),
      label: Text(l8n.redownloadLabel),
    );
  }
}
