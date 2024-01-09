// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'anime_inner.dart';

class AnimeInnerAppBar extends StatefulWidget {
  final AnimeEntry entry;
  final ScrollController scrollController;
  final List<Widget> appBarActions;

  const AnimeInnerAppBar({
    super.key,
    required this.entry,
    required this.scrollController,
    this.appBarActions = const [],
  });

  @override
  State<AnimeInnerAppBar> createState() => _AnimeInnerAppBarState();
}

class _AnimeInnerAppBarState extends State<AnimeInnerAppBar>
    with SingleTickerProviderStateMixin {
  late final animation = AnimationController(
      animationBehavior: AnimationBehavior.preserve,
      vsync: this,
      duration: 300.ms,
      reverseDuration: 300.ms,
      value: 0);

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
    return AppBar(
      actions: [
        ...widget.appBarActions,
        IconButton(
          onPressed: () {
            final overlayColor =
                Theme.of(context).colorScheme.background.withOpacity(0.5);

            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return ImageView(
                  ignoreEndDrawer: false,
                  updateTagScrollPos: (_, __) {},
                  cellCount: 1,
                  scrollUntill: (_) {},
                  startingCell: 0,
                  onExit: () {},
                  getCell: (_) => widget.entry,
                  onNearEnd: null,
                  focusMain: () {},
                  systemOverlayRestoreColor: overlayColor,
                );
              },
            ));
          },
          icon: const Icon(Icons.image),
        )
      ],
      surfaceTintColor: Colors.transparent,
      backgroundColor: ColorTween(
              begin: Colors.transparent,
              end: Theme.of(context).colorScheme.background.withOpacity(0.8))
          .transform(animation.value),
      // title: Text(widget.entry.title),
    );
  }
}
