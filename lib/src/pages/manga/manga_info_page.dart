// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/manga/manga_api.dart";
import "package:gallery/src/pages/anime/info_base/always_loading_anime_mixin.dart";
import "package:gallery/src/pages/anime/info_base/anime_info_app_bar.dart";
import "package:gallery/src/pages/anime/info_base/anime_info_theme.dart";
import "package:gallery/src/pages/anime/info_base/background_image/background_image.dart";
import "package:gallery/src/pages/anime/info_base/card_panel/card_shell.dart";
import "package:gallery/src/pages/manga/body/manga_info_body.dart";
import "package:gallery/src/pages/more/dashboard/dashboard_card.dart";
import "package:gallery/src/widgets/skeletons/settings.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";
import "package:sliver_tools/sliver_tools.dart";
import "package:url_launcher/url_launcher.dart";

class MangaInfoPage extends StatefulWidget {
  const MangaInfoPage({
    super.key,
    required this.id,
    required this.api,
    this.entry,
    required this.db,
  });

  final MangaId id;
  final MangaAPI api;
  final MangaEntry? entry;

  final DbConn db;

  @override
  State<MangaInfoPage> createState() => _MangaInfoPageState();
}

class _MangaInfoPageState extends State<MangaInfoPage>
    with TickerProviderStateMixin {
  CompactMangaDataService get compactManga => widget.db.compactManga;
  PinnedMangaService get pinnedManga => widget.db.pinnedManga;

  final state = SkeletonState();
  final scrollController = ScrollController();
  double? score;
  Future<void>? scoreFuture;

  late bool isPinned = pinnedManga.exist(widget.id.toString(), widget.api.site);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    scoreFuture?.ignore();

    state.dispose();

    super.dispose();
  }

  Future<MangaEntry> newFuture() {
    if (widget.entry != null) {
      scoreFuture = widget.api.score(widget.entry!).then((value) {
        score = value;

        setState(() {});
      }).onError((error, stackTrace) {
        score = -1;

        setState(() {});
      });
      return Future.value(widget.entry!);
    }

    return widget.api.single(widget.id).then((value) {
      isPinned = pinnedManga.exist(value.id.toString(), value.site);
      compactManga.addAll([
        objFactory.makeCompactMangaData(
          mangaId: value.id.toString(),
          site: value.site,
          thumbUrl: value.thumbUrl,
          title: value.title,
        ),
      ]);

      if (score == null || score!.isNegative) {
        scoreFuture = widget.api.score(value).then((value) {
          score = value;

          setState(() {});
        }).onError((error, stackTrace) {
          score = -1;

          setState(() {});
        });
      }

      return value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cardUnknownValue = l10n.cardUnknownValue;

    return WrapFutureRestartable(
      newStatus: newFuture,
      builder: (context, entry) {
        return AnimeInfoTheme(
          mode: entry.safety,
          child: SettingsSkeleton(
            l10n.mangaInfoPage,
            state,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: AnimeInfoAppBar(
                cell: entry,
                scrollController: scrollController,
              ),
            ),
            extendBodyBehindAppBar: true,
            bottomAppBar: BottomAppBar(
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (isPinned) {
                        pinnedManga.deleteSingle(
                          entry.id.toString(),
                          entry.site,
                        );
                      } else {
                        pinnedManga.addAll([entry]);
                      }

                      isPinned =
                          pinnedManga.exist(entry.id.toString(), entry.site);

                      setState(() {});
                    },
                    icon: Icon(
                      Icons.push_pin_rounded,
                      color: isPinned ? theme.colorScheme.primary : null,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      launchUrl(Uri.parse(widget.api.browserUrl(entry)));
                    },
                    icon: const Icon(Icons.public),
                  ),
                ],
              ),
            ),
            child: Stack(
              children: [
                CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverStack(
                      children: [
                        SliverPositioned.fill(
                          child: BackgroundImageBase(
                            image: entry.thumbnail(),
                          ),
                        ),
                        CardShell.sliver(
                          viewPadding: MediaQuery.viewPaddingOf(context),
                          title: entry.title,
                          titleEnglish: entry.titleEnglish,
                          titleJapanese: entry.titleJapanese,
                          titleSynonyms: entry.titleSynonyms,
                          safeMode: entry.safety,
                          info: [
                            UnsizedCard(
                              subtitle: Text(l10n.cardYear),
                              tooltip: l10n.cardYear,
                              title: Text(
                                entry.year == 0
                                    ? cardUnknownValue
                                    : entry.year.toString(),
                              ),
                              transparentBackground: true,
                            ),
                            if (score != null)
                              UnsizedCard(
                                subtitle: Text(
                                  l10n.cardScore,
                                ),
                                title: Text(
                                  score!.isNegative
                                      ? cardUnknownValue
                                      : score!.toString(),
                                ),
                                tooltip: l10n.cardScore,
                                transparentBackground: true,
                              )
                            else
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(right: 24),
                                  child: SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                            UnsizedCard(
                              subtitle: Text(
                                l10n.cardStatus,
                              ),
                              tooltip: l10n.cardStatus,
                              title: Text(entry.status),
                              transparentBackground: true,
                            ),
                            UnsizedCard(
                              subtitle: Text(
                                l10n.cardVolumes,
                              ),
                              tooltip: l10n.cardVolumes,
                              title: Text(
                                entry.volumes.isNegative
                                    ? cardUnknownValue
                                    : entry.volumes.toString(),
                              ),
                              transparentBackground: true,
                            ),
                            UnsizedCard(
                              subtitle: Text(
                                l10n.cardDemographics,
                              ),
                              tooltip: l10n.cardDemographics,
                              title: Text(
                                entry.demographics.isEmpty
                                    ? cardUnknownValue
                                    : entry.demographics,
                              ),
                              transparentBackground: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                    MangaInfoBody(
                      api: widget.api,
                      entry: entry,
                      scrollController: scrollController,
                      viewPadding: MediaQuery.viewPaddingOf(context),
                      db: widget.db,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
