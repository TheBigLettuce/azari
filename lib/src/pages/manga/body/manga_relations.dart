// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/manga/manga_api.dart";
import "package:gallery/src/pages/anime/info_base/body/body_segment_label.dart";
import "package:gallery/src/pages/manga/manga_info_page.dart";
import "package:gallery/src/widgets/menu_wrapper.dart";

class MangaRelations extends StatelessWidget {
  const MangaRelations({
    super.key,
    required this.entry,
    required this.api,
    this.sliver = false,
  });
  final MangaAPI api;
  final MangaEntry entry;
  final bool sliver;

  @override
  Widget build(BuildContext context) {
    if (sliver) {
      return SliverMainAxisGroup(
        slivers: [
          BodySegmentLabel(
            text: AppLocalizations.of(context)!.relationsLabel,
            sliver: true,
          ),
          ...entry.relations.map(
            (e) => SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.centerLeft,
                child: MenuWrapper(
                  title: e.name,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) {
                            return MangaInfoPage(
                              id: e.id,
                              api: api,
                              db: DatabaseConnectionNotifier.of(context),
                            );
                          },
                        ),
                      );
                    },
                    child: Text(
                      e.name,
                      overflow: TextOverflow.fade,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return entry.relations.isEmpty
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BodySegmentLabel(
                text: AppLocalizations.of(context)!.relationsLabel,
              ),
              ...entry.relations.map(
                (e) => MenuWrapper(
                  title: e.name,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) {
                            return MangaInfoPage(
                              id: e.id,
                              api: api,
                              db: DatabaseConnectionNotifier.of(context),
                            );
                          },
                        ),
                      );
                    },
                    child: Text(
                      e.name,
                      overflow: TextOverflow.fade,
                    ),
                  ),
                ),
              ),
            ],
          );
  }
}
