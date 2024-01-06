// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'anime_inner.dart';

class _CardPanel extends StatefulWidget {
  final AnimeEntry entry;

  const _CardPanel({super.key, required this.entry});

  @override
  State<_CardPanel> createState() => __CardPanelState();
}

class __CardPanelState extends State<_CardPanel> {
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
    Widget title() => Column(
          children: [
            Text(
              widget.entry.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
            ),
            Text(
              "${widget.entry.titleEnglish} / ${widget.entry.titleJapanese}",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
            ),
          ],
        );

    return SizedBox(
      height: 2 +
          kToolbarHeight +
          MediaQuery.viewPaddingOf(context).top +
          MediaQuery.sizeOf(context).height * 0.3,
      child: Padding(
        padding: EdgeInsets.only(
            top: 2 + kToolbarHeight + MediaQuery.viewPaddingOf(context).top,
            left: 22,
            right: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: widget.entry.titleSynonyms.isEmpty
                  ? title()
                  : Tooltip(
                      triggerMode:
                          Platform.isAndroid ? TooltipTriggerMode.tap : null,
                      showDuration: Platform.isAndroid ? 2.seconds : null,
                      message:
                          "Also known as:\n${widget.entry.titleSynonyms.reduce((value, element) => '$value\n$element')}",
                      child: title(),
                    ),
            ),
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
                    children: [
                      UnsizedCard(
                        subtitle: Text("Year"),
                        tooltip: "Year",
                        title: Text(widget.entry.year == 0
                            ? "?"
                            : widget.entry.year.toString()),
                        transparentBackground: true,
                      ),
                      UnsizedCard(
                        subtitle: Text("Watch"),
                        title: const Icon(Icons.add_rounded),
                        tooltip: "Watch",
                        transparentBackground: true,
                        onPressed: () {
                          print("object");
                        },
                      ),
                      UnsizedCard(
                        subtitle: Text("Score"),
                        tooltip: "Score",
                        title: Text(widget.entry.score == 0
                            ? "?"
                            : widget.entry.score.toString()),
                        transparentBackground: true,
                      ),
                      UnsizedCard(
                        subtitle: Text("In browser"),
                        tooltip: "In browser",
                        title: const Icon(Icons.public),
                        transparentBackground: true,
                        onPressed: () {
                          launchUrl(Uri.parse(widget.entry.siteUrl));
                        },
                      ),
                      UnsizedCard(
                        subtitle: Text("Airing"),
                        tooltip: "Airing",
                        title: Text(widget.entry.isAiring ? "yes" : "no"),
                        transparentBackground: true,
                      ),
                      if (widget.entry.trailerUrl.isEmpty)
                        const SizedBox.shrink()
                      else
                        UnsizedCard(
                          subtitle: Text("Trailer"),
                          tooltip: "Trailer",
                          title: const Icon(Icons.smart_display_rounded),
                          transparentBackground: true,
                          onPressed: () {
                            launchUrl(Uri.parse(widget.entry.trailerUrl),
                                mode: LaunchMode.externalNonBrowserApplication);
                          },
                        ),
                      UnsizedCard(
                        subtitle: Text("Episodes"),
                        tooltip: "Episodes",
                        title: Text(widget.entry.episodes == 0
                            ? "?"
                            : widget.entry.episodes.toString()),
                        transparentBackground: true,
                      ),
                    ],
                  ),
                  Animate(
                    target: _showArrorLeft ? 1 : 0,
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
                        color:
                            Theme.of(context).iconTheme.color?.withOpacity(0.2),
                      ),
                    ),
                  ),
                  Animate(
                    target: _showArrowRight ? 1 : 0,
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
                        color:
                            Theme.of(context).iconTheme.color?.withOpacity(0.2),
                      ),
                    ),
                  )
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
