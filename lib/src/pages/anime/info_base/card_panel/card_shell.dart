// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/anime/anime_api.dart';
import 'package:gallery/src/pages/anime/info_base/anime_name_widget.dart';

class CardShell extends StatefulWidget {
  final List<Widget> info;
  final EdgeInsets viewPadding;

  final String title;
  final String titleEnglish;
  final String titleJapanese;
  final List<String> titleSynonyms;
  final AnimeSafeMode safeMode;

  const CardShell({
    super.key,
    required this.title,
    required this.titleEnglish,
    required this.titleJapanese,
    required this.titleSynonyms,
    required this.safeMode,
    required this.viewPadding,
    required this.info,
  });

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
    return DefaultTextStyle.merge(
      style: TextStyle(
        color: widget.safeMode == AnimeSafeMode.h ||
                widget.safeMode == AnimeSafeMode.ecchi
            ? Colors.pink.withOpacity(0.8)
            : Theme.of(context).colorScheme.primary.withOpacity(0.8),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: 2 + kToolbarHeight + widget.viewPadding.top,
          left: 22,
          right: 22,
        ),
        child: Column(
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
              data: Theme.of(context).copyWith(
                  iconTheme: IconThemeData(
                      color:
                          Theme.of(context).iconTheme.color?.withOpacity(0.8))),
              child: SizedBox(
                height: 80,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.all(Radius.elliptical(40, 40)),
                  clipBehavior: Clip.antiAlias,
                  child: ListView(
                    clipBehavior: Clip.none,
                    controller: cardsController,
                    scrollDirection: Axis.horizontal,
                    children: widget.info,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
