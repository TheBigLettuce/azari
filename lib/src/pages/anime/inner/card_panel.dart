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

  static List<Widget> defaultCards(BuildContext context, AnimeEntry entry,
          {required bool isWatching,
          required bool inBacklog,
          required bool watched,
          Widget? replaceWatchCard}) =>
      [
        UnsizedCard(
          subtitle: Text("Year"),
          tooltip: "Year",
          title: Text(entry.year == 0 ? "?" : entry.year.toString()),
          transparentBackground: true,
        ),
        replaceWatchCard ??
            UnsizedCard(
              subtitle: Text(watched
                  ? "Watched"
                  : isWatching
                      ? inBacklog
                          ? "In backlog"
                          : "Watching"
                      : "Backlog"),
              title: watched
                  ? Icon(Icons.check_rounded,
                      color: Theme.of(context).colorScheme.primary)
                  : isWatching
                      ? const Icon(Icons.library_add_check)
                      : const Icon(Icons.add_rounded),
              tooltip: watched
                  ? "Watched"
                  : isWatching
                      ? inBacklog
                          ? "In backlog"
                          : "Watching"
                      : "Backlog",
              transparentBackground: true,
              onPressed: isWatching || watched
                  ? null
                  : () {
                      SavedAnimeEntry.addAll([entry], entry.site);
                    },
            ),
        UnsizedCard(
          subtitle: Text("Score"),
          tooltip: "Score",
          title: Text(entry.score == 0 ? "?" : entry.score.toString()),
          transparentBackground: true,
        ),
        UnsizedCard(
          subtitle: Text("In browser"),
          tooltip: "In browser",
          title: const Icon(Icons.public),
          transparentBackground: true,
          onPressed: () {
            launchUrl(Uri.parse(entry.siteUrl));
          },
        ),
        UnsizedCard(
          subtitle: Text("Airing"),
          tooltip: "Airing",
          title: Text(entry.isAiring ? "yes" : "no"),
          transparentBackground: true,
        ),
        if (entry.trailerUrl.isEmpty)
          const SizedBox.shrink()
        else
          UnsizedCard(
            subtitle: Text("Trailer"),
            tooltip: "Trailer",
            title: const Icon(Icons.smart_display_rounded),
            transparentBackground: true,
            onPressed: () {
              launchUrl(Uri.parse(entry.trailerUrl),
                  mode: LaunchMode.externalNonBrowserApplication);
            },
          ),
        UnsizedCard(
          subtitle: Text("Episodes"),
          tooltip: "Episodes",
          title: Text(entry.episodes == 0 ? "?" : entry.episodes.toString()),
          transparentBackground: true,
        ),
      ];

  const CardPanel(
      {super.key,
      required this.entry,
      required this.viewPadding,
      required this.site});

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
      children: CardPanel.defaultCards(context, widget.entry,
          isWatching: _isWatchingBacklog.$1,
          inBacklog: _isWatchingBacklog.$2,
          watched: _watched),
    );
  }
}

class CardShell extends StatefulWidget {
  final List<Widget> children;
  final AnimeEntry entry;
  final EdgeInsets viewPadding;

  const CardShell(
      {super.key,
      required this.entry,
      required this.viewPadding,
      required this.children});

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
                    children: widget.children,
                  ),
                  LeftArrow(show: _showArrorLeft),
                  RightArrow(show: _showArrowRight),
                ],
              )),
            )
            // IconButton(onPressed: () {}, icon:)/s
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
