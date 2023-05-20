import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/schemas/excluded_tags.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:gallery/src/system_gestures.dart';
import 'package:logging/logging.dart';

import '../db/isar.dart';
import 'infinite_scroll.dart';
import 'interface.dart';

class SearchBooru extends StatefulWidget {
  //final void Function(String) onSubmitted;
  const SearchBooru({super.key});

  @override
  State<SearchBooru> createState() => _SearchBooruState();
}

class _SearchBooruState extends State<SearchBooru> {
  final BooruTags _tags = BooruTags();
  List<String> _lastTags = [];
  late final StreamSubscription<void> _lastTagsWatcher;
  List<String> _excludedTags = [];
  late final StreamSubscription<void> _excludedTagsWatcher;

  FocusNode focus = FocusNode();
  FocusNode excludedFocus = FocusNode();

  TextEditingController textController = TextEditingController();
  TextEditingController excludedTagsTextController = TextEditingController();

  AnimationController? replaceController;
  AnimationController? deleteAllExcludedController;
  AnimationController? deleteAllController;

  @override
  void initState() {
    super.initState();
    _lastTagsWatcher =
        isar().lastTags.watchLazy(fireImmediately: true).listen((event) {
      setState(() {
        _lastTags = _tags.getLatest();
      });
    });
    _excludedTagsWatcher =
        isar().excludedTags.watchLazy(fireImmediately: true).listen((event) {
      setState(() {
        _excludedTags = _tags.getExcluded();
      });
    });
  }

  void _onTagPressed(String tag) {
    tag = tag.trim();
    if (tag.isEmpty) {
      return;
    }

    _tags.addLatest(tag);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search"),
      ),
      body: gestureDeadZones(context,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: autocompleteWidget(textController, _onTagPressed, focus,
                    roundBorders: true, showSearch: true),
              ),
              ListTile(
                title: const Text("Recent Tags"),
                trailing: IconButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          DialogRoute(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text(
                                    "Are you sure you want to delete all the tags?"),
                                actions: [
                                  TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text("no")),
                                  TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        if (deleteAllController != null) {
                                          deleteAllController!
                                              .forward(from: 0)
                                              .then((value) {
                                            isar().writeTxnSync(() =>
                                                isar().lastTags.clearSync());
                                            if (deleteAllController != null) {
                                              deleteAllController!
                                                  .reverse(from: 1);
                                            }
                                          });
                                        }
                                      },
                                      child: const Text("yes"))
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
                            _tags.deleteTag(t);
                            if (deleteAllController != null) {
                              deleteAllController!.reverse(from: 1);
                            }
                          });
                        } else {
                          _tags.deleteTag(t);
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
                title: const Text("Excluded Tags"),
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
                              title: autocompleteWidget(
                                  excludedTagsTextController,
                                  _tags.addExcluded,
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
                  autoPlay: false),
              TagsWidget(
                      redBackground: true,
                      tags: _excludedTags,
                      deleteTag: (t) {
                        if (deleteAllExcludedController != null) {
                          deleteAllExcludedController!
                              .forward(from: 0)
                              .then((value) {
                            _tags.deleteExcludedTag(t);
                            if (deleteAllExcludedController != null) {
                              deleteAllExcludedController!.reverse(from: 1);
                            }
                          });
                        } else {
                          _tags.deleteExcludedTag(t);
                        }
                      },
                      onPress: (t) {})
                  .animate(
                      onInit: (controller) =>
                          deleteAllExcludedController = controller,
                      effects: const [FadeEffect(begin: 1, end: 0)],
                      autoPlay: false)
            ],
          )),
    );
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
      child: Wrap(
        spacing: 2,
        runSpacing: -6,
        children: tags.map((tag) {
          return GestureDetector(
            onLongPress: () {
              HapticFeedback.vibrate();
              Navigator.of(context).push(DialogRoute(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: const Text("Do you want to delete"),
                        content: Text(tag),
                        actions: [
                          TextButton(
                              onPressed: () {
                                deleteTag(tag);
                                Navigator.of(context).pop();
                              },
                              child: const Text("yes"))
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
