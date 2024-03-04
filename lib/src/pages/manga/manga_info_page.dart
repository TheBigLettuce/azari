// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/manga/compact_manga_data.dart';
import 'package:gallery/src/db/schemas/manga/pinned_manga.dart';
import 'package:gallery/src/interfaces/manga/manga_api.dart';
import 'package:gallery/src/pages/anime/info_base/always_loading_anime_mixin.dart';
import 'package:gallery/src/pages/anime/info_base/anime_info_app_bar.dart';
import 'package:gallery/src/pages/anime/info_base/anime_info_theme.dart';
import 'package:gallery/src/pages/anime/info_base/background_image/background_image.dart';
import 'package:gallery/src/pages/anime/info_base/card_panel/card_shell.dart';
import 'package:gallery/src/pages/manga/body/manga_info_body.dart';
import 'package:gallery/src/pages/more/dashboard/dashboard_card.dart';
import 'package:gallery/src/widgets/skeletons/settings.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class MangaInfoPage extends StatefulWidget {
  final MangaId id;
  final MangaAPI api;
  final MangaEntry? entry;

  const MangaInfoPage({
    super.key,
    required this.id,
    required this.api,
    this.entry,
  });

  @override
  State<MangaInfoPage> createState() => _MangaInfoPageState();
}

class _MangaInfoPageState extends State<MangaInfoPage>
    with TickerProviderStateMixin {
  final state = SkeletonState();
  final scrollController = ScrollController();
  double? score;
  Future? scoreFuture;

  bool isPinned = false;

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
      isPinned = PinnedManga.exist(value.id.toString(), value.site);
      CompactMangaData.addAll([
        CompactMangaData(
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
    final overlayColor = Theme.of(context).colorScheme.background;
    final cardUnknownValue = AppLocalizations.of(context)!.cardUnknownValue;

    return WrapFutureRestartable(
        newStatus: newFuture,
        builder: (context, entry) {
          return AnimeInfoTheme(
            mode: entry.safety,
            overlayColor: overlayColor,
            child: SettingsSkeleton(
              AppLocalizations.of(context)!.mangaInfoPage,
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
                          PinnedManga.deleteSingle(
                              entry.id.toString(), entry.site);
                        } else {
                          PinnedManga.addAll([
                            PinnedManga(
                              mangaId: entry.id.toString(),
                              site: entry.site,
                              thumbUrl: entry.thumbUrl,
                              title: entry.title,
                            )
                          ]);
                        }

                        isPinned =
                            PinnedManga.exist(entry.id.toString(), entry.site);

                        setState(() {});
                      },
                      icon: Icon(
                        Icons.push_pin_rounded,
                        color: isPinned
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    IconButton(
                        onPressed: () {
                          launchUrl(Uri.parse(widget.api.browserUrl(entry)));
                        },
                        icon: const Icon(Icons.public)),
                  ],
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                // primary: true,
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.viewPaddingOf(context).bottom),
                  child: Stack(
                    children: [
                      BackgroundImage(image: entry.thumbnail()!),
                      Column(
                        children: [
                          CardShell(
                            viewPadding: MediaQuery.viewPaddingOf(context),
                            title: entry.title,
                            titleEnglish: entry.titleEnglish,
                            titleJapanese: entry.titleJapanese,
                            titleSynonyms: entry.titleSynonyms,
                            safeMode: entry.safety,
                            info: [
                              UnsizedCard(
                                subtitle: Text(
                                    AppLocalizations.of(context)!.cardYear),
                                tooltip: AppLocalizations.of(context)!.cardYear,
                                title: Text(entry.year == 0
                                    ? cardUnknownValue
                                    : entry.year.toString()),
                                transparentBackground: true,
                              ),
                              if (score != null)
                                UnsizedCard(
                                  subtitle: Text(
                                      AppLocalizations.of(context)!.cardScore),
                                  title: Text(score!.isNegative
                                      ? cardUnknownValue
                                      : score!.toString()),
                                  tooltip:
                                      AppLocalizations.of(context)!.cardScore,
                                  transparentBackground: true,
                                )
                              else
                                const Center(
                                  child: SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              UnsizedCard(
                                subtitle: Text(
                                    AppLocalizations.of(context)!.cardStatus),
                                tooltip:
                                    AppLocalizations.of(context)!.cardStatus,
                                title: Text(entry.status),
                                transparentBackground: true,
                              ),
                              UnsizedCard(
                                subtitle: Text(
                                    AppLocalizations.of(context)!.cardVolumes),
                                tooltip:
                                    AppLocalizations.of(context)!.cardVolumes,
                                title: Text(entry.volumes.isNegative
                                    ? cardUnknownValue
                                    : entry.volumes.toString()),
                                transparentBackground: true,
                              ),
                              UnsizedCard(
                                subtitle: Text(AppLocalizations.of(context)!
                                    .cardDemographics),
                                tooltip: AppLocalizations.of(context)!
                                    .cardDemographics,
                                title: Text(entry.demographics.isEmpty
                                    ? cardUnknownValue
                                    : entry.demographics),
                                transparentBackground: true,
                              ),
                            ],
                          ),
                          MangaInfoBody(
                            api: widget.api,
                            overlayColor: overlayColor,
                            entry: entry,
                            scrollController: scrollController,
                            viewPadding: MediaQuery.viewPaddingOf(context),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }
}
