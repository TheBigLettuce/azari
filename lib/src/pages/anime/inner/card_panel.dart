// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'anime_inner.dart';

class CardPanel extends StatefulWidget {
  final AnimeEntry entry;
  final AnimeMetadata site;
  final EdgeInsets viewPadding;

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

  const CardPanel({
    super.key,
    required this.entry,
    required this.viewPadding,
    required this.site,
  });

  @override
  State<CardPanel> createState() => _CardPanelState();
}

class _CardPanelState extends State<CardPanel> {
  late final StreamSubscription<void> entriesWatcher;

  late (bool, bool) _isWatchingBacklog =
      SavedAnimeEntry.isWatchingBacklog(widget.entry.id, widget.site);

  late bool _watched =
      WatchedAnimeEntry.watched(widget.entry.id, widget.entry.site);

  @override
  void initState() {
    super.initState();

    entriesWatcher = SavedAnimeEntry.watchAll((_) {
      _isWatchingBacklog =
          SavedAnimeEntry.isWatchingBacklog(widget.entry.id, widget.site);

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
      entry: widget.entry,
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

class CardShell extends StatefulWidget {
  final List<Widget> buttons;
  final List<Widget> info;
  final AnimeEntry entry;
  final EdgeInsets viewPadding;

  const CardShell({
    super.key,
    required this.entry,
    required this.viewPadding,
    required this.info,
    required this.buttons,
  });

  @override
  State<CardShell> createState() => _CardShellState();
}

class _CardShellState extends State<CardShell> {
  final cardsController = ScrollController();

  bool _showArrowRight = true;
  bool _showArrorLeft = false;

  @override
  void initState() {
    super.initState();

    cardsController.addListener(() {
      if (cardsController.offset > 0 && !_showArrorLeft) {
        _showArrorLeft = true;

        setState(() {});
      } else if (cardsController.offset == 0 && _showArrorLeft) {
        _showArrorLeft = false;

        setState(() {});
      }

      if (cardsController.position.maxScrollExtent == cardsController.offset &&
          _showArrowRight) {
        _showArrowRight = false;

        setState(() {});
      } else if (cardsController.position.maxScrollExtent !=
              cardsController.offset &&
          !_showArrowRight) {
        _showArrowRight = true;

        setState(() {});
      }
    });

    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      if (cardsController.position.maxScrollExtent == 0) {
        _showArrowRight = false;

        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    cardsController.dispose();

    super.dispose();
  }

  List<Widget> _insertBlanks(List<Widget> from, List<Widget> compared) {
    if (from.length == compared.length) {
      final res = <Widget>[];
      for (final e in from.indexed) {
        res.add(e.$2);
        res.add(compared[e.$1]);
      }

      return res;
    }

    final res = <Widget>[];
    for (final e in from.indexed) {
      res.add(e.$2);
      res.add(compared.elementAtOrNull(e.$1) ?? const SizedBox.shrink());
    }

    return res;
  }

  List<Widget> _merge() {
    return _insertBlanks(widget.info, widget.buttons);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2 +
          kToolbarHeight +
          widget.viewPadding.top +
          MediaQuery.sizeOf(context).height * 0.3,
      child: Padding(
        padding: EdgeInsets.only(
            top: 2 + kToolbarHeight + widget.viewPadding.top,
            left: 22,
            right: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimeNameWidget(entry: widget.entry),
            Theme(
              data: Theme.of(context).copyWith(
                  iconTheme: IconThemeData(
                      color:
                          Theme.of(context).iconTheme.color?.withOpacity(0.8))),
              child: Expanded(
                  child: Stack(
                children: [
                  GridView(
                    controller: cardsController,
                    scrollDirection: Axis.horizontal,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2),
                    children: _merge(),
                  ),
                  LeftArrow(show: _showArrorLeft),
                  RightArrow(show: _showArrowRight),
                ],
              )),
            )
          ],
        ),
      ),
    );
  }
}

class LeftArrow extends StatelessWidget {
  final bool show;

  const LeftArrow({super.key, required this.show});

  @override
  Widget build(BuildContext context) {
    return Animate(
      target: show ? 1 : 0,
      effects: [
        FadeEffect(
            duration: 200.ms,
            curve: Easing.emphasizedAccelerate,
            begin: 0,
            end: 1)
      ],
      child: Align(
        alignment: Alignment.centerLeft,
        child: Icon(
          Icons.arrow_left,
          color: Theme.of(context).iconTheme.color?.withOpacity(0.2),
        ),
      ),
    );
  }
}

class RightArrow extends StatelessWidget {
  final bool show;

  const RightArrow({super.key, required this.show});

  @override
  Widget build(BuildContext context) {
    return Animate(
      target: show ? 1 : 0,
      effects: [
        FadeEffect(
            duration: 200.ms,
            curve: Easing.emphasizedAccelerate,
            begin: 0,
            end: 1)
      ],
      child: Align(
        alignment: Alignment.centerRight,
        child: Icon(
          Icons.arrow_right,
          color: Theme.of(context).iconTheme.color?.withOpacity(0.2),
        ),
      ),
    );
  }
}
