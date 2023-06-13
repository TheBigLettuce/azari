// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/pages/senitel.dart';
import 'package:gallery/src/widgets/booru/single_post.dart';
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/schemas/excluded_tags.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:logging/logging.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../booru/interface.dart';
import '../db/isar.dart';
import '../keybinds/keybinds.dart';
import '../widgets/booru/autocomplete_tag.dart';
import 'booru_scroll.dart';

class SearchBooru extends StatefulWidget {
  const SearchBooru({super.key});

  @override
  State<SearchBooru> createState() => _SearchBooruState();
}

class _SearchBooruState extends State<SearchBooru> {
  final BooruTags _tags = BooruTags();
  BooruAPI booru = getBooru();
  List<String> _lastTags = [];
  late final StreamSubscription<void> _lastTagsWatcher;
  List<String> _excludedTags = [];
  late final StreamSubscription<void> _excludedTagsWatcher;

  FocusNode mainFocus = FocusNode();
  FocusNode focus = FocusNode();
  FocusNode excludedFocus = FocusNode();
  FocusNode singlePostFocus = FocusNode();

  String searchHighlight = "";
  String excludedHighlight = "";

  TextEditingController textController = TextEditingController();
  TextEditingController excludedTagsTextController = TextEditingController();

  AnimationController? replaceController;
  AnimationController? deleteAllExcludedController;
  AnimationController? deleteAllController;

  GlobalKey<ScaffoldState> key = GlobalKey();

  @override
  void initState() {
    focus.addListener(() {
      if (!focus.hasFocus) {
        searchHighlight = "";
        mainFocus.requestFocus();
      }
    });

    excludedFocus.addListener(() {
      if (!excludedFocus.hasFocus) {
        excludedHighlight = "";
        mainFocus.requestFocus();
      }
    });

    singlePostFocus.addListener(() {
      if (!singlePostFocus.hasFocus) {
        mainFocus.requestFocus();
      }
    });

    super.initState();
    _lastTagsWatcher =
        isar().lastTags.watchLazy(fireImmediately: true).listen((event) {
      setState(() {
        _lastTags = _tags.latest.getStrings();
      });
    });
    _excludedTagsWatcher =
        isar().excludedTags.watchLazy(fireImmediately: true).listen((event) {
      setState(() {
        _excludedTags = _tags.excluded.getStrings();
      });
    });
  }

  void _onTagPressed(String tag) {
    tag = tag.trim();
    if (tag.isEmpty) {
      return;
    }

    _tags.latest.add(tag);
    newSecondaryGrid().then((value) {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return BooruScroll.secondary(
          isar: value,
          tags: tag,
        );
      }));
    }).onError((error, stackTrace) {
      log("opening a secondary grid on tag $tag",
          level: Level.SEVERE.value, error: error, stackTrace: stackTrace);
    });
  }

  @override
  void dispose() {
    textController.dispose();
    excludedTagsTextController.dispose();
    _lastTagsWatcher.cancel();
    _excludedTagsWatcher.cancel();
    focus.dispose();
    excludedFocus.dispose();
    singlePostFocus.dispose();
    mainFocus.dispose();

    booru.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return makeSkeleton(context, kTagsDrawerIndex,
        AppLocalizations.of(context)!.tagsPageName, key, mainFocus,
        additionalBindings: {
          SingleActivatorDescription(
                  AppLocalizations.of(context)!.selectSuggestion,
                  const SingleActivator(LogicalKeyboardKey.enter, shift: true)):
              () {
            if (focus.hasFocus) {
              if (searchHighlight.isNotEmpty) {
                _onTagPressed(searchHighlight);
              }
            } else if (excludedFocus.hasFocus) {
              if (excludedHighlight.isNotEmpty) {
                _tags.excluded.add(excludedHighlight);
                excludedTagsTextController.text = "";
              }
            }
          },
          SingleActivatorDescription(
              AppLocalizations.of(context)!.focusSearch,
              const SingleActivator(LogicalKeyboardKey.keyF,
                  control: true)): () {
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
            child: autocompleteWidget(textController, (s) {
              searchHighlight = s;
            }, _onTagPressed, booru.completeTag, focus,
                roundBorders: true, showSearch: true),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.singlePostTitle),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: SinglePost(singlePostFocus),
          ),
          ListTile(
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
                                  child:
                                      Text(AppLocalizations.of(context)!.no)),
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    if (deleteAllController != null) {
                                      deleteAllController!
                                          .forward(from: 0)
                                          .then((value) {
                                        isar().writeTxnSync(
                                            () => isar().lastTags.clearSync());
                                        if (deleteAllController != null) {
                                          deleteAllController!.reverse(from: 1);
                                        }
                                      });
                                    }
                                  },
                                  child:
                                      Text(AppLocalizations.of(context)!.yes))
                            ],
                          );
                        },
                      ));
                },
                icon: const Icon(Icons.delete)),
          ),
          TagsWidget(
                  tags: _lastTags,
                  deleteTag: (t) {
                    if (deleteAllController != null) {
                      deleteAllController!.forward(from: 0).then((value) {
                        _tags.latest.delete(t);
                        if (deleteAllController != null) {
                          deleteAllController!.reverse(from: 1);
                        }
                      });
                    } else {
                      _tags.latest.delete(t);
                    }
                  },
                  onPress: _onTagPressed)
              .animate(
                  onInit: (controller) => deleteAllController = controller,
                  effects: [
                    FadeEffect(begin: 1, end: 0, duration: 200.milliseconds)
                  ],
                  autoPlay: false),
          ListTile(
            title: Text(AppLocalizations.of(context)!.excludedTagsTitle),
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
                FadeEffect(begin: 1, end: 0, duration: 200.milliseconds),
                SwapEffect(
                    builder: (_, __) => ListTile(
                          title: autocompleteWidget(excludedTagsTextController,
                              (s) {
                            excludedHighlight = s;
                          }, _tags.excluded.add, booru.completeTag,
                              excludedFocus,
                              submitOnPress: true, showSearch: true),
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
              autoPlay: false),
          TagsWidget(
                  redBackground: true,
                  tags: _excludedTags,
                  deleteTag: (t) {
                    if (deleteAllExcludedController != null) {
                      deleteAllExcludedController!
                          .forward(from: 0)
                          .then((value) {
                        _tags.excluded.delete(t);
                        if (deleteAllExcludedController != null) {
                          deleteAllExcludedController!.reverse(from: 1);
                        }
                      });
                    } else {
                      _tags.excluded.delete(t);
                    }
                  },
                  onPress: (t) {})
              .animate(
                  onInit: (controller) =>
                      deleteAllExcludedController = controller,
                  effects: const [FadeEffect(begin: 1, end: 0)],
                  autoPlay: false)
        ]);
  }
}

class TagsWidget extends StatelessWidget {
  final void Function(String tag) deleteTag;
  final void Function(String tag)? onPress;
  final bool redBackground;
  final List<String> tags;
  const TagsWidget(
      {super.key,
      required this.tags,
      this.redBackground = false,
      required this.deleteTag,
      required this.onPress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: tags.isEmpty
          ? const EmptyWidget()
          : Wrap(
              runSpacing: 2,
              children: tags.map((tag) {
                return GestureDetector(
                  onLongPress: () {
                    HapticFeedback.vibrate();
                    Navigator.of(context).push(DialogRoute(
                        context: context,
                        builder: (context) => AlertDialog(
                              title: Text(AppLocalizations.of(context)!
                                  .tagDeleteDialogTitle),
                              content: Text(tag),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      deleteTag(tag);
                                      Navigator.of(context).pop();
                                    },
                                    child:
                                        Text(AppLocalizations.of(context)!.yes))
                              ],
                            )));
                  },
                  child: ActionChip(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    side: redBackground
                        ? BorderSide(color: Colors.pink.shade200)
                        : null,
                    backgroundColor: redBackground ? Colors.pink : null,
                    label: Text(tag,
                        style: redBackground
                            ? TextStyle(color: Colors.white.withOpacity(0.8))
                            : null),
                    onPressed: onPress == null
                        ? null
                        : () {
                            onPress!(tag);
                          },
                  ),
                );
              }).toList(),
            ),
    );
  }
}
