// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/interfaces/anime/anime_api.dart";
import "package:gallery/src/interfaces/anime/anime_entry.dart";
import "package:gallery/src/pages/anime/info_base/always_loading_anime_mixin.dart";
import "package:gallery/src/pages/anime/info_base/card_panel/anime_news.dart";
import "package:gallery/src/pages/anime/info_base/card_panel/card_shell.dart";
import "package:gallery/src/pages/more/dashboard/dashboard_card.dart";
import "package:url_launcher/url_launcher.dart";

class CardPanel extends StatefulWidget {
  const CardPanel({
    super.key,
    required this.entry,
    required this.viewPadding,
  });
  final AnimeEntryData entry;
  final EdgeInsets viewPadding;

  static List<Widget> defaultInfo(BuildContext context, AnimeEntryData entry) =>
      [
        UnsizedCard(
          subtitle: Text(AppLocalizations.of(context)!.cardYear),
          tooltip: AppLocalizations.of(context)!.cardYear,
          title: Text(
            entry.year == 0
                ? AppLocalizations.of(context)!.cardUnknownValue
                : entry.year.toString(),
          ),
          transparentBackground: true,
        ),
        UnsizedCard(
          subtitle: Text(AppLocalizations.of(context)!.cardScore),
          tooltip: AppLocalizations.of(context)!.cardScore,
          title: Text(
            entry.score == 0
                ? AppLocalizations.of(context)!.cardUnknownValue
                : entry.score.toString(),
          ),
          transparentBackground: true,
        ),
        UnsizedCard(
          subtitle: Text(AppLocalizations.of(context)!.cardAiring),
          tooltip: AppLocalizations.of(context)!.cardAiring,
          title: Text(
            entry.isAiring
                ? AppLocalizations.of(context)!.yes
                : AppLocalizations.of(context)!.no,
          ),
          transparentBackground: true,
        ),
        UnsizedCard(
          subtitle: Text(AppLocalizations.of(context)!.cardEpisodes),
          tooltip: AppLocalizations.of(context)!.cardEpisodes,
          title: Text(
            entry.episodes == 0
                ? AppLocalizations.of(context)!.cardUnknownValue
                : entry.episodes.toString(),
          ),
          transparentBackground: true,
        ),
        UnsizedCard(
          subtitle: Text(AppLocalizations.of(context)!.cardType),
          tooltip: AppLocalizations.of(context)!.cardType,
          title: Text(
            entry.type.isEmpty
                ? AppLocalizations.of(context)!.cardUnknownValue
                : entry.type.toLowerCase(),
          ),
          transparentBackground: true,
        ),
      ];

  static List<Widget> defaultButtons(
    BuildContext context,
    AnimeEntryData entry,
    AnimeAPI api,
  ) =>
      [
        IconButton(
          onPressed: () {
            launchUrl(
              Uri.parse(entry.trailerUrl),
              mode: LaunchMode.externalNonBrowserApplication,
            );
          },
          icon: const Icon(Icons.public),
        ),
        if (entry.trailerUrl.isNotEmpty)
          IconButton(
            onPressed: () {
              launchUrl(
                Uri.parse(entry.trailerUrl),
                mode: LaunchMode.externalNonBrowserApplication,
              );
            },
            icon: const Icon(Icons.smart_display_rounded),
          ),
        IconButton(
          onPressed: () {
            showModalBottomSheet<void>(
              context: context,
              useSafeArea: true,
              isScrollControlled: true,
              useRootNavigator: true,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.85,
              ),
              showDragHandle: true,
              builder: (context) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Text(
                        AppLocalizations.of(context)!.newsTab,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Padding(padding: EdgeInsets.only(top: 8)),
                    Expanded(
                      child: WrapFutureRestartable(
                        bottomSheetVariant: true,
                        builder: (context, value) {
                          return AnimeNews(news: value);
                        },
                        newStatus: () {
                          return api.animeNews(entry, 0);
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
          icon: const Icon(Icons.newspaper_rounded),
        ),
      ];

  @override
  State<CardPanel> createState() => _CardPanelState();
}

class _CardPanelState extends State<CardPanel> {
  @override
  Widget build(BuildContext context) {
    return CardShell(
      viewPadding: widget.viewPadding,
      title: widget.entry.title,
      titleEnglish: widget.entry.titleEnglish,
      titleJapanese: widget.entry.titleJapanese,
      titleSynonyms: widget.entry.titleSynonyms,
      safeMode: widget.entry.explicit,
      info: CardPanel.defaultInfo(context, widget.entry),
    );
  }
}
