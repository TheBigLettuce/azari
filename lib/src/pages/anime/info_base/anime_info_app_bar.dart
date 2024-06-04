// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:gallery/src/pages/anime/anime.dart";
import "package:gallery/src/widgets/image_view/image_view.dart";

class AnimeInfoAppBar extends StatefulWidget {
  const AnimeInfoAppBar({
    super.key,
    required this.cell,
    required this.scrollController,
    this.appBarActions = const [],
  });
  final AnimeCell cell;
  final ScrollController scrollController;
  final List<Widget> appBarActions;

  @override
  State<AnimeInfoAppBar> createState() => _AnimeInfoAppBarState();
}

class _AnimeInfoAppBarState extends State<AnimeInfoAppBar>
    with SingleTickerProviderStateMixin {
  late final animation = AnimationController(
    animationBehavior: AnimationBehavior.preserve,
    vsync: this,
    duration: 300.ms,
    reverseDuration: 300.ms,
    value: 0,
  );

  bool _opaqueAppBar = false;

  @override
  void initState() {
    super.initState();

    animation.addListener(() {
      setState(() {});
    });

    widget.scrollController.addListener(_animate);
  }

  void _animate() {
    if (widget.scrollController.offset != 0 && !_opaqueAppBar) {
      animation.animateTo(1, curve: Easing.standard);
      _opaqueAppBar = true;
    } else if (widget.scrollController.offset == 0 && _opaqueAppBar) {
      animation.animateBack(0, curve: Easing.standard);
      _opaqueAppBar = false;
    }
  }

  @override
  void dispose() {
    animation.dispose();
    widget.scrollController.removeListener(_animate);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      title: Text(
        widget.cell.alias(false),
        style: TextStyle(
          color: colorScheme.onSurface.withOpacity(
            clampDouble(
              Easing.emphasizedAccelerate.transform(animation.value),
              0,
              1,
            ),
          ),
        ),
      ),
      actions: [
        ...widget.appBarActions,
        IconButton(
          onPressed: () {
            ImageView.launchWrapped(
              context,
              1,
              (__) => widget.cell.openImage(),
            );
          },
          icon: const Icon(Icons.image),
        ),
      ],
      surfaceTintColor: colorScheme.surface.withOpacity(0),
      backgroundColor: ColorTween(
        begin: colorScheme.surface.withOpacity(0),
        end: colorScheme.surface.withOpacity(0.8),
      ).transform(Easing.emphasizedAccelerate.transform(animation.value)),
      // title: Text(widget.entry.title),
    );
  }
}
