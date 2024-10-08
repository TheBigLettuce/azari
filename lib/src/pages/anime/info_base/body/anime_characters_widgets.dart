// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/anime/anime_api.dart";
import "package:azari/src/pages/anime/info_base/body/body_segment_label.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_cell.dart";
import "package:azari/src/widgets/image_view/image_view.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

class AnimeCharactersWidget extends StatefulWidget
    with DbConnHandle<SavedAnimeCharactersService> {
  const AnimeCharactersWidget({
    super.key,
    required this.entry,
    required this.api,
    required this.db,
  });

  final AnimeEntryData entry;
  final AnimeAPI api;

  @override
  final SavedAnimeCharactersService db;

  @override
  State<AnimeCharactersWidget> createState() => _AnimeCharactersWidgetState();
}

class _AnimeCharactersWidgetState extends State<AnimeCharactersWidget>
    with AnimeCharacterDbScope<AnimeCharactersWidget> {
  late final StreamSubscription<List<AnimeCharacter>?> watcher;
  bool _loading = false;
  List<AnimeCharacter> list = [];

  @override
  void initState() {
    super.initState();

    final l = load(widget.entry.id, widget.entry.site);
    if (l.isNotEmpty) {
      list.addAll(l);
    } else {
      addAsync(widget.entry, widget.api);
      _loading = true;
    }

    watcher = watch(widget.entry.id, widget.entry.site, (e) {
      list = e!;
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
    final l10n = AppLocalizations.of(context)!;

    if (list.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!_loading)
          BodySegmentLabel(
            text: l10n.charactersLabel,
            onLongPress: () {
              addAsync(widget.entry, widget.api);
              _loading = true;

              setState(() {});
            },
          ),
        if (_loading)
          const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          SizedBox(
            height: MediaQuery.sizeOf(context).longestSide * 0.2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: ListView(
                clipBehavior: Clip.none,
                scrollDirection: Axis.horizontal,
                children: list.indexed
                    .map(
                      (e) => SizedBox(
                        width: MediaQuery.sizeOf(context).longestSide *
                            0.2 *
                            GridAspectRatio.zeroFive.value,
                        child: CustomGridCellWrapper(
                          onPressed: (context) {
                            ImageView.launchWrapped(
                              context,
                              list.length,
                              (i) => list[i].openImage(),
                              startingCell: e.$1,
                            );
                          },
                          child: GridCell(
                            cell: e.$2,
                            secondaryTitle: e.$2.role,
                            hideTitle: false,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
      ],
    ).animate().fadeIn();
  }
}
