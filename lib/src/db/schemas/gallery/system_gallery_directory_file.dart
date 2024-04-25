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
import "package:gallery/src/db/base/system_gallery_directory_file_functionality_mixin.dart";
import "package:gallery/src/db/base/system_gallery_thumbnail_provider.dart";
import "package:gallery/src/db/initalize_db.dart";
import "package:gallery/src/db/schemas/downloader/download_file.dart";
import "package:gallery/src/db/schemas/gallery/favorite_file.dart";
import "package:gallery/src/db/schemas/gallery/note_gallery.dart";
import "package:gallery/src/db/schemas/settings/misc_settings.dart";
import "package:gallery/src/db/schemas/statistics/statistics_gallery.dart";
import "package:gallery/src/db/schemas/tags/pinned_tag.dart";
import "package:gallery/src/db/services/settings.dart";
import "package:gallery/src/db/tags/post_tags.dart";
import "package:gallery/src/interfaces/booru/booru_api.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/interfaces/cell/contentable.dart";
import "package:gallery/src/interfaces/cell/sticker.dart";
import "package:gallery/src/net/downloader.dart";
import "package:gallery/src/pages/booru/booru_page.dart";
import "package:gallery/src/pages/gallery/files.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/plugs/gallery/android/api.g.dart";
import "package:gallery/src/plugs/platform_functions.dart";
import "package:gallery/src/widgets/empty_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/page_switcher.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/image_view/image_view.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:gallery/src/widgets/make_tags.dart";
import "package:gallery/src/widgets/menu_wrapper.dart";
import "package:gallery/src/widgets/notifiers/tag_refresh.dart";
import "package:gallery/src/widgets/search_bar/search_text_field.dart";
import "package:gallery/src/widgets/set_wallpaper_tile.dart";
import "package:gallery/src/widgets/translation_notes.dart";
import "package:isar/isar.dart";
import "package:logging/logging.dart";
import "package:url_launcher/url_launcher.dart";

part "system_gallery_directory_file.g.dart";

@collection
class SystemGalleryDirectoryFile
    with SystemGalleryDirectoryFileFunctionalityMixin
    implements
        ContentableCell,
        ContentWidgets,
        Pressable<SystemGalleryDirectoryFile>,
        Thumbnailable,
        Infoable,
        ImageViewActionable,
        AppBarButtonable,
        IsarEntryId,
        Stickerable {
  SystemGalleryDirectoryFile({
    required this.id,
    required this.bucketId,
    required this.name,
    required this.isVideo,
    required this.isGif,
    required this.size,
    required this.height,
    required this.notesFlat,
    required this.isDuplicate,
    required this.isFavorite,
    required this.width,
    required this.tagsFlat,
    required this.isOriginal,
    required this.lastModified,
    required this.originalUri,
  });

  factory SystemGalleryDirectoryFile.fromDirectoryFile(DirectoryFile? e) =>
      SystemGalleryDirectoryFile(
        id: e!.id,
        bucketId: e.bucketId,
        notesFlat: Dbs.g.main.noteGallerys
                .getByIdSync(e.id)
                ?.text
                .join()
                .toLowerCase() ??
            "",
        name: e.name,
        size: e.size,
        isDuplicate: RegExp("[(][0-9].*[)][.][a-zA-Z0-9].*").hasMatch(e.name),
        isFavorite: FavoriteFile.isFavorite(e.id),
        lastModified: e.lastModified,
        height: e.height,
        width: e.width,
        isGif: e.isGif,
        isOriginal: PostTags.g.isOriginal(e.name),
        originalUri: e.originalUri,
        isVideo: e.isVideo,
        tagsFlat: PostTags.g.getTagsPost(e.name).join(" "),
      );

  @override
  Id? isarId;

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

  final bool isOriginal;

  @ignore
  final List<Sticker> injectedStickers = [];

  final String notesFlat;
  final String tagsFlat;
  final bool isDuplicate;
  final bool isFavorite;

  @override
  CellStaticData description() => const CellStaticData(
        tightMode: true,
      );

  @override
  String alias(bool isList) => name;

  @override
  List<Widget> appBarButtons(BuildContext context) {
    final res = PostTags.g.dissassembleFilename(name).maybeValue();

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
        onPressed: () {
          PlatformFunctions.shareMedia(originalUri);
        },
        icon: const Icon(Icons.share),
      ),
    ];
  }

  @override
  Widget info(BuildContext context) => GalleryFileInfo(file: this);

  @override
  List<ImageViewAction> actions(BuildContext context) {
    final (api, callback, actions, state, plug) = FilesDataNotifier.of(context);
    final extra = api.getExtra();

    return callback != null
        ? [
            actions.chooseAction().asImageView(this),
          ]
        : extra.isTrash
            ? [
                actions.restoreFromTrash().asImageView(this),
              ]
            : [
                actions.addToFavoritesAction(this, plug).asImageView(this),
                actions.deleteAction().asImageView(this),
                ImageViewAction(
                  Icons.copy,
                  (selected) {
                    actions.moveOrCopyFnc(context, [this], false, state, plug);
                  },
                ),
                ImageViewAction(
                  Icons.forward_rounded,
                  (selected) {
                    actions.moveOrCopyFnc(context, [this], true, state, plug);
                  },
                ),
              ];
  }

  @override
  Contentable content(BuildContext context) {
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
  ImageProvider<Object> thumbnail() =>
      SystemGalleryThumbnailProvider(id, isVideo);

  @override
  Key uniqueKey() => ValueKey(id);

  @override
  List<Sticker> stickers(BuildContext context, bool excludeDuplicate) {
    if (excludeDuplicate) {
      final stickers = [
        ...injectedStickers.map((e) => e.icon).map((e) => Sticker(e)),
        ...defaultStickers(context, this),
      ];

      return stickers.isEmpty ? const [] : stickers;
    }

    return [
      ...injectedStickers,
      ...defaultStickers(context, this),
      if (isFavorite) const Sticker(Icons.star_rounded, important: true),
      if (notesFlat.isNotEmpty) const Sticker(Icons.sticky_note_2_outlined),
    ];
  }

  @override
  void onPress(
    BuildContext context,
    GridFunctionality<SystemGalleryDirectoryFile> functionality,
    SystemGalleryDirectoryFile cell,
    int idx,
  ) =>
      ImageView.defaultForGrid<SystemGalleryDirectoryFile>(
        context,
        functionality,
        const ImageViewDescription(
          statistics: ImageViewStatistics(
            swiped: StatisticsGallery.addFilesSwiped,
            viewed: StatisticsGallery.addViewedFiles,
          ),
        ),
        idx,
        _tags,
        _watchTags,
      );

  List<ImageTag> _tags(Contentable c) {
    final postTags = PostTags.g.getTagsPost(c.widgets.alias(false));
    if (postTags.isEmpty) {
      return const [];
    }

    return postTags.map((e) => ImageTag(e, PinnedTag.isPinned(e))).toList();
  }

  StreamSubscription<List<ImageTag>> _watchTags(
    Contentable c,
    void Function(List<ImageTag> l) f,
  ) =>
      PostTags.g.watchImageAndPinned(c.widgets.alias(false), f);
}

class GalleryFileInfo extends StatefulWidget {
  const GalleryFileInfo({super.key, required this.file});

  final SystemGalleryDirectoryFile file;

  @override
  State<GalleryFileInfo> createState() => _GalleryFileInfoState();
}

class _GalleryFileInfoState extends State<GalleryFileInfo>
    with SystemGalleryDirectoryFileFunctionalityMixin {
  int currentPage = 0;

  SystemGalleryDirectoryFile get file => widget.file;

  final filesExtended = MiscSettings.current.filesExtendedActions;

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

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(left: 16),
          sliver: LabelSwitcherWidget(
            pages: [
              PageLabel(AppLocalizations.of(context)!.infoHeadline),
              PageLabel(
                AppLocalizations.of(context)!.tagsInfoPage,
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
                  title: AppLocalizations.of(context)!.nameTitle,
                  subtitle: filename,
                  trailing: plug.temporary
                      ? null
                      : IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              DialogRoute(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(
                                      AppLocalizations.of(context)!
                                          .enterNewNameTitle,
                                    ),
                                    content: TextFormField(
                                      autofocus: true,
                                      initialValue: filename,
                                      autovalidateMode: AutovalidateMode.always,
                                      decoration: const InputDecoration(
                                        errorMaxLines: 2,
                                      ),
                                      validator: (value) {
                                        if (value == null) {
                                          return AppLocalizations.of(context)!
                                              .valueIsNull;
                                        }

                                        final res = PostTags.g
                                            .dissassembleFilename(value);
                                        if (res.hasError) {
                                          return res.asError(context);
                                        }

                                        return null;
                                      },
                                      onFieldSubmitted: (value) {
                                        PlatformFunctions.rename(
                                          file.originalUri,
                                          value,
                                        );
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
                title: AppLocalizations.of(context)!.dateModified,
                subtitle: AppLocalizations.of(context)!.date(
                  DateTime.fromMillisecondsSinceEpoch(file.lastModified * 1000),
                ),
              ),
              addInfoTile(
                title: AppLocalizations.of(context)!.widthInfoPage,
                subtitle: AppLocalizations.of(context)!.pixels(file.width),
              ),
              addInfoTile(
                title: AppLocalizations.of(context)!.heightInfoPage,
                subtitle: AppLocalizations.of(context)!.pixels(file.height),
              ),
              addInfoTile(
                title: AppLocalizations.of(context)!.sizeInfoPage,
                subtitle: kbMbSize(context, file.size),
              ),
              if (res != null && file.tagsFlat.contains("translated"))
                TranslationNotes.tile(context, res.id, res.booru),
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
                      PostTags.g.deletePostTags(filename);
                      notifier?.call();
                    },
                    icon: const Icon(Icons.delete_rounded),
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                  ),
                  IconButton.filledTonal(
                    onPressed: () {
                      openAddTagDialog(context, (v, delete) {
                        if (delete) {
                          PostTags.g.removeTag([filename], v);
                        } else {
                          PostTags.g.addTag([filename], v);
                        }
                      });
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

  final SystemGalleryDirectoryFile file;
  final DisassembleResult? res;

  @override
  State<RedownloadTile> createState() => _RedownloadTileState();
}

class _RedownloadTileState extends State<RedownloadTile> {
  Future? _status;

  @override
  void dispose() {
    _status?.ignore();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.res;

    return RawChip(
      isEnabled: _status == null,
      onPressed: _status != null
          ? null
          : () {
              final dio = BooruAPI.defaultClientForBooru(res!.booru);
              final api = BooruAPI.fromEnum(res.booru, dio, EmptyPageSaver());

              _status = api.singlePost(res.id).then((post) {
                PlatformFunctions.deleteFiles([widget.file]);

                PostTags.g.addTagsPost(post.filename(), post.tags, true);

                Downloader.g.add(
                  DownloadFile.d(
                    url: post.fileDownloadUrl(),
                    site: api.booru.url,
                    name: post.filename(),
                    thumbUrl: post.previewUrl,
                  ),
                  SettingsService.currentData,
                );

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
      label: Text(
        AppLocalizations.of(context)!.redownloadLabel,
      ),
    );
  }
}
