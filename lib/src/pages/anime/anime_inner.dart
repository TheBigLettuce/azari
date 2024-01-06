// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/interfaces/anime.dart';
import 'package:gallery/src/pages/image_view.dart';
import 'package:gallery/src/plugs/platform_functions.dart';
import 'package:gallery/src/widgets/dashboard_card.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_settings.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';
import 'package:url_launcher/url_launcher.dart';

class AnimeInner extends StatefulWidget {
  final AnimeEntry entry;

  const AnimeInner({super.key, required this.entry});

  @override
  State<AnimeInner> createState() => _AnimeInnerState();
}

class _AnimeInnerState extends State<AnimeInner> with TickerProviderStateMixin {
  final state = SkeletonState();
  final scrollController = ScrollController();
  final cardsController = ScrollController();

  bool _extendSynopsis = false;
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
    scrollController.dispose();
    cardsController.dispose();

    state.dispose();

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

    return SkeletonSettings(
      "Anime inner",
      state,
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child:
              _AppBar(entry: widget.entry, scrollController: scrollController)),
      extendBodyBehindAppBar: true,
      child: SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom),
          child: Stack(
            children: [
              Container(
                width: MediaQuery.sizeOf(context).width,
                height: MediaQuery.sizeOf(context).height * 0.3 +
                    kToolbarHeight +
                    MediaQuery.viewPaddingOf(context).top,
                foregroundDecoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Theme.of(context).colorScheme.background,
                        Theme.of(context)
                            .colorScheme
                            .background
                            .withOpacity(0.8),
                        Theme.of(context)
                            .colorScheme
                            .background
                            .withOpacity(0.6),
                        Theme.of(context)
                            .colorScheme
                            .background
                            .withOpacity(0.4)
                      ]),
                ),
                decoration: BoxDecoration(
                  image: DecorationImage(
                      fit: BoxFit.cover,
                      opacity: 0.4,
                      filterQuality: FilterQuality.high,
                      colorFilter: const ColorFilter.mode(
                          Colors.black87, BlendMode.softLight),
                      image: widget.entry
                          .getCellData(false, context: context)
                          .thumb!),
                ),
              ),
              SizedBox(
                height: 2 +
                    kToolbarHeight +
                    MediaQuery.viewPaddingOf(context).top +
                    MediaQuery.sizeOf(context).height * 0.3,
                child: Padding(
                  padding: EdgeInsets.only(
                      top: 2 +
                          kToolbarHeight +
                          MediaQuery.viewPaddingOf(context).top,
                      left: 22,
                      right: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: widget.entry.titleSynonyms.isEmpty
                            ? title()
                            : Tooltip(
                                triggerMode: Platform.isAndroid
                                    ? TooltipTriggerMode.tap
                                    : null,
                                showDuration: 2.seconds,
                                message:
                                    "Also known as:\n${widget.entry.titleSynonyms.reduce((value, element) => '$value\n$element')}",
                                child: title(),
                              ),
                      ),
                      Theme(
                        data: Theme.of(context).copyWith(
                            iconTheme: IconThemeData(
                                color: Theme.of(context)
                                    .iconTheme
                                    .color
                                    ?.withOpacity(0.8))),
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
                                  title: Text(
                                      widget.entry.isAiring ? "yes" : "no"),
                                  transparentBackground: true,
                                ),
                                if (widget.entry.trailerUrl.isEmpty)
                                  const SizedBox.shrink()
                                else
                                  UnsizedCard(
                                    subtitle: Text("Trailer"),
                                    tooltip: "Trailer",
                                    title:
                                        const Icon(Icons.smart_display_rounded),
                                    transparentBackground: true,
                                    onPressed: () {
                                      launchUrl(
                                          Uri.parse(widget.entry.trailerUrl),
                                          mode: LaunchMode
                                              .externalNonBrowserApplication);
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
                                  color: Theme.of(context)
                                      .iconTheme
                                      .color
                                      ?.withOpacity(0.2),
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
                                  color: Theme.of(context)
                                      .iconTheme
                                      .color
                                      ?.withOpacity(0.2),
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
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.sizeOf(context).height * 0.3 +
                      kToolbarHeight +
                      MediaQuery.viewPaddingOf(context).top,
                  left: 8,
                  right: 8,
                ),
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Wrap(
                        spacing: 4,
                        children: widget.entry.genres
                            .map((e) => Chip(
                                  surfaceTintColor:
                                      Theme.of(context).colorScheme.surfaceTint,
                                  elevation: 4,
                                  labelStyle: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.8)),
                                  visualDensity: VisualDensity.compact,
                                  label: Text(e),
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25)),
                                ))
                            .toList(),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.only(top: 8)),
                    _SegmentConstrained(
                      content: widget.entry.synopsis,
                      label: "Synopsis",
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width - 16 - 16),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBar extends StatefulWidget {
  final AnimeEntry entry;
  final ScrollController scrollController;

  const _AppBar(
      {super.key, required this.entry, required this.scrollController});

  @override
  State<_AppBar> createState() => __AppBarState();
}

class __AppBarState extends State<_AppBar> with SingleTickerProviderStateMixin {
  late final animation = AnimationController(
      animationBehavior: AnimationBehavior.preserve,
      vsync: this,
      duration: 300.ms,
      reverseDuration: 300.ms,
      value: 0);

  bool _opaqueAppBar = false;

  @override
  void initState() {
    super.initState();

    animation.addListener(() {
      setState(() {});
    });

    widget.scrollController.addListener(_animate);
  }

  void _animate() {
    if (widget.scrollController.offset != 0 && !_opaqueAppBar) {
      animation.animateTo(1, curve: Easing.standard);
      _opaqueAppBar = true;
    } else if (widget.scrollController.offset == 0 && _opaqueAppBar) {
      animation.animateBack(0, curve: Easing.standard);
      _opaqueAppBar = false;
    }
  }

  @override
  void dispose() {
    animation.dispose();
    widget.scrollController.removeListener(_animate);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      actions: [
        IconButton(
          onPressed: () {
            final overlayColor =
                Theme.of(context).colorScheme.background.withOpacity(0.5);

            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return ImageView(
                  ignoreEndDrawer: false,
                  updateTagScrollPos: (_, __) {},
                  cellCount: 1,
                  scrollUntill: (_) {},
                  startingCell: 0,
                  onExit: () {},
                  getCell: (_) => widget.entry,
                  onNearEnd: null,
                  focusMain: () {},
                  systemOverlayRestoreColor: overlayColor,
                );
              },
            ));
          },
          icon: const Icon(Icons.image),
        )
      ],
      surfaceTintColor: Colors.transparent
      // ColorTween(
      // begin: Colors.transparent,
      // end: Theme.of(context).colorScheme.surfaceTint,
      // ).lerp(animation.value)
      ,
      // forceMaterialTransparency: true,
      backgroundColor: ColorTween(
              begin: Colors.transparent,
              end: Theme.of(context).colorScheme.background.withOpacity(0.8))
          .transform(animation.value),
      // title: Text(widget.entry.title),
    );
  }
}

class _SegmentConstrained extends StatelessWidget {
  final String label;
  final String content;
  final BoxConstraints constraints;

  const _SegmentConstrained(
      {super.key,
      required this.content,
      required this.label,
      this.constraints = const BoxConstraints(maxWidth: 200, maxHeight: 300)});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      direction: Axis.vertical,
      children: [
        _Label(text: label),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4, right: 4),
          child: AnimatedContainer(
            duration: 200.ms,
            constraints: constraints,
            child: Text(
              content,
              overflow: TextOverflow.fade,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
            ),
          ),
        )
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final String content;

  const _Segment({super.key, required this.content, required this.label});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      direction: Axis.vertical,
      children: [
        _Label(text: label),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            content,
            overflow: TextOverflow.fade,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
          ),
        )
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
              letterSpacing: 0.5,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
      ),
    );
  }
}
