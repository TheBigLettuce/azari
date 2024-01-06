// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/schemas/tags/tags.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../interfaces/booru/booru_api_state.dart';
import '../db/state_restoration.dart';
import '../widgets/search_bar/autocomplete/autocomplete_widget.dart';
import '../widgets/single_post.dart';
import '../widgets/tags_widget.dart';
import 'notes/tab_with_count.dart';

class TagsPage extends StatefulWidget {
  final TagManager<Unrestorable> tagManager;
  final FocusNode mainFocus;
  final BooruAPIState booru;

  const TagsPage(
      {super.key,
      required this.tagManager,
      required this.mainFocus,
      required this.booru});

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> with TickerProviderStateMixin {
  final excludedFocus = FocusNode();
  final singlePostFocus = FocusNode();

  late final tabController = TabController(length: 2, vsync: this);

  final textController = TextEditingController();
  final excludedTagsTextController = TextEditingController();

  late final StreamSubscription<void> _lastTagsWatcher;

  List<Tag> _excludedTags = [];
  List<Tag> _lastTags = [];

  String searchHighlight = "";
  String excludedHighlight = "";

  late final AnimationController deleteAllExcludedController =
      AnimationController(vsync: this);
  late final AnimationController deleteAllController =
      AnimationController(vsync: this);

  int currentNavBarIndex = 0;

  void _focusListener() {
    if (!widget.mainFocus.hasFocus) {
      searchHighlight = "";
      widget.mainFocus.requestFocus();
    }
  }

  @override
  void initState() {
    widget.mainFocus.addListener(_focusListener);

    excludedFocus.addListener(() {
      if (!excludedFocus.hasFocus) {
        excludedHighlight = "";
        widget.mainFocus.requestFocus();
      }
    });

    singlePostFocus.addListener(() {
      if (!singlePostFocus.hasFocus) {
        widget.mainFocus.requestFocus();
      }
    });

    super.initState();
    _lastTagsWatcher = widget.tagManager.watch(true, () {
      _lastTags = widget.tagManager.latest.get();
      _excludedTags = widget.tagManager.excluded.get();

      setState(() {});
    });
  }

  @override
  void dispose() {
    widget.mainFocus.removeListener(_focusListener);
    textController.dispose();
    excludedTagsTextController.dispose();
    _lastTagsWatcher.cancel();

    deleteAllController.dispose();
    deleteAllExcludedController.dispose();

    excludedFocus.dispose();
    singlePostFocus.dispose();

    tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: NestedScrollView(
      headerSliverBuilder: (context, scrolled) => [
        SliverAppBar(
          pinned: true,
          floating: true,
          snap: true,
          centerTitle: true,
          title: Text(
            "阿",
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontFamily: "ZenKurenaido"),
          ),
          bottom: TabBar(
            tabs: [
              TabWithCount("Recent", _lastTags.length),
              TabWithCount("Excluded", _excludedTags.length),
            ],
            controller: tabController,
          ),
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      DialogRoute(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(AppLocalizations.of(context)!
                                .tagsDeletionDialogTitle),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child:
                                      Text(AppLocalizations.of(context)!.no)),
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    deleteAllController
                                        .forward(from: 0)
                                        .then((value) {
                                      widget.tagManager.latest.clear();
                                      deleteAllController.reverse(from: 1);
                                    });
                                  },
                                  child:
                                      Text(AppLocalizations.of(context)!.yes))
                            ],
                          );
                        },
                      ));
                },
                icon: const Icon(Icons.delete))
          ],
        )
      ],
      body: TabBarView(controller: tabController, children: [
        TagsWidget(
            tags: _lastTags,
            searchBar: SinglePost(
              focus: singlePostFocus,
              tagManager: widget.tagManager,
            ),
            deleteTag: (t) {
              deleteAllController.forward(from: 0).then((value) {
                widget.tagManager.latest.delete(t);
                deleteAllController.reverse(from: 1);
              });
            },
            onPress: (t) => widget.tagManager
                .onTagPressed(context, t, widget.booru.booru, true)).animate(
            controller: deleteAllController,
            effects: [
              FadeEffect(
                begin: 1,
                end: 0,
                duration: 150.milliseconds,
              )
            ],
            autoPlay: false),
        TagsWidget(
                redBackground: true,
                tags: _excludedTags,
                searchBar: AutocompleteWidget(
                  excludedTagsTextController,
                  (s) {
                    excludedHighlight = s;
                  },
                  widget.tagManager.excluded.add,
                  () => widget.mainFocus.requestFocus(),
                  widget.booru.completeTag,
                  excludedFocus,
                  submitOnPress: true,
                  roundBorders: true,
                  plainSearchBar: true,
                  showSearch: true,
                ),
                deleteTag: (t) {
                  deleteAllExcludedController.forward(from: 0).then((value) {
                    widget.tagManager.excluded.delete(t);
                    deleteAllExcludedController.reverse(from: 1);
                  });
                },
                onPress: (t) {})
            .animate(effects: [
          FadeEffect(
            begin: 1,
            end: 0,
            duration: 150.milliseconds,
          )
        ], controller: deleteAllExcludedController, autoPlay: false),
      ]),
    ));
  }
}
