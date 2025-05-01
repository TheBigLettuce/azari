// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/ui/material/widgets/action_button.dart";
import "package:azari/src/ui/material/widgets/grid_cell/cell.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view_fab.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/ui/material/widgets/shimmer_loading_indicator.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:go_router/go_router.dart";
import "package:scrollable_positioned_list/scrollable_positioned_list.dart";

class ImageViewSkeleton extends StatefulWidget {
  const ImageViewSkeleton({
    super.key,
    required this.controller,
    required this.scaffoldKey,
    required this.videoControls,
    required this.pauseVideoState,
    required this.stateControler,
    required this.returnBack,
    required this.child,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final AnimationController controller;
  final PauseVideoState pauseVideoState;

  final VideoControlsControllerImpl videoControls;
  final ImageViewStateController stateControler;

  final VoidCallback returnBack;

  final Widget child;

  @override
  State<ImageViewSkeleton> createState() => _ImageViewSkeletonState();
}

class _ImageViewSkeletonState extends State<ImageViewSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController visibilityController;
  late final thumbnailsBarShowEvents = StreamController<void>.broadcast();

  final GlobalKey<SeekTimeAnchorState> seekTimeAnchor = GlobalKey();

  bool isWide = false;

  @override
  void initState() {
    super.initState();

    visibilityController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    visibilityController.dispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final width = MediaQuery.sizeOf(context).width;

    isWide = width >= 450;
  }

  @override
  Widget build(BuildContext context) {
    // CurrentIndexMetadata.of(context);

    final viewPadding = MediaQuery.viewPaddingOf(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: colorScheme.surface.withValues(alpha: 0.4),
      statusBarIconBrightness: colorScheme.brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarIconBrightness:
          colorScheme.brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
      systemNavigationBarColor: colorScheme.surface.withValues(alpha: 0.4),
    );

    final loader = ImageViewLoaderProvider.of(context);

    return _ExitOnPressRoute(
      scaffoldKey: widget.scaffoldKey,
      child: Scaffold(
        key: widget.scaffoldKey,
        extendBodyBehindAppBar: true,
        extendBody: true,
        endDrawerEnableOpenDragGesture: false,
        resizeToAvoidBottomInset: false,
        body: AnnotatedRegion(
          value: overlayStyle,
          child: Stack(
            alignment: Alignment.bottomCenter,
            fit: StackFit.passthrough,
            children: [
              widget.child,
              Animate(
                effects: const [
                  SlideEffect(
                    duration: Duration(milliseconds: 500),
                    curve: Easing.emphasizedAccelerate,
                    begin: Offset.zero,
                    end: Offset(0, -1),
                  ),
                ],
                autoPlay: false,
                controller: widget.controller,
                child: IgnorePointer(
                  ignoring: !AppBarVisibilityNotifier.of(context),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 56 + viewPadding.top,
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ) +
                                EdgeInsets.only(top: viewPadding.top),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    BackButton(
                                      onPressed: widget.returnBack,
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStatePropertyAll(
                                          colorScheme.surface,
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                    ),
                                    _CountButton(
                                      loader: loader,
                                      showThumbnailsBar: () =>
                                          thumbnailsBarShowEvents.add(null),
                                    ),
                                  ],
                                ),
                                const _AppBarButtons(),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: _ThumbnailsBar(
                            loader: loader,
                            events: thumbnailsBarShowEvents.stream,
                            stateControler: widget.stateControler,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 80,
                child: AbsorbPointer(
                  child: SizedBox.shrink(),
                ),
              ),
              _BottomIcons(
                videoControls: isWide ? null : widget.videoControls,
                viewPadding: viewPadding,
                // visibilityController: visibilityController,
                seekTimeAnchor: seekTimeAnchor,
                // pauseVideoState: widget.pauseVideoState,
              ),
              SeekTimeAnchor(
                key: seekTimeAnchor,
                bottomPadding: viewPadding.top,
                videoControls: widget.videoControls,
              ),
              if (isWide)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: viewPadding.bottom),
                    child: VideoControls(
                      videoControls: widget.videoControls,
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

class _AppBarButtons extends StatelessWidget {
  const _AppBarButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final widgets = ImageViewWidgetsNotifier.of(context);

    return IconButtonTheme(
      data: IconButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(
            theme.colorScheme.surface,
          ),
        ),
      ),
      child: Row(
        key: widgets.uniqueKey(),
        children: widgets.appBarButtons(context),
      ),
    );
  }
}

class _ThumbnailsBar extends StatefulWidget {
  const _ThumbnailsBar({
    // super.key,
    required this.events,
    required this.stateControler,
    required this.loader,
  });

  final ImageViewLoader loader;

  final ImageViewStateController stateControler;
  final Stream<void> events;

  @override
  State<_ThumbnailsBar> createState() => __ThumbnailsBarState();
}

class __ThumbnailsBarState extends State<_ThumbnailsBar>
    with SingleTickerProviderStateMixin, ImageViewLoaderWatcher {
  @override
  ImageViewLoader get loader => widget.loader;

  late final AnimationController controller;
  late final StreamSubscription<void> _events;
  final itemPositionListener = ItemPositionsListener.create();
  final itemScrollController = ItemScrollController();

  bool isExpanded = false;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Durations.medium1,
    );

    _events = widget.events.listen((_) {
      if (controller.isForwardOrCompleted) {
        controller.reverse();
      } else {
        controller.forward().then((_) {
          scrollTo(loader.index);
        });
      }
    });
  }

  @override
  void dispose() {
    _events.cancel();
    controller.dispose();

    super.dispose();
  }

  void scrollTo(int idx, [bool force = false]) {
    final positions = itemPositionListener.itemPositions.value.toList();

    if (force) {
      itemScrollController.scrollTo(
        alignment: 0.5,
        index: idx,
        duration: Durations.extralong1,
        curve: Easing.emphasizedDecelerate,
      );

      return;
    }

    final isVisisble = positions.indexWhere(
          (e) =>
              e.index == idx &&
              !e.itemLeadingEdge.isNegative &&
              e.itemTrailingEdge < 1,
        ) !=
        -1;

    if (!isVisisble) {
      itemScrollController.scrollTo(
        alignment: 0.5,
        index: idx,
        duration: Durations.extralong1,
        curve: Easing.emphasizedDecelerate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Animate(
      autoPlay: false,
      controller: controller,
      effects: const [
        FadeEffect(duration: Durations.medium1, begin: 0, end: 1),
      ],
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: 100,
          child: AnimatedBuilder(
            animation: controller.view,
            builder: (context, child) => IgnorePointer(
              ignoring: controller.isDismissed,
              child: ScrollConfiguration(
                behavior: const _NoBallisticScrollBehaviour(),
                child: ScrollablePositionedList.builder(
                  itemScrollController: itemScrollController,
                  itemPositionsListener: itemPositionListener,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.isDismissed ? 0 : loader.count,
                  itemBuilder: (context, index) {
                    final widgets = loader.get(index)!;

                    return _ThumbnailBarChild(
                      thisIdx: index,
                      isSelected: loader.index == index,
                      widgets: widgets,
                      seekTo: (i) {
                        widget.stateControler.seekTo(index);
                        // scrollTo(index, true);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoBallisticScrollBehaviour extends MaterialScrollBehavior {
  const _NoBallisticScrollBehaviour();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _ThumbnailBarChild extends StatelessWidget {
  const _ThumbnailBarChild({
    // super.key,
    required this.isSelected,
    required this.widgets,
    required this.seekTo,
    required this.thisIdx,
  });

  final bool isSelected;
  final int thisIdx;

  final ImageViewWidgets widgets;

  final void Function(int i) seekTo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnail = widgets.thumbnail();

    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(15)),
      onTap: isSelected
          ? null
          : () {
              seekTo(thisIdx);
            },
      child: SizedBox(
        width: 100,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: AnimatedPhysicalModel(
            clipBehavior: Clip.antiAlias,
            color: theme.colorScheme.surface,
            shadowColor: Colors.black,
            borderRadius: isSelected
                ? const BorderRadius.all(Radius.circular(15))
                : BorderRadius.zero,
            elevation: isSelected ? 3 : 1,
            duration: Durations.medium3,
            child: AnimatedContainer(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: isSelected
                    ? const BorderRadius.all(Radius.circular(15))
                    : BorderRadius.zero,
              ),
              duration: Durations.medium3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumbnail == null)
                    const ShimmerLoadingIndicator()
                  else
                    Image(
                      frameBuilder: (
                        context,
                        child,
                        frame,
                        wasSynchronouslyLoaded,
                      ) {
                        if (wasSynchronouslyLoaded) {
                          return child;
                        }

                        return frame == null
                            ? const ShimmerLoadingIndicator()
                            : child.animate().fadeIn();
                      },
                      image: thumbnail,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            theme.colorScheme.surfaceContainer
                                .withValues(alpha: 0.8),
                            theme.colorScheme.surfaceContainer
                                .withValues(alpha: 0.6),
                            theme.colorScheme.surfaceContainer
                                .withValues(alpha: 0.4),
                            theme.colorScheme.surfaceContainer
                                .withValues(alpha: 0.2),
                            theme.colorScheme.surfaceContainer
                                .withValues(alpha: 0),
                          ],
                        ),
                      ),
                      child: const SizedBox(
                        height: 40,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        (thisIdx + 1).toString(),
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountButton extends StatefulWidget {
  const _CountButton({
    super.key,
    required this.showThumbnailsBar,
    required this.loader,
  });

  final ImageViewLoader loader;
  final VoidCallback showThumbnailsBar;

  @override
  State<_CountButton> createState() => __CountButtonState();
}

class __CountButtonState extends State<_CountButton>
    with ImageViewLoaderWatcher {
  @override
  ImageViewLoader get loader => widget.loader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // final metadata = CurrentIndexMetadata.of(context);

    return SizedBox(
      height: 40,
      child: Center(
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: GestureDetector(
            onTap: widget.showThumbnailsBar,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text.rich(
                  TextSpan(
                    text: "${loader.index + 1}",
                    children: [
                      TextSpan(
                        text: "/${loader.count}",
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  style: theme.textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomIcons extends StatelessWidget {
  const _BottomIcons({
    // super.key,
    required this.viewPadding,
    required this.videoControls,
    required this.seekTimeAnchor,
  });

  final EdgeInsets viewPadding;

  final GlobalKey<SeekTimeAnchorState> seekTimeAnchor;
  final VideoControlsControllerImpl? videoControls;

  @override
  Widget build(BuildContext context) {
    final openInfo = ImageViewWidgetsNotifier.of(context).openInfo();

    return Animate(
      value: 1,
      target: AppBarVisibilityNotifier.of(context) ? 1 : 0,
      effects: const [
        FadeEffect(
          duration: Durations.medium3,
          curve: Easing.standard,
          begin: 0.5,
          end: 1,
        ),
      ],
      child: SizedBox(
        width: double.infinity,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: viewPadding.bottom)
            // + const EdgeInsets.symmetric(horizontal: 16)
            ,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Align(
                          alignment: Alignment.bottomCenter,
                          child: _Actions(),
                        ),
                        const Align(
                          alignment: Alignment.bottomCenter,
                          child: _Stickers(),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (videoControls != null)
                                VideoControls(
                                  videoControls: videoControls!,
                                  seekTimeAnchor: seekTimeAnchor,
                                  vertical: false,
                                ),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                              ),
                              if (openInfo != null)
                                ImageViewFab(openBottomSheet: openInfo),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const _BottomRibbon(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({super.key});

  @override
  Widget build(BuildContext context) {
    final widgets = ImageViewWidgetsNotifier.of(context);
    final actions = widgets.actions(context);

    return SizedBox(
      width: 56,
      child: Column(
        key: widgets.uniqueKey(),
        mainAxisSize: MainAxisSize.min,
        children: actions.reversed
            .map(
              (e) => ActionButton(
                e.icon,
                e.onPress == null
                    ? null
                    : () {
                        AppBarVisibilityNotifier.maybeToggleOf(
                          context,
                          true,
                        );

                        e.onPress!();
                      },
                onLongPress: null,
                play: e.play,
                animate: e.animate,
                color: e.color,
                watch: e.watch,
                animation: e.animation,
                taskTag: e.taskTag,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Stickers extends StatelessWidget {
  const _Stickers({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final widgets = ImageViewWidgetsNotifier.of(context);
    final stickers = widgets.stickers(context);

    return Padding(
      padding: const EdgeInsets.only(
        left: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: stickers
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(
                  right: 8,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: theme.colorScheme.surface,
                  ),
                  child: Padding(
                    padding: e.subtitle != null
                        ? const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          )
                        : const EdgeInsets.all(4),
                    child: e.subtitle != null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                e.icon,
                                size: 10,
                                color: e.important
                                    ? colorScheme.secondary
                                    : colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(
                                  right: 4,
                                ),
                              ),
                              Text(
                                e.subtitle!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: e.important
                                      ? colorScheme.secondary
                                      : colorScheme.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                                ),
                              ),
                            ],
                          )
                        : Icon(
                            e.icon,
                            size: 16,
                            color: e.important
                                ? colorScheme.secondary
                                : colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                          ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _BottomRibbon extends StatelessWidget {
  const _BottomRibbon({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      curve: Easing.standard,
      duration: Durations.medium1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: _PinnedTagsRow(
          tags: ImageTagsNotifier.of(context),
        ),
      ),
    );
  }
}

class _PinnedTagsRow extends StatefulWidget {
  const _PinnedTagsRow({
    // super.key,
    required this.tags,
  });

  final ImageViewTags tags;

  @override
  State<_PinnedTagsRow> createState() => __PinnedTagsRowState();
}

class __PinnedTagsRowState extends State<_PinnedTagsRow>
    with SingleTickerProviderStateMixin {
  late final StreamSubscription<void> events;
  List<ImageTag> pinnedTagList = const [];

  @override
  void initState() {
    super.initState();

    pinnedTagList = widget.tags.list
        .where((e) => e.type == ImageTagType.favorite)
        // .followedBy(
        //   widget.tags.list.where((e) => e.type != ImageTagType.favorite),
        // )
        .toList();

    events = widget.tags.stream.listen((_) {
      pinnedTagList = widget.tags.list
          .where((e) => e.type == ImageTagType.favorite)
          // .followedBy(
          //   widget.tags.list.where((e) => e.type != ImageTagType.favorite),
          // )
          .toList();
      setState(() {});
    });
  }

  @override
  void dispose() {
    events.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Durations.medium4,
      reverseDuration: Durations.medium1,
      switchInCurve: Easing.standardAccelerate,
      switchOutCurve: Easing.standardDecelerate,
      child: KeyedSubtree(
        key: ValueKey(pinnedTagList),
        child: pinnedTagList.isEmpty
            ? const SizedBox.shrink()
            : SizedBox(
                height: 26,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: pinnedTagList.length,
                  itemBuilder: (context, index) {
                    final tag = pinnedTagList[index];

                    return Padding(
                      padding: EdgeInsets.only(
                        right: index != pinnedTagList.length - 1 ? 8 : 0,
                      ),
                      child: PinnedTagChip(
                        letterCount: -1,
                        tag: tag.tag,
                        onPressed: tag.onTap != null
                            ? () => tag.onTap!(context)
                            : null,
                        onLongPressed: tag.onLongTap != null
                            ? () => tag.onLongTap!(context)
                            : null,
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

//  context.openSafeModeDialog((value) {
//                                 OnBooruTagPressed.maybePressOf(
//                                   context,
//                                   tag.tag,
//                                   tagsRes.res!.booru,
//                                   overrideSafeMode: value,
//                                 );
//                               });

class PinnedTagChip extends StatelessWidget {
  const PinnedTagChip({
    super.key,
    this.onPressed,
    this.onLongPressed,
    required this.tag,
    this.tight = false,
    this.letterCount = 10,
    this.mildlyTransculent = false,
    this.addPinnedIcon = false,
  });

  final bool tight;
  final bool mildlyTransculent;
  final bool addPinnedIcon;

  final int letterCount;

  final String tag;

  final VoidCallback? onPressed;
  final VoidCallback? onLongPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final textColor = theme.colorScheme.secondary.withValues(alpha: 0.65);
    final boxColor = mildlyTransculent
        ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.8)
        : theme.colorScheme.surfaceContainerHigh;

    final text = Text(
      "#${(tag.length > letterCount) && !letterCount.isNegative ? "${tag.substring(0, letterCount - (letterCount < 10 ? 2 : 3))}${letterCount < 10 ? '..' : '...'}" : tag}",
      style: (tight ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)
          ?.copyWith(
        color: textColor,
        overflow: TextOverflow.fade,
      ),
    );

    return GestureDetector(
      onTap: onPressed,
      onLongPress: onLongPressed,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shadows: kElevationToShadow[2],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              tight ? const Radius.circular(5) : const Radius.circular(6),
            ),
          ),
          color: boxColor,
        ),
        child: Padding(
          padding: tight
              ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
              : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: addPinnedIcon
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.push_pin_rounded, size: 8),
                    text,
                  ],
                )
              : text,
        ),
      ),
    );
  }
}

class OutlinedTagChip extends StatelessWidget {
  const OutlinedTagChip({
    super.key,
    this.onPressed,
    this.onLongPressed,
    this.onDoublePressed,
    required this.tag,
    required this.isPinned,
    this.letterCount = 10,
  });

  final bool isPinned;

  final int letterCount;

  final String tag;

  final VoidCallback? onPressed;
  final VoidCallback? onLongPressed;
  final VoidCallback? onDoublePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final textColor = isPinned
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary.withValues(alpha: 0.8);

    return GestureDetector(
      onTap: onPressed,
      onLongPress: onLongPressed,
      onDoubleTap: onDoublePressed,
      child: DecoratedBox(
        decoration: const ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            letterCount.isNegative
                ? tag
                : "#${tag.length > letterCount ? "${tag.substring(0, letterCount - (letterCount < 10 ? 2 : 3))}${letterCount < 10 ? '..' : '...'}" : tag}",
            style: theme.textTheme.labelMedium?.copyWith(
              color: textColor,
              overflow: TextOverflow.fade,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExitOnPressRoute extends StatelessWidget {
  const _ExitOnPressRoute({
    // super.key,
    required this.scaffoldKey,
    required this.child,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  final Widget child;

  void _exit(BuildContext context) {
    final scaffold = scaffoldKey.currentState;
    if (scaffold != null && scaffold.isEndDrawerOpen) {
      scaffold.closeEndDrawer();
    }

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return ExitOnPressRoute(
      exit: () => _exit(context),
      child: child,
    );
  }
}
