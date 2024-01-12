// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:gallery/src/pages/anime/info_base/anime_name_widget.dart';

import 'left_arrow.dart';
import 'right_arrow.dart';

class CardShell extends StatefulWidget {
  final List<Widget> buttons;
  final List<Widget> info;
  final AnimeEntry entry;
  final EdgeInsets viewPadding;

  const CardShell({
    super.key,
    required this.entry,
    required this.viewPadding,
    required this.info,
    required this.buttons,
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

  List<Widget> _insertBlanks(List<Widget> from, List<Widget> compared) {
    if (from.length == compared.length) {
      final res = <Widget>[];
      for (final e in from.indexed) {
        res.add(e.$2);
        res.add(compared[e.$1]);
      }

      return res;
    }

    final res = <Widget>[];
    for (final e in from.indexed) {
      res.add(e.$2);
      res.add(compared.elementAtOrNull(e.$1) ?? const SizedBox.shrink());
    }

    return res;
  }

  List<Widget> _merge() {
    return _insertBlanks(widget.info, widget.buttons);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2 +
          kToolbarHeight +
          widget.viewPadding.top +
          MediaQuery.sizeOf(context).height * 0.3,
      child: Padding(
        padding: EdgeInsets.only(
            top: 2 + kToolbarHeight + widget.viewPadding.top,
            left: 22,
            right: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimeNameWidget(entry: widget.entry),
            Theme(
              data: Theme.of(context).copyWith(
                  iconTheme: IconThemeData(
                      color:
                          Theme.of(context).iconTheme.color?.withOpacity(0.8))),
              child: Expanded(
                  child: Stack(
                children: [
                  GridView(
                    controller: cardsController,
                    scrollDirection: Axis.horizontal,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2),
                    children: _merge(),
                  ),
                  LeftArrow(show: _showArrorLeft),
                  RightArrow(show: _showArrowRight),
                ],
              )),
            )
          ],
        ),
      ),
    );
  }
}
