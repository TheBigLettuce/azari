// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/services.dart";
import "package:azari/src/pages/anime/anime_info_page.dart";
import "package:azari/src/pages/anime/info_base/body/body_segment_label.dart";
import "package:azari/src/pages/anime/search_anime.dart";
import "package:azari/src/widgets/menu_wrapper.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

class AnimeRelations extends StatelessWidget {
  const AnimeRelations({super.key, required this.entry});
  final AnimeEntryData entry;

  @override
  Widget build(BuildContext context) {
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
                  title: e.title,
                  child: TextButton(
                    onPressed: () {
                      if (AnimeRelation.idIsValid(e)) {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) {
                              return AnimeInfoPage(
                                id: e.id,
                                apiFactory: entry.site.api,
                                db: DatabaseConnectionNotifier.of(context),
                              );
                            },
                          ),
                        );

                        return;
                      }

                      SearchAnimePage.launchAnimeApi(
                        context,
                        entry.site.api,
                        search: e.title,
                        safeMode: entry.explicit,
                      );
                    },
                    child: Text(
                      e.type.isNotEmpty ? "${e.title} (${e.type})" : e.title,
                      overflow: TextOverflow.fade,
                    ),
                  ),
                ),
              ),
            ],
          );
  }
}
