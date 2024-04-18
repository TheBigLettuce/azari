// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/interfaces/cell/contentable.dart';
import 'package:gallery/src/interfaces/cell/sticker.dart';
import 'package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_action_button.dart';
import 'package:gallery/src/widgets/notifiers/current_content.dart';

import '../notifiers/app_bar_visibility.dart';

class ImageViewBottomAppBar extends StatelessWidget {
  const ImageViewBottomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final widgets = CurrentContentNotifier.of(context).widgets;
    final stickers = widgets.tryAsStickerable(context, true);
    final actions = widgets.tryAsActionable(context);

    if (actions.isEmpty && stickers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Animate(
        effects: const [
          SlideEffect(
            duration: Duration(milliseconds: 500),
            curve: Easing.emphasizedAccelerate,
            begin: Offset(0, 0),
            end: Offset(0, 1),
          )
        ],
        autoPlay: false,
        target: AppBarVisibilityNotifier.of(context) ? 0 : 1,
        child: IgnorePointer(
          ignoring: !AppBarVisibilityNotifier.of(context),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              const SizedBox(
                  height: 80,
                  child: AbsorbPointer(
                    child: SizedBox.shrink(),
                  )),
              BottomAppBar(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        children: actions
                            .map(
                              (e) => WrapGridActionButton(
                                e.icon,
                                () {
                                  e.onPress(CurrentContentNotifier.of(context));
                                },
                                false,
                                play: e.play,
                                color: e.color,
                                onLongPress: null,
                                animate: e.animate,
                                whenSingleContext: null,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    if (stickers.isNotEmpty) FiveStickers(stickers: stickers),
                  ],
                ),
              )
            ],
          ),
        ));
  }
}

class FiveStickers extends StatelessWidget {
  final List<Sticker> stickers;

  const FiveStickers({
    super.key,
    required this.stickers,
  });

  @override
  Widget build(BuildContext context) {
    final l = <Widget>[];
    for (final (i, e) in stickers.indexed) {
      if (l.length == 5) {
        break;
      }

      l.add(Align(
        alignment: switch (i) {
          0 => Alignment.topLeft,
          1 => Alignment.topRight,
          2 => Alignment.bottomRight,
          3 => Alignment.bottomLeft,
          4 => Alignment.center,
          int() => throw "unreachable",
        },
        child: SizedBox(
          height: 20,
          width: 20,
          child: i == 4
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        Theme.of(context).colorScheme.surface.withOpacity(0.2),
                  ),
                  child: Icon(
                    e.icon,
                    size: 20,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.8),
                  ),
                )
              : Icon(
                  e.icon,
                  size: 20,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
        ),
      ));
    }

    return SizedBox(
      height: 40,
      width: 40,
      child: Stack(
        children: l,
      ),
    );
  }
}
