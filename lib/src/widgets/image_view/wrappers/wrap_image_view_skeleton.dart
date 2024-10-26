// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/pages/booru/booru_page.dart";
import "package:azari/src/pages/more/settings/radio_dialog.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/wrappers/wrap_grid_action_button.dart";
import "package:azari/src/widgets/image_view/image_view.dart";
import "package:azari/src/widgets/image_view/sliding_info_drawer.dart";
import "package:azari/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

class WrapImageViewSkeleton extends StatefulWidget {
  const WrapImageViewSkeleton({
    super.key,
    required this.controller,
    required this.scaffoldKey,
    required this.bottomSheetController,
    required this.child,
    required this.next,
    required this.prev,
    required this.videoControls,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final AnimationController controller;
  final DraggableScrollableController bottomSheetController;

  final void Function() next;
  final void Function() prev;

  final VideoControlsControllerImpl videoControls;

  final Widget child;

  @override
  State<WrapImageViewSkeleton> createState() => _WrapImageViewSkeletonState();
}

class _WrapImageViewSkeletonState extends State<WrapImageViewSkeleton>
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

  bool showRail = false;
  bool showDrawer = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final width = MediaQuery.sizeOf(context).width;

    showRail = width >= 450;
    showDrawer = width >= 905;
  }

  @override
  Widget build(BuildContext context) {
    final widgets = CurrentContentNotifier.of(context).widgets;
    final stickers = widgets.tryAsStickerable(context, true);
    final b = widgets.tryAsAppBarButtonable(context);

    final viewPadding = MediaQuery.viewPaddingOf(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final infoWidget = widgets.tryAsInfoable(context);

    return _ExitOnPressRoute(
      scaffoldKey: widget.scaffoldKey,
      child: Scaffold(
        key: widget.scaffoldKey,
        extendBodyBehindAppBar: true,
        extendBody: true,
        endDrawerEnableOpenDragGesture: false,
        resizeToAvoidBottomInset: false,
        endDrawer: showRail
            ? (!showDrawer && infoWidget != null)
                ? _Drawer(
                    infoWidget: infoWidget,
                    viewPadding: viewPadding,
                    showDrawer: showDrawer,
                    next: widget.next,
                    prev: widget.prev,
                  )
                : null
            : null,
        body: !showRail
            ? AnnotatedRegion(
                value: SystemUiOverlayStyle(
                  statusBarColor: colorScheme.surface.withOpacity(0.4),
                  statusBarIconBrightness:
                      colorScheme.brightness == Brightness.dark
                          ? Brightness.light
                          : Brightness.dark,
                  systemNavigationBarIconBrightness:
                      colorScheme.brightness == Brightness.dark
                          ? Brightness.light
                          : Brightness.dark,
                  systemNavigationBarColor:
                      colorScheme.surface.withOpacity(0.4),
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
                                  backgroundColor: theme
                                      .colorScheme.surfaceContainer
                                      .withOpacity(0.4),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                            padding:
                                                const EdgeInsets.only(left: 8),
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
                    if (!(stickers.isEmpty &&
                        b.isEmpty &&
                        widgets is! Infoable))
                      _BottomIcons(
                        videoControls: widget.videoControls,
                        viewPadding: viewPadding,
                        bottomSheetController: widget.bottomSheetController,
                        visibilityController: visibilityController,
                        seekTimeAnchor: seekTimeAnchor,
                      ),
                    if (infoWidget != null)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Animate(
                          value: 0,
                          autoPlay: false,
                          controller: visibilityController,
                          effects: const [
                            FadeEffect(
                              curve: Easing.standard,
                              duration: Durations.long1,
                              begin: 0,
                              end: 1,
                            ),
                          ],
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15),
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surface.withOpacity(0.9),
                              ),
                              child: ImageViewSlidingInfoDrawer(
                                widgets: widgets,
                                bottomSheetController:
                                    widget.bottomSheetController,
                                viewPadding: viewPadding,
                              ),
                            ),
                          ),
                        ),
                      ),
                    SeekTimeAnchor(
                      key: seekTimeAnchor,
                      bottomPadding: viewPadding.top,
                      videoControls: widget.videoControls,
                    ),
                  ],
                ),
              )
            : AnnotatedRegion(
                value: SystemUiOverlayStyle(
                  statusBarColor: colorScheme.surface.withOpacity(0.8),
                ),
                child: Stack(
                  children: [
                    _InlineDrawer(
                      scaffoldKey: widget.scaffoldKey,
                      viewPadding: viewPadding,
                      infoWidget: infoWidget,
                      showDrawer: showDrawer,
                      next: widget.next,
                      prev: widget.prev,
                      child: widget.child,
                    ),
                    _NavigationRail(
                      controller: widget.controller,
                      widgets: widgets,
                      showDrawer: showDrawer,
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: viewPadding.top),
                      child: const _BottomLoadIndicator(
                        preferredSize: Size.fromHeight(4),
                        child: SizedBox.shrink(),
                      ),
                    ),
                    SeekTimeAnchor(
                      key: seekTimeAnchor,
                      bottomPadding: viewPadding.bottom + 60,
                      videoControls: widget.videoControls,
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: viewPadding.bottom),
                      child: VideoControls(
                        videoControls: widget.videoControls,
                        db: DatabaseConnectionNotifier.of(context)
                            .videoSettings,
                        seekTimeAnchor: seekTimeAnchor,
                        vertical: true,
                      ),
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
  });

  final EdgeInsets viewPadding;

  final AnimationController visibilityController;

  final GlobalKey<SeekTimeAnchorState> seekTimeAnchor;
  final VideoControlsControllerImpl videoControls;

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
                              whenSingleContext: null,
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
                          widgets: widgets,
                          bottomSheetController: widget.bottomSheetController,
                          viewPadding: widget.viewPadding,
                          visibilityController: widget.visibilityController,
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
          const _PinnedTagsRow(),
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
                                          : colorScheme.onSurface.withOpacity(
                                              0.6,
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
                                            : colorScheme.onSurface.withOpacity(
                                                0.6,
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
                                      : colorScheme.onSurface.withOpacity(
                                          0.6,
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

class _PinnedTagsRow extends StatelessWidget {
  const _PinnedTagsRow();

  @override
  Widget build(BuildContext context) {
    final tags =
        ImageTagsNotifier.of(context).where((element) => element.favorite);
    final theme = Theme.of(context);
    final res = ImageTagsNotifier.resOf(context);

    final l10n = AppLocalizations.of(context)!;

    final tagsReady = tags
        .map(
          (e) => DecoratedBox(
            decoration: ShapeDecoration(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              color: theme.colorScheme.surfaceContainerHigh,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: GestureDetector(
                onTap: res == null
                    ? null
                    : () {
                        OnBooruTagPressed.maybePressOf(
                          context,
                          e.tag,
                          res.booru,
                        );
                      },
                onLongPress: res == null
                    ? null
                    : () {
                        radioDialog<SafeMode>(
                          context,
                          SafeMode.values
                              .map((e) => (e, e.translatedString(l10n))),
                          SettingsService.db().current.safeMode,
                          (value) {
                            OnBooruTagPressed.maybePressOf(
                              context,
                              e.tag,
                              res.booru,
                              overrideSafeMode: value,
                            );
                          },
                          title: l10n.chooseSafeMode,
                          allowSingle: true,
                        );
                      },
                child: Text(
                  "#${e.tag.length > 10 ? "${e.tag.substring(0, 10 - 3)}..." : e.tag}",
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.secondary.withOpacity(0.65),
                  ),
                ),
              ),
            ),
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

class _InlineDrawer extends StatelessWidget {
  const _InlineDrawer({
    // super.key,
    required this.scaffoldKey,
    required this.viewPadding,
    required this.infoWidget,
    required this.showDrawer,
    required this.next,
    required this.prev,
    required this.child,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  final EdgeInsets viewPadding;

  final Widget? infoWidget;
  final bool showDrawer;

  final void Function() next;
  final void Function() prev;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (showDrawer) {
      return Stack(
        children: [
          child,
          if (infoWidget != null)
            Align(
              alignment: Alignment.centerRight,
              child: Animate(
                effects: const [
                  SlideEffect(
                    duration: Duration(milliseconds: 500),
                    curve: Easing.emphasizedAccelerate,
                    begin: Offset.zero,
                    end: Offset(1, 0),
                  ),
                ],
                autoPlay: false,
                target: AppBarVisibilityNotifier.of(context) ? 0 : 1,
                child: _Drawer(
                  infoWidget: infoWidget!,
                  viewPadding: viewPadding,
                  showDrawer: showDrawer,
                  next: next,
                  prev: prev,
                ),
              ),
            ),
        ],
      );
    } else {
      return Stack(
        children: [
          child,
          Align(
            alignment: Alignment.topRight,
            child: Animate(
              effects: const [
                SlideEffect(
                  duration: Duration(milliseconds: 500),
                  curve: Easing.emphasizedAccelerate,
                  begin: Offset.zero,
                  end: Offset(1, 0),
                ),
              ],
              autoPlay: false,
              target: AppBarVisibilityNotifier.of(context) ? 0 : 1,
              child: Padding(
                padding: const EdgeInsets.all(8) +
                    EdgeInsets.only(
                      top: viewPadding.top,
                    ),
                child: Stack(
                  alignment: Alignment.topRight,
                  fit: StackFit.passthrough,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 40 + 8),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: theme.colorScheme.surfaceContainer
                              .withOpacity(0.9),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () {
                        scaffoldKey.currentState?.openEndDrawer();
                      },
                      icon: const Icon(Icons.info_outlined),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
  }
}

class _Drawer extends StatelessWidget {
  const _Drawer({
    // super.key,
    required this.infoWidget,
    required this.viewPadding,
    required this.showDrawer,
    required this.next,
    required this.prev,
  });

  final EdgeInsets viewPadding;

  final Widget infoWidget;
  final bool showDrawer;

  final void Function() next;
  final void Function() prev;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      shape: const RoundedRectangleBorder(),
      backgroundColor: colorScheme.surface.withOpacity(0.9),
      child: CustomScrollView(
        slivers: [
          Builder(
            builder: (context) {
              final currentCell = CurrentContentNotifier.of(context);

              return SliverAppBar(
                actions: !showDrawer
                    ? const [SizedBox.shrink()]
                    : [
                        IconButton(
                          onPressed: prev,
                          icon: const Icon(Icons.navigate_before),
                        ),
                        IconButton(
                          onPressed: next,
                          icon: const Icon(Icons.navigate_next),
                        ),
                      ],
                scrolledUnderElevation: 0,
                automaticallyImplyLeading: false,
                title: GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: currentCell.widgets.alias(false),
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.copiedClipboard),
                      ),
                    );
                  },
                  child: Text(currentCell.widgets.alias(false)),
                ),
              );
            },
          ),
          infoWidget,
          SliverPadding(
            padding: EdgeInsets.only(bottom: viewPadding.bottom),
          ),
        ],
      ),
    );
  }
}

class _NavigationRail extends StatelessWidget {
  const _NavigationRail({
    // super.key,
    required this.widgets,
    required this.controller,
    required this.showDrawer,
  });

  final ContentWidgets widgets;
  final AnimationController controller;

  final bool showDrawer;

  @override
  Widget build(BuildContext context) {
    final actions = widgets.tryAsActionable(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Animate(
      key: widgets.uniqueKey(),
      autoPlay: false,
      controller: controller,
      effects: const [
        SlideEffect(
          duration: Duration(milliseconds: 500),
          curve: Easing.emphasizedAccelerate,
          begin: Offset.zero,
          end: Offset(-1, 0),
        ),
      ],
      child: SizedBox(
        height: double.infinity,
        width: 72,
        child: NavigationRail(
          backgroundColor: colorScheme.surface.withOpacity(0.9),
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
          ),
          groupAlignment: -0.8,
          destinations: [
            const NavigationRailDestination(
              icon: Icon(Icons.image),
              label: Text(""),
            ),
            if (actions.isEmpty)
              const NavigationRailDestination(
                disabled: true,
                icon: Icon(
                  Icons.image,
                  color: Colors.transparent,
                ),
                label: Text(""),
              )
            else
              ...actions.map(
                (e) => NavigationRailDestination(
                  disabled: true,
                  icon: _AnimatedRailIcon(action: e),
                  label: const Text(""),
                ),
              ),
          ],
          selectedIndex: 0,
        ),
      ),
    );
  }
}

class _BottomLoadIndicator extends PreferredSize {
  const _BottomLoadIndicator({
    required super.preferredSize,
    required super.child,
  });

  @override
  Widget build(BuildContext context) {
    final status = LoadingProgressNotifier.of(context);

    return status == 1
        ? child
        : LinearProgressIndicator(
            minHeight: 4,
            value: status,
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
      whenSingleContext: null,
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
