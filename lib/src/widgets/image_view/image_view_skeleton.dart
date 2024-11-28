// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/pages/booru/booru_page.dart";
import "package:azari/src/pages/other/settings/radio_dialog.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/wrappers/wrap_grid_action_button.dart";
import "package:azari/src/widgets/image_view/image_view.dart";
import "package:azari/src/widgets/image_view/image_view_fab.dart";
import "package:azari/src/widgets/image_view/image_view_notifiers.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";

class ImageViewSkeleton extends StatefulWidget {
  const ImageViewSkeleton({
    super.key,
    required this.controller,
    required this.scaffoldKey,
    required this.bottomSheetController,
    required this.next,
    required this.prev,
    required this.videoControls,
    required this.wrapNotifiers,
    required this.pauseVideoState,
    required this.child,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final AnimationController controller;
  final DraggableScrollableController bottomSheetController;
  final PauseVideoState pauseVideoState;

  final VoidCallback next;
  final VoidCallback prev;

  final VideoControlsControllerImpl videoControls;

  final NotifierWrapper? wrapNotifiers;

  final Widget child;

  @override
  State<ImageViewSkeleton> createState() => _ImageViewSkeletonState();
}

class _ImageViewSkeletonState extends State<ImageViewSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController visibilityController;

  final GlobalKey<SeekTimeAnchorState> seekTimeAnchor = GlobalKey();

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
  Widget build(BuildContext context) {
    final widgets = CurrentContentNotifier.of(context).widgets;
    final stickers = widgets.tryAsStickerable(context, true);
    final b = widgets.tryAsAppBarButtonable(context);

    final viewPadding = MediaQuery.viewPaddingOf(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _ExitOnPressRoute(
      scaffoldKey: widget.scaffoldKey,
      child: Scaffold(
        key: widget.scaffoldKey,
        extendBodyBehindAppBar: true,
        extendBody: true,
        endDrawerEnableOpenDragGesture: false,
        resizeToAvoidBottomInset: false,
        body: AnnotatedRegion(
          value: SystemUiOverlayStyle(
            statusBarColor: colorScheme.surface.withValues(alpha: 0.4),
            statusBarIconBrightness: colorScheme.brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarIconBrightness:
                colorScheme.brightness == Brightness.dark
                    ? Brightness.light
                    : Brightness.dark,
            systemNavigationBarColor:
                colorScheme.surface.withValues(alpha: 0.4),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            fit: StackFit.passthrough,
            children: [
              widget.child,
              Builder(
                builder: (context) {
                  final status = LoadingProgressNotifier.of(context);

                  return status == 1
                      ? const SizedBox.shrink()
                      : Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.onSurfaceVariant,
                            backgroundColor: theme.colorScheme.surfaceContainer
                                .withValues(alpha: 0.4),
                            value: status,
                          ),
                        );
                },
              ),
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
                    child: SizedBox(
                      height: 100,
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
                            BackButton(
                              style: ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll(
                                  colorScheme.surface,
                                ),
                              ),
                            ),
                            Row(
                              children: widgets
                                  .tryAsAppBarButtonable(context)
                                  .reversed
                                  .map(
                                    (e) => Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: IconButton(
                                        onPressed: e.onPressed,
                                        icon: Icon(e.icon),
                                        style: ButtonStyle(
                                          backgroundColor:
                                              WidgetStatePropertyAll(
                                            colorScheme.surface,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
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
              if (!(stickers.isEmpty && b.isEmpty && widgets is! Infoable))
                _BottomIcons(
                  videoControls: widget.videoControls,
                  viewPadding: viewPadding,
                  bottomSheetController: widget.bottomSheetController,
                  visibilityController: visibilityController,
                  seekTimeAnchor: seekTimeAnchor,
                  wrapNotifiers: widget.wrapNotifiers,
                  pauseVideoState: widget.pauseVideoState,
                ),
              SeekTimeAnchor(
                key: seekTimeAnchor,
                bottomPadding: viewPadding.top,
                videoControls: widget.videoControls,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomIcons extends StatefulWidget {
  const _BottomIcons({
    // super.key,
    required this.viewPadding,
    required this.bottomSheetController,
    required this.visibilityController,
    required this.videoControls,
    required this.seekTimeAnchor,
    required this.wrapNotifiers,
    required this.pauseVideoState,
  });

  final EdgeInsets viewPadding;

  final AnimationController visibilityController;

  final GlobalKey<SeekTimeAnchorState> seekTimeAnchor;
  final VideoControlsControllerImpl videoControls;
  final NotifierWrapper? wrapNotifiers;
  final PauseVideoState pauseVideoState;

  final DraggableScrollableController bottomSheetController;

  @override
  State<_BottomIcons> createState() => __BottomIconsState();
}

class __BottomIconsState extends State<_BottomIcons>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final widgets = CurrentContentNotifier.of(context).widgets;
    final actions = widgets.tryAsActionable(context);

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
            padding: EdgeInsets.only(bottom: widget.viewPadding.bottom + 18) +
                const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: 56,
                    child: Column(
                      key: widgets.uniqueKey(),
                      mainAxisSize: MainAxisSize.min,
                      children: actions.reversed
                          .map(
                            (e) => WrapGridActionButton(
                              e.icon,
                              e.onPress == null
                                  ? null
                                  : () => e.onPress!(
                                        CurrentContentNotifier.of(context),
                                      ),
                              onLongPress: null,
                              play: e.play,
                              animate: e.animate,
                              color: e.color,
                              watch: e.watch,
                              animation: e.animation,
                              notifier: e.longLoadingNotifier,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _BottomRibbon(),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      VideoControls(
                        videoControls: widget.videoControls,
                        db: DatabaseConnectionNotifier.of(context)
                            .videoSettings,
                        seekTimeAnchor: widget.seekTimeAnchor,
                        vertical: false,
                      ),
                      const Padding(padding: EdgeInsets.only(bottom: 8)),
                      if (widgets.tryAsInfoable(context) != null)
                        ImageViewFab(
                          wrapNotifiers: widget.wrapNotifiers,
                          widgets: widgets,
                          bottomSheetController: widget.bottomSheetController,
                          viewPadding: widget.viewPadding,
                          visibilityController: widget.visibilityController,
                          pauseVideoState: widget.pauseVideoState,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomRibbon extends StatelessWidget {
  const _BottomRibbon(
      // {super.key}
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stickers = CurrentContentNotifier.of(context)
        .widgets
        .tryAsStickerable(context, true);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PinnedTagsRow(
            tags: ImageTagsNotifier.of(context),
          ),
          const Padding(padding: EdgeInsets.only(bottom: 16)),
          Padding(
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
                                      padding: EdgeInsets.only(right: 4),
                                    ),
                                    Text(
                                      e.subtitle!,
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
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
          ),
        ],
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

class __PinnedTagsRowState extends State<_PinnedTagsRow> {
  late final StreamSubscription<void> events;

  @override
  void initState() {
    super.initState();

    events = widget.tags.stream.listen((_) {
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
    final tagsRes = widget.tags;
    final pinnedTags = tagsRes.list.where((e) => e.favorite);

    final l10n = AppLocalizations.of(context)!;

    final tagsReady = pinnedTags
        .map(
          (e) => PinnedTagChip(
            tag: e.tag,
            onPressed: tagsRes.res == null
                ? null
                : () {
                    OnBooruTagPressed.maybePressOf(
                      context,
                      e.tag,
                      tagsRes.res!.booru,
                    );
                  },
            onLongPressed: tagsRes.res == null
                ? null
                : () {
                    radioDialog<SafeMode>(
                      context,
                      SafeMode.values.map((e) => (e, e.translatedString(l10n))),
                      SettingsService.db().current.safeMode,
                      (value) {
                        OnBooruTagPressed.maybePressOf(
                          context,
                          e.tag,
                          tagsRes.res!.booru,
                          overrideSafeMode: value,
                        );
                      },
                      title: l10n.chooseSafeMode,
                      allowSingle: true,
                    );
                  },
          ),
        )
        .toList();

    return Wrap(
      runSpacing: 6,
      spacing: 4,
      children: tagsReady.isEmpty || tagsReady.length == 1
          ? tagsReady
          : [
              ...tagsReady.take(tagsReady.length - 1).map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: e,
                    ),
                  ),
              tagsReady.last,
            ],
    );
  }
}

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
      "#${tag.length > letterCount ? "${tag.substring(0, letterCount - (letterCount < 10 ? 2 : 3))}${letterCount < 10 ? '..' : '...'}" : tag}",
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
          shadows: kElevationToShadow[1],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              tight ? const Radius.circular(5) : const Radius.circular(10),
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
    required this.tag,
    required this.isPinned,
    this.letterCount = 10,
  });

  final bool isPinned;

  final int letterCount;

  final String tag;

  final VoidCallback? onPressed;
  final VoidCallback? onLongPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final textColor = isPinned
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary.withValues(alpha: 0.8);

    return GestureDetector(
      onTap: onPressed,
      onLongPress: onLongPressed,
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
            "#${tag.length > letterCount ? "${tag.substring(0, letterCount - (letterCount < 10 ? 2 : 3))}${letterCount < 10 ? '..' : '...'}" : tag}",
            style: theme.textTheme.labelSmall?.copyWith(
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

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ExitOnPressRoute(
      exit: () => _exit(context),
      child: child,
    );
  }
}

class _AnimatedRailIcon extends StatefulWidget {
  const _AnimatedRailIcon({
    // super.key,
    required this.action,
  });

  final ImageViewAction action;

  @override
  State<_AnimatedRailIcon> createState() => __AnimatedRailIconState();
}

class __AnimatedRailIconState extends State<_AnimatedRailIcon> {
  ImageViewAction get action => widget.action;

  @override
  Widget build(BuildContext context) {
    return WrapGridActionButton(
      action.icon,
      action.onPress == null
          ? null
          : () => action.onPress!(CurrentContentNotifier.of(context)),
      onLongPress: null,
      play: action.play,
      animate: action.animate,
      animation: action.animation,
      watch: action.watch,
      color: action.color,
      notifier: action.longLoadingNotifier,
      iconOnly: true,
    );
  }
}
