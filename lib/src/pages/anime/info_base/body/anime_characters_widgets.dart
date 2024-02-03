// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/schemas/anime/saved_anime_characters.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:gallery/src/interfaces/grid/grid_aspect_ratio.dart';
import 'package:gallery/src/widgets/image_view/image_view.dart';
import 'package:gallery/src/widgets/grid/grid_cell.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'body_segment_label.dart';

class AnimeCharactersWidget extends StatefulWidget {
  final AnimeEntry entry;
  final Color? overlayColor;

  const AnimeCharactersWidget({
    super.key,
    required this.entry,
    required this.overlayColor,
  });

  @override
  State<AnimeCharactersWidget> createState() => _AnimeCharactersWidgetState();
}

class _AnimeCharactersWidgetState extends State<AnimeCharactersWidget> {
  late final StreamSubscription<SavedAnimeCharacters?> watcher;
  bool _loading = false;
  List<AnimeCharacter> list = [];

  @override
  void initState() {
    super.initState();

    final l = SavedAnimeCharacters.load(widget.entry.id, widget.entry.site);
    if (l.isNotEmpty) {
      list.addAll(l);
    } else {
      SavedAnimeCharacters.addAsync(widget.entry, widget.entry.site.api);
      _loading = true;
    }

    watcher =
        SavedAnimeCharacters.watch(widget.entry.id, widget.entry.site, (e) {
      list = e!.characters;
      _loading = false;

      setState(() {});
    });
  }

  @override
  void dispose() {
    watcher.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!_loading)
          BodySegmentLabel(text: AppLocalizations.of(context)!.charactersLabel),
        _loading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Wrap(
                  children: list.indexed
                      .map((e) => SizedBox(
                            height:
                                MediaQuery.sizeOf(context).longestSide * 0.2,
                            width: MediaQuery.sizeOf(context).longestSide *
                                0.2 *
                                GridAspectRatio.zeroFive.value,
                            child: GridCell(
                              cell: e.$2,
                              indx: e.$1,
                              forceAlias: e.$2.role,
                              onPressed: (context) {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (context) {
                                    return ImageView(
                                      updateTagScrollPos:
                                          (pos, selectedCell) {},
                                      cellCount: list.length,
                                      scrollUntill: (_) {},
                                      startingCell: e.$1,
                                      onExit: () {},
                                      getCell: (i) => list[i],
                                      onNearEnd: null,
                                      focusMain: () {},
                                      systemOverlayRestoreColor:
                                          widget.overlayColor ??
                                              Theme.of(context)
                                                  .colorScheme
                                                  .background,
                                    );
                                  },
                                ));
                              },
                              tight: false,
                              download: null,
                              isList: false,
                              labelAtBottom: true,
                            ),
                          ))
                      .toList(),
                ),
              ),
      ],
    ).animate().fadeIn();
  }
}
