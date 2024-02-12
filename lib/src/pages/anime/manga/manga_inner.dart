// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/manga/manga_api.dart';
import 'package:gallery/src/pages/anime/info_base/anime_info_app_bar.dart';
import 'package:gallery/src/pages/anime/info_base/anime_info_theme.dart';
import 'package:gallery/src/pages/anime/info_base/background_image/background_image.dart';
import 'package:gallery/src/pages/anime/info_base/body/anime_relations.dart';
import 'package:gallery/src/pages/anime/info_base/body/body_segment_label.dart';
import 'package:gallery/src/pages/anime/info_base/card_panel/card_shell.dart';
import 'package:gallery/src/pages/anime/info_pages/anime_info_id.dart';
import 'package:gallery/src/pages/anime/manga/manga_info_body.dart';
import 'package:gallery/src/pages/anime/search/search_anime.dart';
import 'package:gallery/src/pages/more/dashboard/dashboard_card.dart';
import 'package:gallery/src/widgets/menu_wrapper.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_settings.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class MangaInnerPage extends StatefulWidget {
  final Future<MangaEntry> entry;
  final MangaAPI api;

  const MangaInnerPage({
    super.key,
    required this.entry,
    required this.api,
  });

  @override
  State<MangaInnerPage> createState() => _MangaInnerPageState();
}

class _MangaInnerPageState extends State<MangaInnerPage>
    with TickerProviderStateMixin {
  final state = SkeletonState();
  final scrollController = ScrollController();
  double? score;

  @override
  void initState() {
    super.initState();

    widget.entry.then((value) => widget.api.score(value).then((value) {
          score = value;

          setState(() {});
        }).onError((error, stackTrace) {
          score = -1;

          setState(() {});
        }));
  }

  @override
  void dispose() {
    scrollController.dispose();

    state.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overlayColor = Theme.of(context).colorScheme.background;
    final cardUnknownValue = AppLocalizations.of(context)!.cardUnknownValue;

    return FutureBuilder(
      future: widget.entry,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final entry = snapshot.data!;

          return AnimeInfoTheme(
            mode: entry.safety,
            overlayColor: overlayColor,
            child: SkeletonSettings(
              "Manga info",
              state,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: AnimeInfoAppBar(
                  cell: entry,
                  scrollController: scrollController,
                ),
              ),
              extendBodyBehindAppBar: true,
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.viewPaddingOf(context).bottom),
                  child: Stack(
                    children: [
                      BackgroundImage(image: entry.thumbnail()!),
                      CardShell(
                        viewPadding: MediaQuery.viewPaddingOf(context),
                        title: entry.title,
                        titleEnglish: entry.titleEnglish,
                        titleJapanese: entry.titleJapanese,
                        titleSynonyms: entry.titleSynonyms,
                        safeMode: entry.safety,
                        info: [
                          UnsizedCard(
                            subtitle:
                                Text(AppLocalizations.of(context)!.cardYear),
                            tooltip: AppLocalizations.of(context)!.cardYear,
                            title: Text(entry.year == 0
                                ? cardUnknownValue
                                : entry.year.toString()),
                            transparentBackground: true,
                          ),
                          if (score != null)
                            UnsizedCard(
                              subtitle: const Text("Score"), // TODO: change
                              title: Text(score!.isNegative
                                  ? cardUnknownValue
                                  : score!.toString()),
                              tooltip: "score",
                              transparentBackground: true,
                            )
                          else
                            const Center(
                              child: SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          UnsizedCard(
                            subtitle: const Text("Status"), // TODO: change
                            tooltip: "Status",
                            title: Text(entry.status),
                            transparentBackground: true,
                          ),
                          UnsizedCard(
                            subtitle: const Text("Volumes"), // TODO: change
                            tooltip: "Volumes",
                            title: Text(entry.volumes.isNegative
                                ? cardUnknownValue
                                : entry.volumes.toString()),
                            transparentBackground: true,
                          ),
                          UnsizedCard(
                            subtitle:
                                const Text("Demographics"), // TODO: change
                            tooltip: "Demographics",
                            title: Text(entry.demographics.isEmpty
                                ? cardUnknownValue
                                : entry.demographics),
                            transparentBackground: true,
                          ),
                        ],
                        buttons: [
                          UnsizedCard(
                            subtitle: Text(AppLocalizations.of(context)!
                                .cardInBrowser), // TODO: change
                            tooltip:
                                AppLocalizations.of(context)!.cardInBrowser,
                            title: const Icon(Icons.public),
                            transparentBackground: true,
                            onPressed: () {
                              launchUrl(
                                  Uri.parse(widget.api.browserUrl(entry)));
                            },
                          ),
                        ],
                      ),
                      MangaInfoBody(
                        api: widget.api,
                        overlayColor: overlayColor,
                        entry: entry,
                        viewPadding: MediaQuery.viewPaddingOf(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else {
          return Scaffold(
            appBar: snapshot.hasError
                ? AppBar(
                    leading: const BackButton(),
                  )
                : null,
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}
