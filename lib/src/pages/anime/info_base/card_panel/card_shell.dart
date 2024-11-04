// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/net/anime/anime_api.dart";
import "package:azari/src/pages/anime/info_base/anime_name_widget.dart";
import "package:flutter/material.dart";

class CardShell extends StatefulWidget {
  const CardShell({
    super.key,
    required this.title,
    required this.titleEnglish,
    required this.titleJapanese,
    required this.titleSynonyms,
    required this.safeMode,
    required this.viewPadding,
    required this.info,
  }) : _sliver = false;

  const CardShell.sliver({
    super.key,
    required this.title,
    required this.titleEnglish,
    required this.titleJapanese,
    required this.titleSynonyms,
    required this.safeMode,
    required this.viewPadding,
    required this.info,
  }) : _sliver = true;

  final List<Widget> info;
  final EdgeInsets viewPadding;

  final String title;
  final String titleEnglish;
  final String titleJapanese;
  final List<String> titleSynonyms;
  final AnimeSafeMode safeMode;

  final bool _sliver;

  @override
  State<CardShell> createState() => _CardShellState();
}

class _CardShellState extends State<CardShell> {
  final cardsController = ScrollController();

  bool _showArrowRight = true;
  bool _showArrorLeft = false;

  @override
  void initState() {
    super.initState();

    cardsController.addListener(() {
      if (cardsController.offset > 0 && !_showArrorLeft) {
        _showArrorLeft = true;

        setState(() {});
      } else if (cardsController.offset == 0 && _showArrorLeft) {
        _showArrorLeft = false;

        setState(() {});
      }

      if (cardsController.position.maxScrollExtent == cardsController.offset &&
          _showArrowRight) {
        _showArrowRight = false;

        setState(() {});
      } else if (cardsController.position.maxScrollExtent !=
              cardsController.offset &&
          !_showArrowRight) {
        _showArrowRight = true;

        setState(() {});
      }
    });

    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      if (cardsController.position.maxScrollExtent == 0) {
        _showArrowRight = false;

        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    cardsController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final child = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimeNameWidget(
          title: widget.title,
          titleEnglish: widget.titleEnglish,
          titleJapanese: widget.titleJapanese,
          titleSynonyms: widget.titleSynonyms,
          safeMode: widget.safeMode,
        ),
        Theme(
          data: theme.copyWith(
            iconTheme: IconThemeData(
              color: theme.iconTheme.color?.withValues(alpha: 0.8),
            ),
          ),
          child: SizedBox(
            height: 80,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.elliptical(40, 40)),
              child: ListView(
                clipBehavior: Clip.none,
                controller: cardsController,
                scrollDirection: Axis.horizontal,
                children: widget.info,
              ),
            ),
          ),
        ),
      ],
    );

    final padding = EdgeInsets.only(
      top: 2 + kToolbarHeight + widget.viewPadding.top,
      left: 22,
      right: 22,
    );

    return DefaultTextStyle.merge(
      style: TextStyle(
        color: widget.safeMode == AnimeSafeMode.h ||
                widget.safeMode == AnimeSafeMode.ecchi
            ? Colors.pink.withValues(alpha: 0.8)
            : theme.colorScheme.secondary.withValues(alpha: 0.8),
      ),
      child: widget._sliver
          ? SliverPadding(
              padding: padding,
              sliver: SliverToBoxAdapter(
                child: child,
              ),
            )
          : Padding(
              padding: padding,
              child: child,
            ),
    );
  }
}
