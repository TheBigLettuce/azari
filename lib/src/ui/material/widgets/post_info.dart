// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/resource_source/filtering_mode.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/impl/obj/post_impl.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/base/home.dart";
import "package:azari/src/ui/material/widgets/shimmer_placeholders.dart";
import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:url_launcher/url_launcher.dart" as url;
import "package:video_player/video_player.dart";

class PostInfo extends StatelessWidget {
  const PostInfo({super.key, required this.post});

  final PostImpl post;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(padding: EdgeInsets.only(top: 18)),
        ListBody(
          children: [
            DimensionsName(
              l10n: l10n,
              width: post.width,
              height: post.height,
              name: post.id.toString(),
              icon: post.type.toIcon(),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
            ),
            // StarsListTile(post: post),
            PostInfoTile(post: post),
            const Padding(padding: EdgeInsets.only(top: 4)),
            const Divider(indent: 24, endIndent: 24),
            PostActionChips(post: post),
          ],
        ),
      ],
    );
  }
}

class DimensionsName extends StatelessWidget {
  const DimensionsName({
    super.key,
    required this.l10n,
    required this.width,
    required this.height,
    required this.name,
    required this.icon,
    this.trailing = const [],
    this.onTap,
    this.onLongTap,
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(15)),
    ),
  });

  final int width;
  final int height;

  final String name;

  final List<Widget> trailing;

  final Icon icon;

  final ShapeBorder shape;

  final VoidCallback? onTap;
  final VoidCallback? onLongTap;

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongTap,
        shape: shape,
        tileColor: theme.colorScheme.surfaceContainerHigh,
        leading: icon,
        trailing: trailing.isEmpty
            ? null
            : Row(mainAxisSize: MainAxisSize.min, children: trailing),
        title: Text(name),
        subtitle: width == 0 && height == 0
            ? null
            : Text("$width x ${l10n.pixels(height)}"),
      ),
    );
  }
}

class FiveStarsRow extends StatefulWidget {
  const FiveStarsRow({super.key, required this.booru, required this.id});

  final Booru booru;
  final int id;

  @override
  State<FiveStarsRow> createState() => _FiveStarsRowState();
}

class _FiveStarsRowState extends State<FiveStarsRow>
    with FavoritePostSourceService, FavoritePostsWatcherMixin {
  late FavoritePost? post;

  @override
  void onFavoritePostsUpdate() {
    super.onFavoritePostsUpdate();

    post = cache.get((widget.id, widget.booru));
  }

  @override
  void initState() {
    super.initState();

    onFavoritePostsUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final post = this.post;
    if (post == null) {
      return const SizedBox.shrink();
    }
    return FiveStarsButtonsRow(post: post, color: null);
  }
}

class PostSimpleVideo extends StatefulWidget {
  const PostSimpleVideo({super.key, required this.post});

  final PostImpl post;

  @override
  State<PostSimpleVideo> createState() => _PostSimpleVideoState();
}

class _PostSimpleVideoState extends State<PostSimpleVideo> {
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

class PostInfoTile extends StatelessWidget {
  const PostInfoTile({
    super.key,
    required this.post,
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(15),
        bottomRight: Radius.circular(15),
      ),
    ),
  });

  final PostImpl post;

  final ShapeBorder shape;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListTile(
        shape: shape,
        tileColor: theme.colorScheme.surfaceContainerHigh,
        leading: const Icon(Icons.description_outlined),
        title: Text(post.booru.string),
        subtitle: PostInfoTileSubtitle(post: post),
      ),
    );
  }
}

class PostInfoTileSubtitle extends StatefulWidget {
  const PostInfoTileSubtitle({super.key, required this.post});

  final PostImpl post;

  @override
  State<PostInfoTileSubtitle> createState() => _PostInfoTileSubtitleState();
}

class _PostInfoTileSubtitleState extends State<PostInfoTileSubtitle>
    with FavoritePostSourceService, FavoritePostsWatcherMixin {
  late FavoritePost? post;

  @override
  void onFavoritePostsUpdate() {
    super.onFavoritePostsUpdate();

    post = cache.get((widget.post.id, widget.post.booru));
  }

  @override
  void initState() {
    super.initState();

    onFavoritePostsUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
    final theme = Theme.of(context);

    return Text.rich(
      TextSpan(
        text: widget.post.rating.translatedName(l10n),
        children: [
          const TextSpan(text: " • "),
          WidgetSpan(
            child: Padding(
              padding: const EdgeInsets.only(left: 2, right: 4),
              child: Icon(
                Icons.thumb_up_alt_rounded,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          TextSpan(text: "${widget.post.score}"),
          TextSpan(
            text:
                "\n${l10n.date(widget.post.createdAt)} ${post != null ? "\n" : ""}",
          ),
          if (post != null)
            WidgetSpan(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FiveStarsButtonsRow(post: post!, color: null),
              ),
            ),
        ],
      ),
    );
  }
}

class PostActionChips extends StatelessWidget {
  const PostActionChips({
    super.key,
    required this.post,
    this.appButtons = const [],
  });

  final PostImpl post;

  final List<Widget> appButtons;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          ...appButtons,
          ActionChip(
            onPressed: () => url.launchUrl(
              Uri.parse(post.fileDownloadUrl()),
              mode: url.LaunchMode.externalApplication,
            ),
            avatar: const Icon(Icons.open_in_new_rounded),
            label: Text(l10n.linkLabel),
          ),
          ActionChip(
            onPressed: () => const AppApi().shareMedia(post.fileDownloadUrl()),
            label: Text(l10n.shareLabel),
            avatar: const Icon(Icons.share_rounded, size: 18),
          ),
          ActionChip(
            onPressed: () => url.launchUrl(
              Uri.parse(post.sourceUrl),
              mode: url.LaunchMode.externalApplication,
            ),
            label: Text(l10n.sourceFileInfoPage),
            avatar: const Icon(Icons.open_in_new_rounded, size: 18),
          ),
          ActionChip(
            onPressed: () => url.launchUrl(
              post.booru.browserLink(post.id),
              mode: url.LaunchMode.externalApplication,
            ),
            label: Text(l10n.openOnBooru(post.booru.string)),
            avatar: const Icon(Icons.open_in_new_rounded, size: 18),
          ),
          if (post.tags.contains("translated"))
            TranslationNotesChip(postId: post.id, booru: post.booru),
        ],
      ),
    );
  }
}

class TranslationNotes extends StatefulWidget {
  const TranslationNotes({
    super.key,
    required this.booru,
    required this.postId,
  });

  final int postId;
  final Booru booru;

  static void open(
    BuildContext context, {
    required int postId,
    required Booru booru,
  }) {
    Navigator.of(context, rootNavigator: true).push<void>(
      DialogRoute(
        context: context,
        builder: (context) => TranslationNotes(postId: postId, booru: booru),
      ),
    );
  }

  @override
  State<TranslationNotes> createState() => _TranslationNotesState();
}

class _TranslationNotesState extends State<TranslationNotes> {
  late Future<Iterable<String>> f;
  late final BooruAPI api;

  @override
  void initState() {
    super.initState();

    api = BooruAPI.fromEnum(widget.booru);
    f = api.notes(widget.postId);
  }

  @override
  void dispose() {
    f.ignore();
    api.destroy();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return AlertDialog(
      title: Text(l10n.translationTitle),
      content: FutureBuilder(
        future: f,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: snapshot.data!
                    .map((e) => ListTile(title: Text(e)))
                    .toList(),
              ),
            );
          } else if (snapshot.hasError) {
            return Text(snapshot.error!.toString());
          }

          return SizedBox.fromSize(
            size: const Size.square(42),
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}

class TranslationNotesChip extends StatelessWidget {
  const TranslationNotesChip({
    super.key,
    required this.postId,
    required this.booru,
  });

  final int postId;
  final Booru booru;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return ActionChip(
      onPressed: () =>
          TranslationNotes.open(context, postId: postId, booru: booru),
      label: Text(l10n.hasTranslations),
      avatar: const Icon(Icons.open_in_new_rounded, size: 18),
    );
  }
}

class FiveStarsButtonsRow extends StatelessWidget {
  const FiveStarsButtonsRow({
    super.key,
    required this.post,
    required this.color,
  });

  final FavoritePost post;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 4,
      // mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        CubeButton(
          onPressed: () {
            if (post.stars == FavoriteStars.one) {
              post.copyWith(stars: FavoriteStars.zeroFive).maybeSave();
            } else if (post.stars == FavoriteStars.zeroFive) {
              post.copyWith(stars: FavoriteStars.zero).maybeSave();
            } else {
              post.copyWith(stars: FavoriteStars.one).maybeSave();
            }
          },
          icon: post.stars.includes(FavoriteStars.one)
              ? Icon(Icons.star_rounded, color: color)
              : post.stars.includes(FavoriteStars.zeroFive)
              ? Icon(Icons.star_half_rounded, color: color)
              : Icon(Icons.star_border_rounded, color: color),
        ),
        CubeButton(
          onPressed: () {
            if (post.stars == FavoriteStars.two) {
              post.copyWith(stars: FavoriteStars.oneFive).maybeSave();
            } else if (post.stars == FavoriteStars.oneFive) {
              post.copyWith(stars: FavoriteStars.one).maybeSave();
            } else {
              post.copyWith(stars: FavoriteStars.two).maybeSave();
            }
          },
          icon: post.stars.includes(FavoriteStars.two)
              ? Icon(Icons.star_rounded, color: color)
              : post.stars.includes(FavoriteStars.oneFive)
              ? Icon(Icons.star_half_rounded, color: color)
              : Icon(Icons.star_border_rounded, color: color),
        ),
        CubeButton(
          onPressed: () {
            if (post.stars == FavoriteStars.three) {
              post.copyWith(stars: FavoriteStars.twoFive).maybeSave();
            } else if (post.stars == FavoriteStars.twoFive) {
              post.copyWith(stars: FavoriteStars.two).maybeSave();
            } else {
              post.copyWith(stars: FavoriteStars.three).maybeSave();
            }
          },
          icon: post.stars.includes(FavoriteStars.three)
              ? Icon(Icons.star_rounded, color: color)
              : post.stars.includes(FavoriteStars.twoFive)
              ? Icon(Icons.star_half_rounded, color: color)
              : Icon(Icons.star_border_rounded, color: color),
        ),
        CubeButton(
          onPressed: () {
            if (post.stars == FavoriteStars.four) {
              post.copyWith(stars: FavoriteStars.threeFive).maybeSave();
            } else if (post.stars == FavoriteStars.threeFive) {
              post.copyWith(stars: FavoriteStars.three).maybeSave();
            } else {
              post.copyWith(stars: FavoriteStars.four).maybeSave();
            }
          },
          icon: post.stars.includes(FavoriteStars.four)
              ? Icon(Icons.star_rounded, color: color)
              : post.stars.includes(FavoriteStars.threeFive)
              ? Icon(Icons.star_half_rounded, color: color)
              : Icon(Icons.star_border_rounded, color: color),
        ),
        CubeButton(
          onPressed: () {
            if (post.stars == FavoriteStars.five) {
              post.copyWith(stars: FavoriteStars.fourFive).maybeSave();
            } else if (post.stars == FavoriteStars.fourFive) {
              post.copyWith(stars: FavoriteStars.four).maybeSave();
            } else {
              post.copyWith(stars: FavoriteStars.five).maybeSave();
            }
          },
          icon: post.stars.includes(FavoriteStars.five)
              ? Icon(Icons.star_rounded, color: color)
              : post.stars.includes(FavoriteStars.fourFive)
              ? Icon(Icons.star_half_rounded, color: color)
              : Icon(Icons.star_border_rounded, color: color),
        ),
      ],
    );
  }
}

class CubeButton extends StatelessWidget {
  const CubeButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.selected,
  });

  final VoidCallback onPressed;

  final bool? selected;
  final Icon icon;

  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconTheme(
      data: IconThemeData(
        color: theme.colorScheme.onSurfaceVariant,
        size: _iconSize,
      ),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: icon,
          ),
        ),
      ),
    );
  }
}

class ColorCubeButton extends StatelessWidget {
  const ColorCubeButton({
    super.key,
    required this.onTap,
    required this.color,
    this.size = 20,
    this.padding = const EdgeInsets.all(6),
    this.selected,
  });

  final VoidCallback onTap;

  final double size;
  final EdgeInsets padding;

  final Color color;

  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transparent = this.color == Colors.transparent;
    final color = this.color.withValues(
      alpha: transparent
          ? 0
          : selected != null && !selected!
          ? 0.45
          : 1,
    );
    final borderColor = theme.colorScheme.onSurface.withValues(
      alpha: selected != null && !selected! ? 0.2 : 0.8,
    );
    final shadowColor = theme.colorScheme.onSurface.withValues(
      alpha: transparent ? 0.2 : 1,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: AnimatedPhysicalModel(
          duration: Durations.medium1,
          curve: Easing.standard,
          elevation: selected != null
              ? selected!
                    ? 4
                    : 0
              : 4,
          shadowColor: shadowColor,
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          color: color,
          child: AnimatedContainer(
            width: size,
            height: size,
            duration: Durations.medium1,
            curve: Easing.standard,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              border: Border.fromBorderSide(
                BorderSide(color: borderColor, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ColorCube extends StatefulWidget {
  const ColorCube({super.key, required this.idBooru, required this.source});

  final ResourceSource<int, PostImpl>? source;

  final (int, Booru) idBooru;

  @override
  State<ColorCube> createState() => _ColorCubeState();
}

class _ColorCubeState extends State<ColorCube>
    with _SingleFavoritePost, FavoritePostSourceService {
  late final StreamSubscription<int>? _countEvents;

  @override
  (int, Booru) get idBooru => widget.idBooru;

  final menuController = MenuController();

  bool hide = false;

  @override
  void initState() {
    super.initState();

    _countEvents = widget.source?.backingStorage.watch((e) {
      menuController.close();
    });
  }

  @override
  void dispose() {
    _countEvents?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = this.post;
    if (post == null) {
      return const SizedBox.shrink();
    }

    final color = post.filteringColors == FilteringColors.noColor
        ? theme.colorScheme.surfaceContainer
        : post.filteringColors.color;

    return MenuAnchor(
      onClose: () {
        setState(() {
          hide = false;
        });
      },
      onOpen: () {
        setState(() {
          hide = true;
        });
      },
      controller: menuController,
      consumeOutsideTap: true,
      alignmentOffset: const Offset(-(46 / 2) + 3, -20 - 6),
      clipBehavior: Clip.none,
      style: MenuStyle(
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(
          theme.colorScheme.surface.withValues(alpha: 0),
        ),
        alignment: Alignment.bottomLeft,
      ),
      menuChildren: [
        ColorCubeMenu(
          menuController: menuController,
          post: post,
        ).animate().fadeIn(),
      ],
      child: Visibility(
        visible: !hide,
        maintainState: true,
        child: ColorCubeButton(
          onTap: () => menuController.open(),
          color: color,
        ),
      ),
    );
  }
}

mixin _SingleFavoritePost<W extends StatefulWidget> on State<W>
    implements FavoritePostSourceService {
  late final StreamSubscription<void>? favoriteEvents;

  FavoritePost? post;

  (int id, Booru booru) get idBooru;

  @override
  void initState() {
    super.initState();

    post = cache.get(idBooru);

    favoriteEvents = cache.streamSingle(idBooru.$1, idBooru.$2).listen((e) {
      setState(() {
        post = cache.get(idBooru);
      });
    });
  }

  @override
  void dispose() {
    favoriteEvents?.cancel();

    super.dispose();
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
      if (tags.map.containsKey(e)) {
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

class ColorCubeMenu extends StatefulWidget {
  const ColorCubeMenu({
    super.key,
    required this.menuController,
    required this.post,
  });

  final MenuController menuController;
  final FavoritePost post;

  static Future<void> openChangeColorNameDialog(
    BuildContext context,
    FilteringColors e,
  ) {
    return Navigator.of(context, rootNavigator: true).push(
      DialogRoute<void>(
        context: context,
        builder: (context) {
          final l10n = context.l10n();
          final colorsNames = const ColorsNamesService().current;

          return AlertDialog(
            title: Text(
              l10n.changeColorTo(e.translatedString(l10n, colorsNames)),
            ),
            content: TextField(
              onSubmitted: (value) {
                switch (e) {
                  case FilteringColors.red:
                    colorsNames.copy(red: value).maybeSave();
                  case FilteringColors.blue:
                    colorsNames.copy(blue: value).maybeSave();
                  case FilteringColors.yellow:
                    colorsNames.copy(yellow: value).maybeSave();
                  case FilteringColors.green:
                    colorsNames.copy(green: value).maybeSave();
                  case FilteringColors.purple:
                    colorsNames.copy(purple: value).maybeSave();
                  case FilteringColors.orange:
                    colorsNames.copy(orange: value).maybeSave();
                  case FilteringColors.pink:
                    colorsNames.copy(pink: value).maybeSave();
                  case FilteringColors.white:
                    colorsNames.copy(white: value).maybeSave();
                  case FilteringColors.brown:
                    colorsNames.copy(brown: value).maybeSave();
                  case FilteringColors.black:
                    colorsNames.copy(black: value).maybeSave();
                  case FilteringColors.noColor:
                }

                Navigator.of(context, rootNavigator: true).pop();
              },
            ),
          );
        },
      ),
    );
  }

  @override
  State<ColorCubeMenu> createState() => _ColorCubeMenuState();
}

class _ColorCubeMenuState extends State<ColorCubeMenu>
    with ColorsNamesWatcherMixin {
  MenuController get menuController => widget.menuController;
  FavoritePost get post => widget.post;

  List<FilteringColors> colors = const [];

  final scrollController = ScrollController();

  @override
  void onNewColorsNames() => _filterColors();

  @override
  void initState() {
    super.initState();

    _filterColors();
  }

  @override
  void dispose() {
    scrollController.dispose();

    super.dispose();
  }

  void _filterColors() {
    colors = FilteringColors.values
        .where((e) => e != widget.post.filteringColors)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: ((colors.length * 20) / 2) + ((colors.length * 6) / 2),
      width: 46,
      child: GridView.builder(
        controller: scrollController,
        itemCount: colors.length,
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          crossAxisCount: 2,
        ),
        itemBuilder: (context, idx) {
          final e = colors[idx];
          final color = e.color.harmonizeWith(theme.colorScheme.primary);

          return GestureDetector(
            onTap: () {
              menuController.close();

              post.copyWith(filteringColors: e).maybeSave();
            },
            onLongPress: () {
              menuController.close();

              ColorCubeMenu.openChangeColorNameDialog(
                context,
                e,
              ).whenComplete(() => menuController.open());
            },
            child: Padding(
              padding: EdgeInsets.zero,
              child: SizedBox.square(
                dimension: 20,
                child: PhysicalModel(
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  shadowColor: theme.colorScheme.onSurfaceVariant,
                  elevation: 2,
                  color: color,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.fromBorderSide(
                        BorderSide(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                    ),
                    child: const SizedBox(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
