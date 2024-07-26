// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/anime/anime_api.dart";
import "package:gallery/src/net/anime/anime_entry.dart";
import "package:gallery/src/pages/anime/info_base/always_loading_anime_mixin.dart";
import "package:gallery/src/pages/anime/info_base/anime_info_app_bar.dart";
import "package:gallery/src/pages/anime/info_base/anime_info_theme.dart";
import "package:gallery/src/pages/anime/info_base/background_image/background_image.dart";
import "package:gallery/src/pages/anime/info_base/body/anime_info_body.dart";
import "package:gallery/src/pages/anime/info_base/card_panel/card_panel.dart";
import "package:gallery/src/pages/anime/info_base/card_panel/card_shell.dart";
import "package:gallery/src/pages/anime/info_base/refresh_entry_icon.dart";
import "package:gallery/src/widgets/skeletons/settings.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";

class AnimeInfoPage extends StatefulWidget {
  const AnimeInfoPage({
    super.key,
    this.entry,
    required this.id,
    required this.apiFactory,
    required this.db,
  });

  final int id;
  final AnimeEntryData? entry;
  final AnimeAPI Function(Dio) apiFactory;

  final DbConn db;

  @override
  State<AnimeInfoPage> createState() => _AnimeInfoPageState();
}

class _AnimeInfoPageState extends State<AnimeInfoPage> {
  SavedAnimeEntriesService get savedAnimeEntries => widget.db.savedAnimeEntries;
  WatchedAnimeEntryService get watchedAnimeEntries => widget.db.watchedAnime;

  final state = SkeletonState();
  final textController = TextEditingController();
  final alwaysLoading = MiscSettingsService.db().current.animeAlwaysLoadFromNet;

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

  Future<AnimeEntryData> _newStatus() {
    if (widget.entry != null && !alwaysLoading) {
      return Future.value(widget.entry!);
    }

    return api.info(widget.id).then((value) {
      savedAnimeEntries.update(value);
      watchedAnimeEntries.update(value);

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
          db: widget.db,
        );
      },
    );
  }
}

class _AnimeInfoBody extends StatefulWidget {
  const _AnimeInfoBody({
    required this.entry,
    required this.api,
    required this.state,
    required this.db,
  });
  final AnimeEntryData entry;
  final AnimeAPI api;
  final SkeletonState state;

  final DbConn db;

  @override
  State<_AnimeInfoBody> createState() => __AnimeInfoBodyState();
}

class __AnimeInfoBodyState extends State<_AnimeInfoBody> {
  SavedAnimeEntriesService get savedAnimeEntries => widget.db.savedAnimeEntries;
  WatchedAnimeEntryService get watchedAnimeEntries => widget.db.watchedAnime;

  late final StreamSubscription<void> entriesWatcher;
  late final StreamSubscription<WatchedAnimeEntryData?> watchedEntryWatcher;

  final scrollController = ScrollController();

  late AnimeEntryData entry = widget.entry;
  AnimeAPI get api => widget.api;

  late bool _inDb;
  late bool _backlog;
  late bool _watched;

  @override
  void initState() {
    super.initState();

    final r = savedAnimeEntries.isWatchingBacklog(entry.id, entry.site);

    _inDb = r.$1;
    _backlog = r.$2;

    _watched = watchedAnimeEntries.watched(entry.id, entry.site);

    watchedEntryWatcher =
        watchedAnimeEntries.watchSingle(entry.id, api.site, (e) {
      final e = watchedAnimeEntries.maybeGet(entry.id, entry.site);
      _watched = e != null;
      if (e != null) {
        entry = e;
      }

      setState(() {});
    });

    entriesWatcher = savedAnimeEntries.watchAll((_) {
      final e = savedAnimeEntries.maybeGet(entry.id, entry.site);

      if (e == null) {
        _inDb = false;
        _backlog = false;
      } else {
        _inDb = true;
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

  void _save(AnimeEntryData e) {
    if (_inDb) {
      savedAnimeEntries.update(e);
    } else if (_watched) {
      watchedAnimeEntries.update(e);
    } else {
      entry = e;

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimeInfoTheme(
      mode: entry.explicit,
      child: SettingsSkeleton(
        l10n.watchingTab,
        widget.state,
        bottomAppBar: BottomAppBar(
          child: Row(
            children: [
              ...CardPanel.defaultButtons(
                context,
                entry,
                api,
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
              ),
            ],
          ),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Stack(
              children: [
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
                      entry: entry,
                      api: api,
                      buttons: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _ActionButton(
                              icon: Icons.play_arrow_rounded,
                              label: !_backlog && _inDb
                                  ? "Remove from watching"
                                  : "Add to watching",
                              onPress: !_inDb
                                  ? null
                                  : () {
                                      final prevEntry =
                                          savedAnimeEntries.maybeGet(
                                        entry.id,
                                        entry.site,
                                      )!;

                                      if (_backlog) {
                                        prevEntry.copy(inBacklog: false).save();
                                      } else {
                                        prevEntry.copy(inBacklog: true).save();
                                      }
                                    },
                              isSelected: !_backlog,
                            ),
                          ),
                          const Padding(padding: EdgeInsets.only(left: 8)),
                          Expanded(
                            flex: 2,
                            child: _ActionButton(
                              icon: Icons.check_rounded,
                              label: _watched
                                  ? "Remove from watched"
                                  : "Add to watched",
                              onPress: () {
                                if (!_watched) {
                                  watchedAnimeEntries
                                      .moveAll([entry], savedAnimeEntries);
                                } else {
                                  watchedAnimeEntries.delete(
                                    entry.id,
                                    entry.site,
                                  );
                                }
                              },
                              isSelected: _watched,
                            ),
                          ),
                          const Padding(padding: EdgeInsets.only(left: 8)),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.video_collection_rounded,
                              label: _inDb
                                  ? "Remove from backlog"
                                  : "Add to backlog",
                              onPress: _watched
                                  ? null
                                  : () {
                                      if (_inDb) {
                                        savedAnimeEntries.deleteAll(
                                            [(entry.id, entry.site)]);
                                      } else {
                                        savedAnimeEntries.addAll(
                                            [entry], watchedAnimeEntries);
                                      }
                                    },
                              isSelected: _inDb,
                            ),
                          ),
                        ],
                      ),
                      viewPadding: MediaQuery.viewPaddingOf(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPress,
    required this.isSelected,
  });

  final IconData icon;
  final String label;

  final void Function()? onPress;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final foreground = onPress == null
        ? theme.disabledColor
        : theme.colorScheme.onTertiaryContainer;
    final background = (onPress == null
            ? theme.colorScheme.surfaceContainerLow
            : theme.colorScheme.tertiaryContainer)
        .withOpacity(isSelected ? 0.8 : 0.2);
    final colorIcon = onPress == null
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.tertiary;

    return InkWell(
      onTap: onPress,
      borderRadius: BorderRadius.circular(15),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 90,
          maxHeight: 90,
        ),
        child: TweenAnimationBuilder(
          tween: ColorTween(end: background),
          curve: Easing.standard,
          duration: Durations.medium3,
          builder: (context, color, child) => DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15),
            ),
            child: child,
          ),
          child: SizedBox.expand(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 100) {
                    return Center(
                      child: Tooltip(
                        message: label,
                        child: Icon(
                          icon,
                          color:
                              colorIcon.withOpacity(onPress == null ? 0.4 : 1),
                        ),
                      ),
                    );
                  }

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: colorIcon.withOpacity(onPress == null ? 0.4 : 1),
                      ),
                      AnimatedSize(
                        duration: Durations.medium3,
                        curve: Easing.standard,
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: foreground
                                .withOpacity(onPress == null ? 0.4 : 0.9),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
