// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/schemas/tags.dart';
import 'package:gallery/src/widgets/skeletons/make_skeleton.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../interfaces/booru.dart';
import '../db/state_restoration.dart';
import '../widgets/skeletons/drawer/destinations.dart';
import '../widgets/search_bar/autocomplete/autocomplete_widget.dart';
import '../widgets/keybinds/single_activator_description.dart';
import '../widgets/single_post.dart';
import '../widgets/skeletons/skeleton_state.dart';
import '../widgets/tags_widget.dart';

class TagsPage extends StatefulWidget {
  final TagManager tagManager;
  final bool popSenitel;
  final bool fromGallery;

  const TagsPage(
      {super.key,
      required this.tagManager,
      required this.popSenitel,
      required this.fromGallery});

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> with TickerProviderStateMixin {
  final booru = BooruAPI.fromSettings();

  final focus = FocusNode();
  final excludedFocus = FocusNode();
  final singlePostFocus = FocusNode();

  final textController = TextEditingController();
  final excludedTagsTextController = TextEditingController();

  final skeletonState = SkeletonState(kTagsDrawerIndex);

  late final StreamSubscription<void> _lastTagsWatcher;

  List<Tag> _excludedTags = [];
  List<Tag> _lastTags = [];

  String searchHighlight = "";
  String excludedHighlight = "";

  AnimationController? replaceController;

  late final AnimationController deleteAllExcludedController =
      AnimationController(vsync: this);
  late final AnimationController deleteAllController =
      AnimationController(vsync: this);

  bool recentTagsExpanded = true;
  bool excludedTagsExpanded = true;

  int currentNavBarIndex = 0;

  @override
  void initState() {
    focus.addListener(() {
      if (!focus.hasFocus) {
        searchHighlight = "";
        skeletonState.mainFocus.requestFocus();
      }
    });

    excludedFocus.addListener(() {
      if (!excludedFocus.hasFocus) {
        excludedHighlight = "";
        skeletonState.mainFocus.requestFocus();
      }
    });

    singlePostFocus.addListener(() {
      if (!singlePostFocus.hasFocus) {
        skeletonState.mainFocus.requestFocus();
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
    textController.dispose();
    excludedTagsTextController.dispose();
    _lastTagsWatcher.cancel();
    focus.dispose();

    deleteAllController.dispose();
    deleteAllExcludedController.dispose();

    excludedFocus.dispose();
    singlePostFocus.dispose();
    skeletonState.dispose();

    booru.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bindings = {
      SingleActivatorDescription(AppLocalizations.of(context)!.selectSuggestion,
          const SingleActivator(LogicalKeyboardKey.enter, shift: true)): () {
        if (focus.hasFocus) {
          if (searchHighlight.isNotEmpty) {
            widget.tagManager.onTagPressed(
                context, Tag.string(tag: searchHighlight), booru.booru, true);
          }
        } else if (excludedFocus.hasFocus) {
          if (excludedHighlight.isNotEmpty) {
            widget.tagManager.excluded.add(Tag.string(tag: excludedHighlight));
            excludedTagsTextController.text = "";
          }
        }
      },
      SingleActivatorDescription(AppLocalizations.of(context)!.focusSearch,
          const SingleActivator(LogicalKeyboardKey.keyF, control: true)): () {
        if (focus.hasFocus) {
          focus.unfocus();
        } else {
          focus.requestFocus();
        }
      },
      SingleActivatorDescription(AppLocalizations.of(context)!.focusSinglePost,
          const SingleActivator(LogicalKeyboardKey.keyF, alt: true)): () {
        if (singlePostFocus.hasFocus) {
          singlePostFocus.unfocus();
        } else {
          singlePostFocus.requestFocus();
        }
      },
      SingleActivatorDescription(
          AppLocalizations.of(context)!.focusExcludedSearch,
          const SingleActivator(LogicalKeyboardKey.keyF, shift: true)): () {
        if (excludedFocus.hasFocus) {
          if (replaceController != null) {
            replaceController!
                .reverse(from: 1)
                .then((value) => excludedFocus.unfocus());
          } else {
            excludedFocus.unfocus();
          }
        } else {
          if (replaceController != null) {
            replaceController!
                .forward(from: 0)
                .then((value) => excludedFocus.requestFocus());
          } else {
            excludedFocus.requestFocus();
          }
        }
      },
    };

    return makeSkeleton(
      context,
      AppLocalizations.of(context)!.tagsInfoPage,
      skeletonState,
      additionalBindings: bindings,
      children: [
        switch (currentNavBarIndex) {
          0 => TagsWidget(
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
                  .onTagPressed(context, t, booru.booru, true)).animate(
              controller: deleteAllController,
              effects: [
                FadeEffect(
                  begin: 1,
                  end: 0,
                  duration: 150.milliseconds,
                )
              ],
              autoPlay: false),
          1 => TagsWidget(
                    redBackground: true,
                    tags: _excludedTags,
                    searchBar: autocompleteWidget(
                      excludedTagsTextController,
                      (s) {
                        excludedHighlight = s;
                      },
                      widget.tagManager.excluded.add,
                      () => focus.requestFocus(),
                      booru.completeTag,
                      excludedFocus,
                      submitOnPress: true,
                      roundBorders: true,
                      showSearch: true,
                    ),
                    deleteTag: (t) {
                      deleteAllExcludedController
                          .forward(from: 0)
                          .then((value) {
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
          int() => throw "invalid idx",
        }
      ],
      popSenitel: widget.popSenitel,
      appBarActions: currentNavBarIndex == 0
          ? [
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
                  icon: const Icon(Icons.delete)),
            ]
          : currentNavBarIndex == 1
              ? []
              : null,
      bottomNavBar: NavigationBar(
        selectedIndex: currentNavBarIndex,
        onDestinationSelected: (value) {
          if (value == 0) {
            deleteAllExcludedController.animateTo(1).then((_) {
              currentNavBarIndex = value;

              setState(() {});
              deleteAllExcludedController.reset();
            });
          } else {
            deleteAllController.animateTo(1).then((_) {
              currentNavBarIndex = value;

              setState(() {});
              deleteAllController.reset();
            });
          }
        },
        destinations: [
          NavigationDestination(
              label: "Recent",
              icon: Badge.count(
                count: _lastTags.length,
                child: const Icon(Icons.label),
              )),
          NavigationDestination(
              label: "Excluded",
              icon: Badge.count(
                count: _excludedTags.length,
                child: const Icon(Icons.label_off_rounded),
              ))
        ],
      ),
      overrideChooseRoute: widget.fromGallery
          ? (route, original) {
              if (route == kGalleryDrawerIndex) {
                Navigator.pop(context);
                Navigator.pop(context);
              } else {
                original();
              }
            }
          : null,
    );
  }
}
