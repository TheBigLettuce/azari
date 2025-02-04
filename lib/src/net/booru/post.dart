// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/post_tags.dart";
import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/booru/display_quality.dart";
import "package:azari/src/net/booru/post_functions.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/pages/booru/booru_page.dart";
import "package:azari/src/pages/home/home.dart";
import "package:azari/src/pages/other/settings/radio_dialog.dart";
import "package:azari/src/platform/platform_api.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/gesture_dead_zones.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/sticker.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_cell.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:azari/src/widgets/image_view/image_view.dart";
import "package:azari/src/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/widgets/image_view/image_view_skeleton.dart";
import "package:azari/src/widgets/image_view/video/photo_gallery_page_video.dart";
import "package:azari/src/widgets/shimmer_loading_indicator.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:mime/mime.dart" as mime;
import "package:path/path.dart" as path_util;
import "package:photo_view/photo_view.dart";
import "package:transparent_image/transparent_image.dart";
import "package:url_launcher/url_launcher.dart";
import "package:video_player/video_player.dart";

final _transparent = MemoryImage(kTransparentImage);

abstract class PostImpl
    implements
        PostBase,
        SelectionWrapperBuilder,
        ContentableCell,
        Thumbnailable,
        ContentWidgets,
        AppBarButtonable,
        ImageViewActionable,
        Infoable,
        Stickerable,
        Downloadable {
  const PostImpl();

  String _makeName() =>
      ParsedFilenameResult.makeFilename(booru, fileDownloadUrl(), md5, id);

  @override
  CellStaticData description() => const CellStaticData();

  @override
  Widget info(BuildContext context) => PostInfo(post: this);

  // void _addToVisited(PostImpl post) {
  //   VisitedPostsService.db().addAll([
  //     VisitedPost(
  //       booru: post.booru,
  //       id: post.id,
  //       rating: post.rating,
  //       thumbUrl: post.previewUrl,
  //       date: DateTime.now(),
  //     ),
  //   ]);
  // }

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
    final downloadManager = DownloadManager.of(context);

    return WrapSelection(
      thisIndx: thisIndx,
      description: description,
      selectFrom: selectFrom,
      selection: selection,
      functionality: functionality,
      onPressed: onPressed,
      onDoubleTap: (context) {
        final status = downloadManager.statusFor(fileDownloadUrl());
        final downloadStatus = status?.data.status;

        if (downloadStatus == DownloadStatus.failed) {
          downloadManager.restartAll([status!], SettingsService.db().current);
        } else {
          download(
            downloadManager,
            PostTags.fromContext(context),
          );
        }
        WrapperSelectionAnimation.tryPlayOf(context);
      },
      child: child,
    );

    // return OpenContainer(
    //   tappable: false,
    //   closedElevation: 0,
    //   openElevation: 0,
    //   middleColor: theme.colorScheme.surface.withValues(alpha: 0),
    //   openColor: theme.colorScheme.surface.withValues(alpha: 0),
    //   closedColor: theme.colorScheme.surface.withValues(alpha: 1),
    //   useRootNavigator: true,
    //   closedBuilder: (context, action) => WrapSelection(
    //     thisIndx: thisIndx,
    //     description: description,
    //     selectFrom: selectFrom,
    //     selection: selection,
    //     functionality: functionality,
    //     onPressed: () {
    //       _addToVisited(this);
    //       action();
    //     },
    //     child: child,
    //   ),
    //   openBuilder: (containerContext, action) {
    //     final tagManager = TagManager.of(containerContext);

    //     final imageDescription = ImageViewDescription(
    //       ignoreOnNearEnd: false,
    //       statistics: StatisticsBooruService.asImageViewStatistics(),
    //     );

    //     final getCell = functionality.source.forIdxUnsafe;

    //     // return ImageView(
    //     //   // updates: functionality.source.backingStorage.watch,
    //     //   // gridContext: context,
    //     //   // statistics: imageDescription.statistics,
    //     //   // scrollUntill: (i) =>
    //     //   //     GridScrollNotifier.maybeScrollToOf<T>(context, i),
    //     //   // pageChange: (state) {
    //     //   //   imageDescription.pageChange?.call(state);
    //     //   //   _addToVisited(getCell(state.currentPage) as PostImpl);
    //     //   // },
    //     //   // watchTags: (c, f) => DefaultPostPressable.watchTags(c, f, tagManager),
    //     //   // onExit: imageDescription.onExit,
    //     //   // getContent: (idx) => (getCell(idx) as PostImpl).content(),
    //     //   // cellCount: functionality.source.count,
    //     //   // download: functionality.download,
    //     //   // startingCell: thisIndx,
    //     //   // tags: (c) => DefaultPostPressable.imageViewTags(c, tagManager),
    //     //   // onNearEnd:
    //     //   //     imageDescription.ignoreOnNearEnd || !functionality.source.hasNext
    //     //   //         ? null
    //     //   //         : functionality.source.next,
    //     //   // stateController: ,
    //     //   wrapNotifiers: functionality.registerNotifiers,
    //     // );
    //   },
    // );
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
      _CellWidget(
        key: uniqueKey(),
        wrapSelection: wrapSelection,
        post: this,
      );

  @override
  List<NavigationAction> appBarButtons(BuildContext context) {
    final l10n = context.l10n();

    return [
      NavigationAction(
        Icons.public,
        () {
          launchUrl(
            booru.browserLink(id),
            mode: LaunchMode.externalApplication,
          );
        },
        l10n.openOnBooru(booru.string),
      ),
      NavigationAction(
        Icons.share,
        () {
          PlatformApi().shareMedia(fileUrl, url: true);
        },
        l10n.shareLabel,
      ),
    ];
  }

  @override
  List<ImageViewAction> actions(BuildContext context) {
    final theme = Theme.of(context);

    final db = DbConn.of(context);
    final favorites = db.favoritePosts;
    final hidden = db.hiddenBooruPost;

    return [
      ImageViewAction(
        Icons.favorite_border_rounded,
        (_) => favorites.addRemove([this]),
        animate: true,
        watch: (f, [fire = false]) {
          return db.favoritePosts.cache
              .streamSingle(id, booru, fire)
              .map(
                (isFavorite_) => (
                  isFavorite_
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  isFavorite_
                      ? Colors.red.harmonizeWith(theme.colorScheme.primary)
                      : null,
                  !isFavorite_,
                ),
              )
              .listen(f);
        },
      ),
      ImageViewAction(
        Icons.download,
        (_) => download(
          DownloadManager.of(context),
          PostTags.fromContext(context),
        ),
        animate: true,
        animation: const [
          SlideEffect(
            curve: Easing.emphasizedAccelerate,
            duration: Durations.medium1,
            begin: Offset.zero,
            end: Offset(0, -0.4),
          ),
          FadeEffect(
            delay: Duration(milliseconds: 60),
            curve: Easing.standard,
            duration: Durations.medium1,
            begin: 1,
            end: 0,
          ),
        ],
      ),
      if (this is! FavoritePost)
        ImageViewAction(
          Icons.hide_image_rounded,
          (_) {
            if (hidden.isHidden(id, booru)) {
              hidden.removeAll([(id, booru)]);
            } else {
              hidden.addAll([
                HiddenBooruPostData(
                  thumbUrl: previewUrl,
                  postId: id,
                  booru: booru,
                ),
              ]);
            }
          },
          watch: (f, [fire = false]) {
            return hidden
                .streamSingle(id, booru, fire)
                .map<(IconData?, Color?, bool?)>((e) {
              return (
                null,
                e
                    ? Colors.lightBlue.harmonizeWith(theme.colorScheme.primary)
                    : null,
                null
              );
            }).listen(f);
          },
        ),
      // ImageViewAction(
      //   Icons.comment_rounded,
      //   (_) {
      //     final client = BooruAPI.defaultClientForBooru(booru);
      //     final api = BooruComunnityAPI.fromEnum(booru, client);

      //     final pageSaver = PageSaver.noPersist();

      //     Navigator.push<void>(
      //       context,
      //       ModalBottomSheetRoute(
      //         isScrollControlled: true,
      //         showDragHandle: true,
      //         builder: (context) {
      //           return WrapFutureRestartable(
      //             newStatus: () =>
      //                 api.comments.forPostId(postId: id, pageSaver: pageSaver),
      //             builder: (context, data) {
      //               return ListView.builder(
      //                 itemCount: data.length,
      //                 itemBuilder: (context, idx) {
      //                   return CommentTile(
      //                     comments: data[idx],
      //                   );
      //                 },
      //               );
      //             },
      //           );
      //         },
      //       ),
      //     ).whenComplete(() {
      //       client.close(force: true);
      //     });
      //   },
      //   animate: true,
      //   watch: (f, [fire = false]) => db.favoritePosts.watchSingle(
      //     id,
      //     booru,
      //     (isFavorite_) => (
      //       isFavorite_
      //           ? Icons.favorite_rounded
      //           : Icons.favorite_border_rounded,
      //       isFavorite_
      //           ? Colors.red.harmonizeWith(theme.colorScheme.primary)
      //           : null,
      //       !isFavorite_,
      //     ),
      //     f,
      //     fire,
      //   ),
      // ),
    ];
  }

  @override
  ImageProvider<Object> thumbnail(BuildContext? context) {
    if (HiddenBooruPostService.db().isHidden(id, booru)) {
      return _transparent;
    }

    final sampleThumbnails = SettingsService.db().current.sampleThumbnails;

    final int columns = (context == null
            ? null
            : GridConfiguration.maybeOf(context)?.columns.number) ??
        3;

    return CachedNetworkImageProvider(
      sampleThumbnails &&
              columns <= 2 &&
              type != PostContentType.gif &&
              type != PostContentType.video
          ? sampleUrl
          : previewUrl,
    );
  }

  @override
  Contentable content([bool thumb = false]) {
    final url =
        thumb && type == PostContentType.image ? previewUrl : Post.getUrl(this);

    final sampleThumbnails = SettingsService.db().current.sampleThumbnails;
    final isOriginal =
        SettingsService.db().current.quality == DisplayQuality.original;

    return switch (type) {
      PostContentType.none => EmptyContent(this),
      PostContentType.video => NetVideo(
          this,
          path_util.extension(url) == ".zip" ? sampleUrl : url,
        ),
      PostContentType.gif => NetGif(this, NetworkImage(url)),
      PostContentType.image => NetImage(
          this,
          thumb || (sampleThumbnails && !isOriginal)
              ? CachedNetworkImageProvider(url)
              : NetworkImage(url),
        ),
    };
  }

  @override
  Key uniqueKey() => ValueKey(fileUrl);

  @override
  String alias(bool isList) => isList ? _makeName() : id.toString();

  @override
  String fileDownloadUrl() {
    if (path_util.extension(fileUrl) == ".zip") {
      return sampleUrl;
    } else {
      return fileUrl;
    }
  }

  @override
  List<Sticker> stickers(BuildContext context, bool excludeDuplicate) {
    if (this is FavoritePost) {
      return [
        if (type == PostContentType.video)
          Sticker(
            FilteringMode.video.icon,
            subtitle: "",
          ),
        if (type == PostContentType.gif)
          Sticker(
            FilteringMode.gif.icon,
            subtitle: "",
          ),
        if (excludeDuplicate && tags.contains("original"))
          Sticker(FilteringMode.original.icon),
        if (excludeDuplicate && tags.contains("translated"))
          const Sticker(Icons.translate_outlined),
      ];
    }

    if (excludeDuplicate) {
      final icons = [
        if (score > 10)
          Sticker(
            score > 80 ? Icons.whatshot_rounded : Icons.thumb_up_rounded,
            subtitle: score.toString(),
            important: score > 80,
          ),
        ...defaultStickersPost(
          type,
          context,
          tags,
          id,
          booru,
        ),
      ];

      return icons.isEmpty ? const [] : icons;
    }

    final db = DbConn.of(context);

    final isHidden = db.hiddenBooruPost.isHidden(id, booru);

    return [
      if (isHidden) const Sticker(Icons.hide_image_rounded),
      ...defaultStickersPost(
        type,
        context,
        tags,
        id,
        booru,
      ),
    ];
  }
}

class CommentTile extends StatelessWidget {
  const CommentTile({
    super.key,
    required this.comments,
  });

  final BooruComments comments;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

enum PostRating {
  general,
  sensitive,
  questionable,
  explicit;

  String translatedName(AppLocalizations l10n) => switch (this) {
        PostRating.general => l10n.enumPostRatingGeneral,
        PostRating.sensitive => l10n.enumPostRatingSensitive,
        PostRating.questionable => l10n.enumPostRatingQuestionable,
        PostRating.explicit => l10n.enumPostRatingExplicit,
      };

  SafeMode get asSafeMode => switch (this) {
        PostRating.general => SafeMode.normal,
        PostRating.sensitive => SafeMode.relaxed,
        PostRating.questionable || PostRating.explicit => SafeMode.none,
      };
}

enum PostContentType {
  none,
  video,
  gif,
  image;

  Icon toIcon() => switch (this) {
        PostContentType.none => const Icon(Icons.hide_image_outlined),
        PostContentType.video => const Icon(Icons.slideshow_outlined),
        PostContentType.image ||
        PostContentType.gif =>
          const Icon(Icons.photo_outlined),
      };

  static PostContentType fromUrl(String url) {
    final t = mime.lookupMimeType(url);
    if (t == null) {
      return PostContentType.none;
    }

    final typeHalf = t.split("/");

    if (typeHalf[0] == "image") {
      return typeHalf[1] == "gif" ? PostContentType.gif : PostContentType.image;
    } else if (typeHalf[0] == "video") {
      return PostContentType.video;
    } else {
      throw "";
    }
  }
}

abstract class PostBase {
  const PostBase();

  int get id;

  String get md5;

  List<String> get tags;

  int get width;
  int get height;

  String get fileUrl;
  String get previewUrl;
  String get sampleUrl;
  String get sourceUrl;
  PostRating get rating;
  int get score;
  int get size;
  DateTime get createdAt;
  Booru get booru;
  PostContentType get type;
}

mixin DefaultPostPressable<T extends PostImpl>
    implements PostImpl, Pressable<T> {
  @override
  void onPress(
    BuildContext context,
    GridFunctionality<T> functionality,
    int idx,
  ) {
    final db = DbConn.of(context);
    final tagManager = TagManager.of(context);

    if (this is! FavoritePost &&
        SettingsService.db().current.sampleThumbnails) {
      _CellWidget.openMaximizedImage(
        context,
        this,
        content(),
      );

      return;
    }

    ImageView.defaultForGrid<T>(
        context,
        functionality,
        ImageViewDescription(
          ignoreOnNearEnd: false,
          statistics: StatisticsBooruService.asImageViewStatistics(),
        ),
        idx,
        (c) => imageViewTags(c, tagManager),
        (c, f) => watchTags(c, f, tagManager), (post) {
      db.visitedPosts.addAll([
        VisitedPost(
          booru: post.booru,
          id: post.id,
          rating: post.rating,
          thumbUrl: post.previewUrl,
          date: DateTime.now(),
        ),
      ]);
    });
  }

  static List<ImageTag> imageViewTags(
    ContentWidgets c,
    TagManager tagManager,
  ) =>
      (c as PostBase)
          .tags
          .map(
            (e) => ImageTag(
              e,
              favorite: tagManager.pinned.exists(e),
              excluded: tagManager.excluded.exists(e),
            ),
          )
          .toList();

  static StreamSubscription<List<ImageTag>> watchTags(
    ContentWidgets c,
    void Function(List<ImageTag> l) f,
    TagManager tagManager,
  ) =>
      tagManager.pinned.watchImage((c as PostBase).tags, f);
}

extension MultiplePostDownloadExt on List<PostImpl> {
  void downloadAll(
    DownloadManager downloadManager,
    PostTags postTags, [
    PathVolume? thenMoveTo,
  ]) {
    downloadManager.addLocalTags(
      map(
        (e) => DownloadEntryTags.d(
          tags: e.tags,
          name: ParsedFilenameResult.makeFilename(
            e.booru,
            e.fileDownloadUrl(),
            e.md5,
            e.id,
          ),
          url: e.fileDownloadUrl(),
          thumbUrl: e.previewUrl,
          site: e.booru.url,
          thenMoveTo: thenMoveTo,
        ),
      ),
      SettingsService.db().current,
      postTags,
    );
  }
}

extension PostDownloadExt on PostImpl {
  void download(
    DownloadManager downloadManager,
    PostTags postTags, [
    PathVolume? thenMoveTo,
  ]) {
    downloadManager.addLocalTags(
      [
        DownloadEntryTags.d(
          tags: tags,
          name: ParsedFilenameResult.makeFilename(
            booru,
            fileDownloadUrl(),
            md5,
            id,
          ),
          url: fileDownloadUrl(),
          thumbUrl: previewUrl,
          site: booru.url,
          thenMoveTo: thenMoveTo,
        ),
      ],
      SettingsService.db().current,
      postTags,
    );
  }
}

// class _CellWidget extends StatelessWidget {
//   const _CellWidget({
//     // super.key,
//     required this.post,
//   });

//   final PostImpl post;

//   int calculateTagsChipLetterCount(Size biggest) {
//     return switch (biggest) {
//       Size(height: > 190, width: > 190) => 10,
//       Size(height: > 180, width: > 180) => 8,
//       Size(height: > 90, width: > 90) => 7,
//       Size() => 10,
//     };
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final thumbnail = post.thumbnail();
//     final downloader = DownloadManager.of(context);

//     final animate = PlayAnimations.maybeOf(context) ?? false;

//     final child = Card(
//       elevation: 0,
//       color: theme.cardColor.withValues(alpha: 0),
//       child: ClipPath(
//         clipper: ShapeBorderClipper(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15),
//           ),
//         ),
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             return Stack(
//               children: [
//                 GridCellImage(
//                   imageAlign: Alignment.topCenter,
//                   thumbnail: thumbnail,
//                   blur: false,
//                 ),
//                 if (constraints.maxHeight > 80 &&
//                     constraints.maxWidth > 80) ...[
//                   // if (post is! FavoritePost)
//                   Align(
//                     alignment: Alignment.topRight,
//                     child: Padding(
//                       padding: const EdgeInsets.all(6),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           _FavoriteButton(
//                             post: post,
//                             favoritePosts:
//                                 DatabaseConnectionNotifier.of(context)
//                                     .favoritePosts,
//                           ),
//                           if (post.score > 10)
//                             StickerWidget(
//                               Sticker(
//                                 post.score > 80
//                                     ? Icons.whatshot_rounded
//                                     : Icons.thumb_up_rounded,
//                                 subtitle: post.score.toString(),
//                                 important: post.score > 80,
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   Align(
//                     alignment: Alignment.bottomCenter,
//                     child: Padding(
//                       padding: const EdgeInsets.all(2),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         crossAxisAlignment: post is FavoritePost
//                             ? CrossAxisAlignment.center
//                             : CrossAxisAlignment.end,
//                         children: [
//                           Expanded(
//                             child: Padding(
//                               padding: const EdgeInsets.only(
//                                 top: 6,
//                                 bottom: 6,
//                                 left: 6,
//                               ),
//                               child: _TagsWrap(
//                                 post: post,
//                                 verySmall: constraints.maxWidth < 100,
//                                 letterCount: calculateTagsChipLetterCount(
//                                   constraints.biggest,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           _DownloadIcon(
//                             downloadManager: downloader,
//                             post: post,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             );
//           },
//         ),
//       ),
//     );

//     return animate ? child.animate(key: post.uniqueKey()).fadeIn() : child;
//   }
// }

class _CellWidget extends StatefulWidget {
  const _CellWidget({
    super.key,
    required this.post,
    required this.wrapSelection,
  });

  final PostImpl post;

  final Widget Function(Widget child) wrapSelection;

  static void openMaximizedImage(
    BuildContext context,
    PostImpl post,
    Contentable content,
  ) {
    Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder(
        fullscreenDialog: true,
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) =>
            _ExpandedImage(
          post: post,
          content: content,
        ),
      ),
    );
  }

  @override
  State<_CellWidget> createState() => _CellWidgetState();
}

class _CellWidgetState extends State<_CellWidget>
    with PinnedSortedTagsArrayMixin {
  PostImpl get post => widget.post;
  @override
  List<String> get postTags => widget.post.tags;

  final controller = ScrollController();
  late final StreamSubscription<SettingsData?> subscription;

  SettingsData settings = SettingsService.db().current;

  @override
  void initState() {
    super.initState();

    subscription = settings.s.watch((newSettings) {
      settings = newSettings!;

      setState(() {});
    });
  }

  @override
  void dispose() {
    subscription.cancel();

    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnail = post.thumbnail(context);

    final downloadManager = DownloadManager.of(context);

    final animate = PlayAnimations.maybeOf(context) ?? false;

    final content = post.content();

    final child = Builder(
      builder: (context) {
        final card = widget.wrapSelection(
          Builder(
            builder: (context) => GestureDetector(
              child: Card(
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                color: theme.cardColor.withValues(alpha: 0),
                child: Stack(
                  children: [
                    GridCellImage(
                      heroTag: post.uniqueKey(),
                      imageAlign: Alignment.topCenter,
                      thumbnail: post.type == PostContentType.gif &&
                              post.size != 0 &&
                              !post.size.isNegative &&
                              post.size < 524288
                          ? CachedNetworkImageProvider(
                              post.sampleUrl.isEmpty
                                  ? post.fileUrl
                                  : post.sampleUrl,
                            )
                          : thumbnail,
                      blur: false,
                    ),
                    if (widget.post is! FavoritePost)
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: _FavoriteButton(
                          post: post,
                          favoritePosts: DbConn.of(context).favoritePosts,
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
                          isVideo: widget.post.type == PostContentType.video,
                          isGif: widget.post.type == PostContentType.gif,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _DownloadIndicator(
                        downloadManager: downloadManager,
                        post: post,
                      ),
                    ),
                    if (post is! FavoritePost &&
                        post.type == PostContentType.image)
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: IconButton(
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: WidgetStatePropertyAll(
                                theme.colorScheme.surface
                                    .withValues(alpha: 0.9),
                              ),
                              backgroundColor: WidgetStatePropertyAll(
                                theme.colorScheme.onSurface
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                            onPressed: () => _CellWidget.openMaximizedImage(
                              context,
                              post,
                              settings.sampleThumbnails
                                  ? content
                                  : post.content(true),
                            ),
                            icon: const Icon(Icons.open_in_full),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );

        if (tags.isEmpty) {
          return card;
        }

        return Column(
          children: [
            Expanded(child: card),
            SizedBox(
              height: 21,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ListView.builder(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.antiAlias,
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    final e = tags[index];

                    return OutlinedTagChip(
                      tag: e.tag,
                      letterCount: 8,
                      isPinned: e.pinned,
                      onDoublePressed: e.pinned
                          ? null
                          : () {
                              controller.animateTo(
                                0,
                                duration: Durations.medium3,
                                curve: Easing.standard,
                              );

                              final pinned = TagManager.of(context).pinned;

                              pinned.add(e.tag);
                            },
                      onLongPressed: widget.post is FavoritePost
                          ? null
                          : () {
                              context.openSafeModeDialog((safeMode) {
                                OnBooruTagPressed.pressOf(
                                  context,
                                  e.tag,
                                  widget.post.booru,
                                  overrideSafeMode: safeMode,
                                );
                              });
                            },
                      onPressed: () => OnBooruTagPressed.pressOf(
                        context,
                        e.tag,
                        widget.post.booru,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    if (animate) {
      return child.animate(key: post.uniqueKey()).fadeIn();
    }

    return child;
  }
}

class _Video extends StatefulWidget {
  const _Video({
    // super.key,
    required this.post,
  });

  final PostImpl post;

  @override
  State<_Video> createState() => __VideoState();
}

class __VideoState extends State<_Video> {
  late final VideoPlayerController controller;

  bool initalized = false;

  @override
  void initState() {
    super.initState();

    controller = VideoPlayerController.networkUrl(
      Uri.parse(
        widget.post.sampleUrl.isEmpty
            ? widget.post.fileUrl
            : widget.post.sampleUrl,
      ),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    controller.setVolume(0);
    controller.setLooping(true);

    controller.initialize().then((_) {
      if (context.mounted) {
        setState(() {
          controller.play();
          initalized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final aspectRatio = widget.post.width == 0 || widget.post.height == 0
    //     ? 1
    //     : widget.post.width / widget.post.height;

    return initalized
        ? LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: constraints.maxHeight,
              width: constraints.maxWidth,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  height: controller.value.size.height,
                  width: controller.value.size.width,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          )
        : const ShimmerLoadingIndicator();
  }
}

class _ExpandedImage extends StatelessWidget {
  const _ExpandedImage({
    // super.key,
    required this.post,
    required this.content,
  });

  final PostImpl post;
  final Contentable content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final buttonStyle = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(theme.colorScheme.surface),
      iconColor: WidgetStatePropertyAll(theme.colorScheme.onSurface),
    );

    final child = content is NetVideo
        ? _ExpandedVideo(
            post: post,
            child: PhotoGalleryPageVideo(
              url: (content as NetVideo).uri,
              networkThumb: post.thumbnail(context),
              localVideo: false,
              db: DbConn.of(context).videoSettings,
            ),
          )
        : PhotoView(
            heroAttributes: PhotoViewHeroAttributes(tag: post.uniqueKey()),
            maxScale: PhotoViewComputedScale.contained * 1.8,
            minScale: PhotoViewComputedScale.contained * 0.8,
            filterQuality: FilterQuality.high,
            loadingBuilder: (context, event) => const ShimmerLoadingIndicator(),
            backgroundDecoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0),
            ),
            imageProvider: content is NetImage
                ? (content as NetImage).provider
                : (content as NetGif).provider,
          );

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: buttonStyle,
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                builder: (sheetContext) {
                  return Padding(
                    padding: EdgeInsets.only(
                      top: 8,
                      bottom: MediaQuery.viewPaddingOf(context).bottom + 12,
                    ),
                    child: SizedBox(
                      width: MediaQuery.sizeOf(sheetContext).width,
                      child: PostInfoSimple(post: post),
                    ),
                  );
                },
              );
            },
            style: buttonStyle,
            icon: const Icon(Icons.info_outline),
          ),
        ],
        backgroundColor: Colors.transparent,
      ),
      body: GestureDeadZones(
        left: true,
        right: true,
        child: child,
      ),
    );
  }
}

class _ExpandedVideo extends StatefulWidget {
  const _ExpandedVideo({
    // super.key,
    required this.post,
    required this.child,
  });

  final PostImpl post;

  final Widget child;

  @override
  State<_ExpandedVideo> createState() => __ExpandedVideoState();
}

class __ExpandedVideoState extends State<_ExpandedVideo> {
  final videoControls = VideoControlsControllerImpl();
  final pauseVideoState = PauseVideoState();

  final seekTimeAnchor = GlobalKey<SeekTimeAnchorState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    videoControls.dispose();
    pauseVideoState.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);

    return Center(
      child: VideoControlsNotifier(
        controller: videoControls,
        child: PauseVideoNotifierHolder(
          state: pauseVideoState,
          child: Stack(
            alignment: Alignment.center,
            children: [
              widget.child,
              SeekTimeAnchor(
                key: seekTimeAnchor,
                bottomPadding: viewPadding.bottom + 20,
                videoControls: videoControls,
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: viewPadding.bottom + 20),
                  child: VideoControls(
                    videoControls: videoControls,
                    db: DbConn.of(context).videoSettings,
                    seekTimeAnchor: seekTimeAnchor,
                    vertical: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoGifRow extends StatelessWidget {
  const VideoGifRow({
    super.key,
    required this.isVideo,
    required this.isGif,
  });

  final bool isVideo;
  final bool isGif;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 2,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isGif)
          const _VideoGifIcon(
            icon: Icons.gif_rounded,
          ),
        if (isVideo)
          const _VideoGifIcon(
            icon: Icons.play_arrow_rounded,
          ),
        // if (score > 10) _Score(score: score),
      ],
    );
  }
}

class _TagsWrap extends StatefulWidget {
  const _TagsWrap({
    // super.key,
    required this.post,
    required this.letterCount,
    required this.verySmall,
  });

  final bool verySmall;

  final int letterCount;

  final PostImpl post;

  @override
  State<_TagsWrap> createState() => __TagsWrapState();
}

class __TagsWrapState extends State<_TagsWrap> {
  List<String> pinnedTags = [];
  bool hasVideo = false;
  bool hasGif = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final tags = PinnedTagsProvider.of(context);
    pinnedTags = widget.post.tags.where((e) {
      if (hasGif || e == "gif") {
        hasGif = true;
      }

      if (hasVideo || e == "video") {
        hasVideo = true;
      }

      return tags.$1.containsKey(e);
    }).toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.verySmall ? 42 / 2 : 42,
      child: Wrap(
        clipBehavior: Clip.antiAlias,
        verticalDirection: VerticalDirection.up,
        runSpacing: 2,
        spacing: 2,
        children: [
          if (hasGif)
            const _VideoGifIcon(
              icon: Icons.gif_box_rounded,
            ),
          if (hasVideo)
            const _VideoGifIcon(
              icon: Icons.play_arrow_rounded,
            ),
          ...pinnedTags.map(
            (e) => PinnedTagChip(
              tag: e,
              tight: true,
              letterCount: widget.letterCount,
              mildlyTransculent: true,
            ),
          ),
        ],
      ),
    );
  }
}

// class _Score extends StatelessWidget {
//   const _Score({
//     // super.key,
//     required this.score,
//   });

//   final int score;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     return DecoratedBox(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(6),
//         color: score > 80
//             ? colorScheme.onPrimary.withValues(alpha: 0.2)
//             : colorScheme.surfaceContainerLow.withValues(alpha: 0.1),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               score > 80 ? Icons.whatshot_rounded : Icons.thumb_up_rounded,
//               size: 12,
//               color: score > 80
//                   ? colorScheme.primary.withValues(alpha: 0.9)
//                   : colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
//             ),
//             const Padding(padding: EdgeInsets.only(right: 4)),
//             Text(
//               score.toString(),
//               style: theme.textTheme.labelMedium?.copyWith(
//                 color: colorScheme.onSurfaceVariant,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class _VideoGifIcon extends StatelessWidget {
  const _VideoGifIcon({
    // super.key,
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.secondary.withValues(alpha: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSecondary.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  const _FavoriteButton({
    // super.key,
    required this.post,
    required this.favoritePosts,
  });

  final PostImpl post;
  final FavoritePostSourceService favoritePosts;

  @override
  State<_FavoriteButton> createState() => __FavoriteButtonState();
}

class __FavoriteButtonState extends State<_FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final StreamSubscription<void> events;

  bool favorite = false;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this);

    favorite = widget.favoritePosts.cache
        .isFavorite(widget.post.id, widget.post.booru);

    events = widget.favoritePosts.cache
        .streamSingle(widget.post.id, widget.post.booru)
        .listen((newFavorite) {
      favorite = newFavorite;

      if (favorite) {
        controller.forward().then((_) => controller.reverse());
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    events.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder(
      curve: Easing.linear,
      tween: ColorTween(
        end: favorite ? Colors.pink : theme.colorScheme.surfaceContainer,
      ),
      duration: Durations.short3,
      builder: (context, value, child) => IconButton(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(
            value,
          ),
          backgroundColor: WidgetStatePropertyAll(
            theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
          ),
        ),
        onPressed: () {
          widget.favoritePosts.addRemove([widget.post]);
        },
        icon: Animate(
          controller: controller,
          value: 0,
          autoPlay: false,
          effects: const [
            ScaleEffect(
              delay: Duration(milliseconds: 40),
              duration: Durations.short3,
              begin: Offset(1, 1),
              end: Offset(2, 2),
              curve: Easing.emphasizedDecelerate,
            ),
          ],
          child: Icon(
            favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          ),
        ),
      ),
    );
  }
}

class _DownloadIndicator extends StatefulWidget {
  const _DownloadIndicator({
    // super.key,
    required this.downloadManager,
    required this.post,
  });

  final DownloadManager downloadManager;
  final PostImpl post;

  @override
  State<_DownloadIndicator> createState() => __DownloadIndicatorState();
}

class __DownloadIndicatorState extends State<_DownloadIndicator> {
  late final StreamSubscription<void> events;
  DownloadHandle? status;

  @override
  void initState() {
    events = widget.downloadManager.watch(
      (_) {
        setState(() {
          status =
              widget.downloadManager.statusFor(widget.post.fileDownloadUrl());
        });
      },
      true,
    );

    super.initState();
  }

  @override
  void dispose() {
    events.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    // final downloadStatus = status?.data.status;

    return status == null || status!.data.status == DownloadStatus.failed
        ? const SizedBox.shrink()
        : _LinearProgress(handle: status!);
  }
}

class _DownloadIcon extends StatefulWidget {
  const _DownloadIcon({
    // super.key,
    required this.downloadManager,
    required this.post,
  });

  final DownloadManager downloadManager;
  final PostImpl post;

  @override
  State<_DownloadIcon> createState() => __DownloadIconState();
}

class __DownloadIconState extends State<_DownloadIcon> {
  late final StreamSubscription<void> events;
  DownloadHandle? status;

  @override
  void initState() {
    events = widget.downloadManager.watch(
      (_) {
        setState(() {
          status =
              widget.downloadManager.statusFor(widget.post.fileDownloadUrl());
        });
      },
      true,
    );

    super.initState();
  }

  @override
  void dispose() {
    events.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final downloadStatus = status?.data.status;

    final icon = switch (downloadStatus) {
      null => const Icon(Icons.download_rounded),
      DownloadStatus.onHold => const Icon(Icons.download_rounded),
      DownloadStatus.failed => const Icon(Icons.file_download_off_rounded),
      DownloadStatus.inProgress => const Icon(Icons.downloading_rounded),
    };

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          onPressed: downloadStatus == DownloadStatus.onHold ||
                  downloadStatus == DownloadStatus.inProgress
              ? null
              : () {
                  if (downloadStatus == DownloadStatus.failed) {
                    widget.downloadManager
                        .restartAll([status!], SettingsService.db().current);
                  } else {
                    widget.post.download(
                      widget.downloadManager,
                      PostTags.fromContext(context),
                    );
                    WrapperSelectionAnimation.tryPlayOf(context);
                  }
                },
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(
              downloadStatus == DownloadStatus.inProgress ||
                      downloadStatus == DownloadStatus.onHold
                  ? const CircleBorder()
                  : const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
            ),
            foregroundColor: WidgetStateProperty.fromMap(
              {
                WidgetState.disabled: theme.disabledColor,
                WidgetState.any:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
              },
            ),
            backgroundColor: WidgetStateProperty.fromMap({
              WidgetState.disabled:
                  theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.8),
              WidgetState.any:
                  theme.colorScheme.surfaceContainer.withValues(alpha: 0.8),
            }),
          ),
          icon: icon,
        ),
        if (status != null && downloadStatus == DownloadStatus.inProgress)
          _Progress(handle: status!),
      ],
    );
  }
}

class _LinearProgress extends StatefulWidget {
  const _LinearProgress({
    // super.key,
    required this.handle,
  });

  final DownloadHandle handle;

  @override
  State<_LinearProgress> createState() => __LinearProgressState();
}

class __LinearProgressState extends State<_LinearProgress> {
  late final StreamSubscription<void> subscription;

  double? progress;

  @override
  void initState() {
    super.initState();

    subscription = widget.handle.watchProgress((i) {
      setState(() {
        progress = i;
      });
    });
  }

  @override
  void dispose() {
    subscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Animate(
      autoPlay: true,
      effects: const [
        FadeEffect(
          duration: Durations.medium4,
          curve: Easing.standard,
          begin: 0,
          end: 1,
        ),
      ],
      child: LinearProgressIndicator(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        minHeight: 2,
        year2023: false,
        value: progress,
      ),
    );
  }
}

class _Progress extends StatefulWidget {
  const _Progress({
    // super.key,
    required this.handle,
  });

  final DownloadHandle handle;

  @override
  State<_Progress> createState() => __ProgressState();
}

class __ProgressState extends State<_Progress> {
  late final StreamSubscription<void> subscription;

  double? progress;

  @override
  void initState() {
    super.initState();

    subscription = widget.handle.watchProgress((i) {
      setState(() {
        progress = i;
      });
    });
  }

  @override
  void dispose() {
    subscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 38,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        value: progress,
      ),
    );
  }
}

mixin PinnedSortedTagsArrayMixin<S extends StatefulWidget> on State<S> {
  List<String> get postTags;

  List<({String tag, bool pinned})> _tags = [];
  List<({String tag, bool pinned})> get tags => _tags;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (postTags.isEmpty) {
      return;
    }

    final tags = PinnedTagsProvider.of(context);
    final postTags_ = postTags.toList();
    final pinnedTags = <String>[];
    postTags_.removeWhere((e) {
      if (tags.$1.containsKey(e)) {
        pinnedTags.add(e);

        return true;
      }

      return false;
    });

    _tags = pinnedTags
        .map((e) => (tag: e, pinned: true))
        .followedBy(postTags_.map((e) => (tag: e, pinned: false)))
        // .take(10)
        .toList();

    setState(() {});
  }
}
