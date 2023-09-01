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
import 'package:gallery/src/widgets/booru/single_post.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../db/isar.dart';
import '../keybinds/keybinds.dart';
import '../widgets/booru/autocomplete_tag.dart';
import '../widgets/tags_widget.dart';
import 'booru_scroll.dart';

class SearchBooru extends StatefulWidget {
  final GridTab grids;
  final bool popSenitel;
  final bool fromGallery;

  const SearchBooru(
      {super.key,
      required this.grids,
      required this.popSenitel,
      required this.fromGallery});

  @override
  State<SearchBooru> createState() => _SearchBooruState();
}

class _SearchBooruState extends State<SearchBooru> {
  final booru = getBooru();

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
  AnimationController? deleteAllExcludedController;
  AnimationController? deleteAllController;

  bool recentTagsExpanded = true;
  bool excludedTagsExpanded = true;

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
    _lastTagsWatcher = widget.grids.instance.tags
        .watchLazy(fireImmediately: true)
        .listen((event) {
      _lastTags = widget.grids.latest.get();
      _excludedTags = widget.grids.excluded.get();

      setState(() {});
    });
  }

  @override
  void dispose() {
    textController.dispose();
    excludedTagsTextController.dispose();
    _lastTagsWatcher.cancel();
    focus.dispose();

    excludedFocus.dispose();
    singlePostFocus.dispose();
    skeletonState.dispose();

    booru.close();

    super.dispose();
  }

  void _onTagPressed(Tag tag) {
    tag = tag.trim();
    if (tag.tag.isEmpty) {
      return;
    }

    widget.grids.latest.add(tag);
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return BooruScroll.secondary(
        grids: widget.grids,
        instance: widget.grids.newSecondaryGrid(),
        tags: tag.tag,
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return makeSkeleton(
      context,
      AppLocalizations.of(context)!.tagsInfoPage,
      skeletonState,
      additionalBindings: {
        SingleActivatorDescription(
            AppLocalizations.of(context)!.selectSuggestion,
            const SingleActivator(LogicalKeyboardKey.enter, shift: true)): () {
          if (focus.hasFocus) {
            if (searchHighlight.isNotEmpty) {
              _onTagPressed(Tag.string(tag: searchHighlight));
            }
          } else if (excludedFocus.hasFocus) {
            if (excludedHighlight.isNotEmpty) {
              widget.grids.excluded.add(Tag.string(tag: excludedHighlight));
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
        SingleActivatorDescription(
            AppLocalizations.of(context)!.focusSinglePost,
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
      },
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: SinglePost(singlePostFocus),
        ),
        ExpansionPanelList(
          elevation: 0,
          dividerColor: Theme.of(context).colorScheme.background,
          expansionCallback: (panelIndex, isExpanded) => switch (panelIndex) {
            0 => setState(() => recentTagsExpanded = !isExpanded),
            1 => setState(() => excludedTagsExpanded = !isExpanded),
            int() => throw "out of range",
          },
          children: [
            ExpansionPanel(
                isExpanded: recentTagsExpanded,
                headerBuilder: (context, isExpanded) {
                  return ListTile(
                    title: Text(AppLocalizations.of(context)!.recentTagsTitle),
                    trailing: IconButton(
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
                                          child: Text(
                                              AppLocalizations.of(context)!
                                                  .no)),
                                      TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            if (deleteAllController != null) {
                                              deleteAllController!
                                                  .forward(from: 0)
                                                  .then((value) {
                                                widget.grids.latest.clear();
                                                if (deleteAllController !=
                                                    null) {
                                                  deleteAllController!
                                                      .reverse(from: 1);
                                                }
                                              });
                                            }
                                          },
                                          child: Text(
                                              AppLocalizations.of(context)!
                                                  .yes))
                                    ],
                                  );
                                },
                              ));
                        },
                        icon: const Icon(Icons.delete)),
                  );
                },
                body: TagsWidget(
                        tags: _lastTags,
                        deleteTag: (t) {
                          if (deleteAllController != null) {
                            deleteAllController!.forward(from: 0).then((value) {
                              widget.grids.latest.delete(t);
                              if (deleteAllController != null) {
                                deleteAllController!.reverse(from: 1);
                              }
                            });
                          } else {
                            widget.grids.latest.delete(t);
                          }
                        },
                        onPress: _onTagPressed)
                    .animate(
                        onInit: (controller) =>
                            deleteAllController = controller,
                        effects: [
                          FadeEffect(
                              begin: 1, end: 0, duration: 200.milliseconds)
                        ],
                        autoPlay: false)),
            ExpansionPanel(
                isExpanded: excludedTagsExpanded,
                headerBuilder: (context, isExpanded) {
                  return ListTile(
                    title:
                        Text(AppLocalizations.of(context)!.excludedTagsTitle),
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (replaceController != null) {
                          replaceController!.forward(from: 0);
                        }
                      },
                    ),
                  ).animate(
                      onInit: (controller) => replaceController = controller,
                      effects: [
                        FadeEffect(
                            begin: 1, end: 0, duration: 200.milliseconds),
                        SwapEffect(
                            builder: (_, __) => ListTile(
                                  title: autocompleteWidget(
                                      excludedTagsTextController, (s) {
                                    excludedHighlight = s;
                                  },
                                      widget.grids.excluded.add,
                                      () => focus.requestFocus(),
                                      booru.completeTag,
                                      excludedFocus,
                                      submitOnPress: true,
                                      showSearch: true),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.arrow_back),
                                    onPressed: () {
                                      if (replaceController != null) {
                                        replaceController!.reverse(from: 1);
                                      }
                                    },
                                  ),
                                ).animate().fadeIn()),
                      ],
                      autoPlay: false);
                },
                body: TagsWidget(
                        redBackground: true,
                        tags: _excludedTags,
                        deleteTag: (t) {
                          if (deleteAllExcludedController != null) {
                            deleteAllExcludedController!
                                .forward(from: 0)
                                .then((value) {
                              widget.grids.excluded.delete(t);
                              if (deleteAllExcludedController != null) {
                                deleteAllExcludedController!.reverse(from: 1);
                              }
                            });
                          } else {
                            widget.grids.excluded.delete(t);
                          }
                        },
                        onPress: (t) {})
                    .animate(
                        onInit: (controller) =>
                            deleteAllExcludedController = controller,
                        effects: const [FadeEffect(begin: 1, end: 0)],
                        autoPlay: false))
          ],
        ),
      ],
      popSenitel: widget.popSenitel,
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
