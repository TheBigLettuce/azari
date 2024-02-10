// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/db/schemas/anime/saved_anime_entry.dart';
import 'package:gallery/src/db/schemas/anime/watched_anime_entry.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:gallery/src/pages/more/dashboard/dashboard_card.dart';
import 'package:url_launcher/url_launcher.dart';

import 'card_shell.dart';

class CardPanel extends StatefulWidget {
  final AnimeEntry entry;
  final EdgeInsets viewPadding;

  const CardPanel({
    super.key,
    required this.entry,
    required this.viewPadding,
  });

  static List<Widget> defaultInfo(BuildContext context, AnimeEntry entry) => [
        UnsizedCard(
          subtitle: Text(AppLocalizations.of(context)!.cardYear),
          tooltip: AppLocalizations.of(context)!.cardYear,
          title: Text(entry.year == 0
              ? AppLocalizations.of(context)!.cardUnknownValue
              : entry.year.toString()),
          transparentBackground: true,
        ),
        UnsizedCard(
          subtitle: Text(AppLocalizations.of(context)!.cardScore),
          tooltip: AppLocalizations.of(context)!.cardScore,
          title: Text(entry.score == 0
              ? AppLocalizations.of(context)!.cardUnknownValue
              : entry.score.toString()),
          transparentBackground: true,
        ),
        UnsizedCard(
          subtitle: Text(AppLocalizations.of(context)!.cardAiring),
          tooltip: AppLocalizations.of(context)!.cardAiring,
          title: Text(entry.isAiring
              ? AppLocalizations.of(context)!.yes
              : AppLocalizations.of(context)!.no),
          transparentBackground: true,
        ),
        UnsizedCard(
          subtitle: Text(AppLocalizations.of(context)!.cardEpisodes),
          tooltip: AppLocalizations.of(context)!.cardEpisodes,
          title: Text(entry.episodes == 0
              ? AppLocalizations.of(context)!.cardUnknownValue
              : entry.episodes.toString()),
          transparentBackground: true,
        ),
        UnsizedCard(
          subtitle: Text(AppLocalizations.of(context)!.cardType),
          tooltip: AppLocalizations.of(context)!.cardType,
          title: Text(entry.type.isEmpty
              ? AppLocalizations.of(context)!.cardUnknownValue
              : entry.type.toLowerCase()),
          transparentBackground: true,
        ),
      ];

  static List<Widget> defaultButtons(BuildContext context, AnimeEntry entry,
          {required bool isWatching,
          required bool inBacklog,
          required bool watched,
          Widget? replaceWatchCard}) =>
      [
        replaceWatchCard ??
            UnsizedCard(
              subtitle: Text(watched
                  ? AppLocalizations.of(context)!.cardWatched
                  : isWatching
                      ? inBacklog
                          ? AppLocalizations.of(context)!.cardInBacklog
                          : AppLocalizations.of(context)!.cardWatching
                      : AppLocalizations.of(context)!.cardBacklog),
              title: watched
                  ? Icon(Icons.check_rounded,
                      color: Theme.of(context).colorScheme.primary)
                  : isWatching
                      ? const Icon(Icons.library_add_check)
                      : const Icon(Icons.add_rounded),
              tooltip: watched
                  ? AppLocalizations.of(context)!.cardWatched
                  : isWatching
                      ? inBacklog
                          ? AppLocalizations.of(context)!.cardInBacklog
                          : AppLocalizations.of(context)!.cardWatching
                      : AppLocalizations.of(context)!.cardBacklog,
              transparentBackground: true,
              onPressed: isWatching || watched
                  ? null
                  : () {
                      SavedAnimeEntry.addAll([entry], entry.site);
                    },
            ),
        UnsizedCard(
          subtitle: Text(AppLocalizations.of(context)!.cardInBrowser),
          tooltip: AppLocalizations.of(context)!.cardInBrowser,
          title: const Icon(Icons.public),
          transparentBackground: true,
          onPressed: () {
            launchUrl(Uri.parse(entry.siteUrl));
          },
        ),
        if (entry.trailerUrl.isEmpty)
          const SizedBox.shrink()
        else
          UnsizedCard(
            subtitle: Text(AppLocalizations.of(context)!.cardTrailer),
            tooltip: AppLocalizations.of(context)!.cardTrailer,
            title: const Icon(Icons.smart_display_rounded),
            transparentBackground: true,
            onPressed: () {
              launchUrl(Uri.parse(entry.trailerUrl),
                  mode: LaunchMode.externalNonBrowserApplication);
            },
          ),
      ];

  @override
  State<CardPanel> createState() => _CardPanelState();
}

class _CardPanelState extends State<CardPanel> {
  late final StreamSubscription<void> entriesWatcher;

  late (bool, bool) _isWatchingBacklog =
      SavedAnimeEntry.isWatchingBacklog(widget.entry.id, widget.entry.site);

  late bool _watched =
      WatchedAnimeEntry.watched(widget.entry.id, widget.entry.site);

  @override
  void initState() {
    super.initState();

    entriesWatcher = SavedAnimeEntry.watchAll((_) {
      _isWatchingBacklog =
          SavedAnimeEntry.isWatchingBacklog(widget.entry.id, widget.entry.site);

      _watched = WatchedAnimeEntry.watched(widget.entry.id, widget.entry.site);

      setState(() {});
    });
  }

  @override
  void dispose() {
    entriesWatcher.cancel();

    super.dispose();
  }

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
      buttons: CardPanel.defaultButtons(
        context,
        widget.entry,
        isWatching: _isWatchingBacklog.$1,
        inBacklog: _isWatchingBacklog.$2,
        watched: _watched,
      ),
    );
  }
}
