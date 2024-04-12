// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/anime/saved_anime_entry.dart';
import 'package:gallery/src/db/schemas/anime/watched_anime_entry.dart';
import 'package:gallery/src/db/schemas/settings/misc_settings.dart';
import 'package:gallery/src/interfaces/anime/anime_api.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:gallery/src/pages/anime/info_base/anime_info_app_bar.dart';
import 'package:gallery/src/pages/anime/info_base/anime_info_theme.dart';
import 'package:gallery/src/pages/anime/info_base/background_image/background_image.dart';
import 'package:gallery/src/pages/anime/info_base/body/anime_info_body.dart';
import 'package:gallery/src/pages/anime/info_base/card_panel/card_panel.dart';
import 'package:gallery/src/pages/anime/info_base/card_panel/card_shell.dart';
import 'package:gallery/src/pages/anime/info_base/always_loading_anime_mixin.dart';
import 'package:gallery/src/pages/anime/info_base/refresh_entry_icon.dart';
import 'package:gallery/src/widgets/skeletons/settings.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AnimeInfoPage extends StatefulWidget {
  final int id;
  final AnimeEntry? entry;
  final AnimeAPI Function(Dio) apiFactory;

  const AnimeInfoPage({
    super.key,
    this.entry,
    required this.id,
    required this.apiFactory,
  });

  @override
  State<AnimeInfoPage> createState() => _AnimeInfoPageState();
}

class _AnimeInfoPageState extends State<AnimeInfoPage> {
  final state = SkeletonState();
  final textController = TextEditingController();
  final alwaysLoading = MiscSettings.current.animeAlwaysLoadFromNet;

  final client = Dio();
  late final AnimeAPI api;

  @override
  void initState() {
    super.initState();
    api = widget.apiFactory(client);
  }

  @override
  void dispose() {
    client.close();

    textController.dispose();

    state.dispose();

    super.dispose();
  }

  Future<AnimeEntry> _newStatus() {
    if (widget.entry != null && !alwaysLoading) {
      return Future.value(widget.entry!);
    }

    return api.info(widget.id).then((value) {
      SavedAnimeEntry.update(value);
      WatchedAnimeEntry.update(value);

      return value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WrapFutureRestartable(
      newStatus: _newStatus,
      builder: (context, entry) {
        return _AnimeInfoBody(
          entry: entry,
          api: api,
          state: state,
        );
      },
    );
  }
}

class _AnimeInfoBody extends StatefulWidget {
  final AnimeEntry entry;
  final AnimeAPI api;
  final SkeletonState state;

  const _AnimeInfoBody({
    super.key,
    required this.entry,
    required this.api,
    required this.state,
  });

  @override
  State<_AnimeInfoBody> createState() => __AnimeInfoBodyState();
}

class __AnimeInfoBodyState extends State<_AnimeInfoBody> {
  late final StreamSubscription<void> entriesWatcher;
  late final StreamSubscription<WatchedAnimeEntry?> watchedEntryWatcher;

  final scrollController = ScrollController();

  late AnimeEntry entry = widget.entry;
  AnimeAPI get api => widget.api;

  late bool _watching;
  late bool _backlog;
  late bool _watched;

  @override
  void initState() {
    super.initState();

    final r = SavedAnimeEntry.isWatchingBacklog(entry.id, entry.site);

    _watching = r.$1;
    _backlog = r.$2;

    _watched = WatchedAnimeEntry.watched(entry.id, entry.site);

    watchedEntryWatcher =
        WatchedAnimeEntry.watchSingle(entry.id, api.site, (e) {
      final e = WatchedAnimeEntry.maybeGet(entry.id, entry.site);
      _watched = e != null;
      if (e != null) {
        entry = e;
      }

      setState(() {});
    });

    entriesWatcher = SavedAnimeEntry.watchAll((_) {
      final e = SavedAnimeEntry.maybeGet(entry.id, entry.site);

      if (e == null) {
        _watching = false;
        _backlog = false;
      } else {
        _watching = true;
        _backlog = e.inBacklog;

        entry = e;
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    entriesWatcher.cancel();
    watchedEntryWatcher.cancel();

    scrollController.dispose();

    super.dispose();
  }

  void _addToWatched() {
    WatchedAnimeEntry.moveAll([entry]);
  }

  void _save(AnimeEntry e) {
    if (_watching) {
      SavedAnimeEntry.update(e);
    } else if (_watched) {
      WatchedAnimeEntry.update(e);
    } else {
      entry = e;

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final overlayColor = Theme.of(context).colorScheme.surface;
    final iconBrightness = Theme.of(context).colorScheme.brightness;

    return AnimeInfoTheme(
      mode: entry.explicit,
      overlayColor: overlayColor,
      iconBrightness: iconBrightness,
      child: SettingsSkeleton(
        AppLocalizations.of(context)!.watchingTab,
        widget.state,
        fab: _watched
            ? null
            : FloatingActionButton(
                onPressed: () {
                  if (_watching) {
                    final e = SavedAnimeEntry.maybeGet(
                        widget.entry.id, widget.entry.site)!;

                    SavedAnimeEntry.deleteAll([
                      (e.site, e.id),
                    ]);
                  } else {
                    SavedAnimeEntry.addAll([widget.entry]);
                  }
                },
                child: _watching
                    ? const Icon(Icons.close_rounded)
                    : const Icon(Icons.add_rounded),
              ),
        bottomAppBar: BottomAppBar(
          child: Row(
            children: [
              if (_watching && !_watched)
                IconButton(
                  onPressed: () {
                    final prevEntry =
                        SavedAnimeEntry.maybeGet(entry.id, entry.site)!;

                    if (!_backlog) {
                      prevEntry.unsetIsWatching();
                      return;
                    }

                    if (!prevEntry.setCurrentlyWatching()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                AppLocalizations.of(context)!.cantWatchThree)),
                      );
                    }
                  },
                  icon: Icon(
                    Icons.play_arrow_rounded,
                    color:
                        _backlog ? null : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ...CardPanel.defaultButtons(
                context,
                entry,
                api,
              ),
              if (_watched)
                IconButton(
                  onPressed: () {
                    final prevEntry =
                        WatchedAnimeEntry.maybeGet(entry.id, entry.site)!;
                    WatchedAnimeEntry.delete(entry.id, entry.site);

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text(AppLocalizations.of(context)!.removeFromWatched),
                      action: SnackBarAction(
                          label: AppLocalizations.of(context)!.undoLabel,
                          onPressed: () {
                            WatchedAnimeEntry.read(prevEntry);
                          }),
                    ));
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
              if (!_watched)
                IconButton(
                  onPressed: _addToWatched,
                  icon: const Icon(Icons.check_rounded),
                ),
              if (_watched)
                IconButton(
                  onPressed: () {
                    WatchedAnimeEntry.moveAllReversed([
                      WatchedAnimeEntry.maybeGet(entry.id, entry.site)!,
                    ]);
                  },
                  icon: const Icon(Icons.library_add_rounded),
                ),
            ],
          ),
        ),
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: AnimeInfoAppBar(
              cell: entry,
              scrollController: scrollController,
              appBarActions: [
                RefreshEntryIcon(
                  entry,
                  _save,
                  api: api,
                )
              ],
            )),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.viewPaddingOf(context).bottom),
            child: Stack(children: [
              BackgroundImage(image: entry.thumbnail()),
              Column(
                children: [
                  CardShell(
                    title: entry.title,
                    titleEnglish: entry.titleEnglish,
                    titleJapanese: entry.titleJapanese,
                    titleSynonyms: entry.titleSynonyms,
                    safeMode: entry.explicit,
                    viewPadding: MediaQuery.viewPaddingOf(context),
                    info: CardPanel.defaultInfo(
                      context,
                      entry,
                    ),
                  ),
                  AnimeInfoBody(
                    overlayColor: overlayColor,
                    entry: entry,
                    api: api,
                    iconColor: iconBrightness,
                    viewPadding: MediaQuery.viewPaddingOf(context),
                  ),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
