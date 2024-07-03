// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/booru/safe_mode.dart";
import "package:gallery/src/pages/booru/booru_page.dart";
import "package:gallery/src/pages/more/settings/radio_dialog.dart";
import "package:gallery/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";

class ImageViewAppBar extends StatelessWidget {
  const ImageViewAppBar({
    super.key,
    required this.controller,
    required this.actions,
  });
  final List<Widget> actions;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final currentCell = CurrentContentNotifier.of(context);

    return Animate(
      effects: const [
        SlideEffect(
          duration: Duration(milliseconds: 500),
          curve: Easing.emphasizedAccelerate,
          begin: Offset.zero,
          end: Offset(0, -1),
        ),
      ],
      autoPlay: false,
      controller: controller,
      child: IgnorePointer(
        ignoring: !AppBarVisibilityNotifier.of(context),
        child: Column(
          children: [
            Expanded(
              child: AppBar(
                bottom: const _BottomLoadIndicator(
                  preferredSize: Size.fromHeight(4 + 18 + 8),
                  child: SizedBox.shrink(),
                ),
                scrolledUnderElevation: 0,
                automaticallyImplyLeading: false,
                leading: const BackButton(),
                title: GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: currentCell.widgets.alias(false),
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.copiedClipboard,
                        ),
                      ),
                    );
                  },
                  child: Text(currentCell.widgets.alias(false)),
                ),
                actions: Scaffold.of(context).hasEndDrawer
                    ? [
                        ...actions,
                        IconButton(
                          onPressed: () {
                            Scaffold.of(context).openEndDrawer();
                          },
                          icon: const Icon(Icons.info_outline),
                        ),
                      ]
                    : actions,
              ),
            ),
          ],
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
      child: SizedBox(
        height: 18,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (stickers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  left: 8,
                ),
                child: Row(
                  children: stickers
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(
                            right: 8,
                          ),
                          child: Icon(
                            e.icon,
                            size: 16,
                            color: e.important
                                ? colorScheme.secondary
                                : colorScheme.onSurface.withOpacity(
                                    0.6,
                                  ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              )
            else
              const SizedBox.shrink(),
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: _PinnedTagsRow(),
            ),
          ],
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == 1)
          const SizedBox.shrink()
        else
          LinearProgressIndicator(
            minHeight: 4,
            value: status,
          ),
        const _BottomRibbon(),
      ],
    );
  }
}

class _PinnedTagsRow extends StatelessWidget {
  const _PinnedTagsRow();

  @override
  Widget build(BuildContext context) {
    final tags = ImageTagsNotifier.of(context)
        .where((element) => element.favorite)
        .take(2);
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
              padding: const EdgeInsets.only(left: 8, right: 8),
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
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary.withOpacity(0.65),
                  ),
                ),
              ),
            ),
          ),
        )
        .toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
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

class _BottomSheetButton extends StatefulWidget {
  const _BottomSheetButton({
    required this.bottomSheetController,
    required this.minSize,
  });
  final DraggableScrollableController bottomSheetController;
  final double minSize;

  @override
  State<_BottomSheetButton> createState() => __BottomSheetButtonState();
}

class __BottomSheetButtonState extends State<_BottomSheetButton> {
  bool facingUpward = true;

  DraggableScrollableController get bottomSheetController =>
      widget.bottomSheetController;

  @override
  void initState() {
    super.initState();

    bottomSheetController.addListener(listener);
  }

  @override
  void dispose() {
    bottomSheetController.removeListener(listener);

    super.dispose();
  }

  void listener() {
    if (bottomSheetController.size > widget.minSize && facingUpward == true) {
      setState(() {
        facingUpward = false;
      });
    } else if (bottomSheetController.size <= widget.minSize &&
        facingUpward == false) {
      setState(() {
        facingUpward = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      padding: EdgeInsets.zero,
      onPressed: () {
        if (bottomSheetController.size > widget.minSize) {
          bottomSheetController.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Easing.emphasizedAccelerate,
          );
        } else {
          bottomSheetController.animateTo(
            1,
            duration: const Duration(milliseconds: 200),
            curve: Easing.emphasizedDecelerate,
          );
        }
      },
      icon: Animate(
        autoPlay: false,
        target: facingUpward ? 0 : 1,
        effects: [
          const FadeEffect(
            begin: 1,
            end: 0,
            curve: Easing.standard,
          ),
          SwapEffect(
            builder: (_, __) {
              return const Icon(
                size: 18,
                Icons.keyboard_arrow_down_rounded,
              ).animate().fadeIn(curve: Easing.standard);
            },
          ),
        ],
        child: const Icon(
          size: 18,
          Icons.keyboard_arrow_up_rounded,
        ),
      ),
    );
  }
}
