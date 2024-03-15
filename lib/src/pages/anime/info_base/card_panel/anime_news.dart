// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/interfaces/anime/anime_api.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class AnimeNews extends StatefulWidget {
  final List<AnimeNewsEntry> news;

  const AnimeNews({super.key, required this.news});

  @override
  State<AnimeNews> createState() => _AnimeNewsState();
}

class _AnimeNewsState extends State<AnimeNews> {
  final _expanded = <int, bool>{};

  @override
  Widget build(BuildContext context) {
    return widget.news.isEmpty
        ? const EmptyWidget(gridSeed: 0)
        : ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.viewPaddingOf(context).bottom),
                child: ExpansionPanelList(
                  expansionCallback: (panelIndex, isExpanded) {
                    _expanded[panelIndex] = isExpanded;

                    setState(() {});
                  },
                  children: widget.news.indexed
                      .map((e) => ExpansionPanel(
                            canTapOnHeader: true,
                            isExpanded: _expanded[e.$1] ?? false,
                            headerBuilder: (context, isExpanded) {
                              return ListTile(
                                leading: e.$2.thumbUrl != null
                                    ? CircleAvatar(
                                        foregroundImage:
                                            CachedNetworkImageProvider(
                                                e.$2.thumbUrl!),
                                      )
                                    : null,
                                title: Text(e.$2.title),
                              );
                            },
                            body: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      right: 16, left: 16, bottom: 4),
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .date(e.$2.date),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6)),
                                  ),
                                ),
                                ListTile(
                                  subtitle: Text(e.$2.content),
                                  onTap: () {
                                    launchUrl(Uri.parse(e.$2.browserUrl),
                                        mode: LaunchMode.inAppBrowserView);
                                  },
                                  trailing: IconButton.filledTonal(
                                    onPressed: () {
                                      launchUrl(Uri.parse(e.$2.browserUrl),
                                          mode: LaunchMode.inAppBrowserView);
                                    },
                                    icon: const Icon(Icons.open_in_new_rounded),
                                  ),
                                )
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          );
  }
}
