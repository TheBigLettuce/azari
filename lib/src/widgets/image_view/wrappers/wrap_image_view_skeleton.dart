// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_action_button.dart";
import "package:gallery/src/widgets/image_view/app_bar/app_bar.dart";
import "package:gallery/src/widgets/image_view/bottom_bar.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";

class WrapImageViewSkeleton extends StatefulWidget {
  const WrapImageViewSkeleton({
    super.key,
    required this.controller,
    required this.scaffoldKey,
    required this.bottomSheetController,
    required this.child,
    required this.next,
    required this.prev,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final AnimationController controller;
  final DraggableScrollableController bottomSheetController;

  final void Function() next;
  final void Function() prev;

  final Widget child;

  static double minPixelsFor(BuildContext context) {
    final widgets = CurrentContentNotifier.of(context).widgets;
    final viewPadding = MediaQuery.viewPaddingOf(context);

    return minPixels(widgets, viewPadding);
  }

  static double minPixels(ContentWidgets widgets, EdgeInsets viewPadding) =>
      widgets is! Infoable
          ? 80 + viewPadding.bottom
          : (80 + viewPadding.bottom);

  @override
  State<WrapImageViewSkeleton> createState() => _WrapImageViewSkeletonState();
}

class _WrapImageViewSkeletonState extends State<WrapImageViewSkeleton> {
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

    return Scaffold(
      key: widget.scaffoldKey,
      extendBodyBehindAppBar: true,
      extendBody: true,
      endDrawerEnableOpenDragGesture: false,
      resizeToAvoidBottomInset: false,
      bottomNavigationBar:
          showRail || (stickers.isEmpty && b.isEmpty && widgets is! Infoable)
              ? null
              : _BottomNavigationBar(
                  widgets: widgets,
                  viewPadding: viewPadding,
                  bottomSheetController: widget.bottomSheetController,
                ),
      appBar: showRail
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight + 4 + 18 + 8),
              child: ImageViewAppBar(
                actions: b,
                controller: widget.controller,
              ),
            ),
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
          ? widget.child
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
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: viewPadding.top),
                    child: const _BottomLoadIndicator(
                      preferredSize: Size.fromHeight(4),
                      child: SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
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
                child: IconButton.filledTonal(
                  onPressed: () {
                    scaffoldKey.currentState?.openEndDrawer();
                  },
                  icon: const Icon(Icons.info_outlined),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }
}

class _BottomNavigationBar extends StatelessWidget {
  const _BottomNavigationBar({
    // super.key,
    required this.widgets,
    required this.viewPadding,
    required this.bottomSheetController,
  });

  final ContentWidgets widgets;
  final EdgeInsets viewPadding;

  final DraggableScrollableController bottomSheetController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Animate(
      effects: const [
        SlideEffect(
          duration: Duration(milliseconds: 500),
          curve: Easing.emphasizedAccelerate,
          begin: Offset.zero,
          end: Offset(0, 1),
        ),
      ],
      autoPlay: false,
      target: AppBarVisibilityNotifier.of(context) ? 0 : 1,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(15),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.98),
          ),
          child: IgnorePointer(
            ignoring: !AppBarVisibilityNotifier.of(context),
            child: ImageViewBottomAppBar(
              addInfoFab: true,
              viewPadding: viewPadding,
              bottomSheetController: bottomSheetController,
            ),
          ),
        ),
      ),
    );
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
  });

  final ContentWidgets widgets;
  final AnimationController controller;

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
          trailing: ListBody(
            children: widgets.tryAsAppBarButtonable(context),
          ),
          destinations: [
            const NavigationRailDestination(
              icon: Icon(Icons.image),
              label: Text(""), // TODO: think about it
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
      () => action.onPress(CurrentContentNotifier.of(context)),
      onLongPress: null,
      whenSingleContext: null,
      play: action.play,
      animate: action.animate,
      animation: action.animation,
      watch: action.watch,
      color: action.color,
      iconOnly: true,
    );
  }
}
