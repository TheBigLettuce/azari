import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/schemas/excluded_tags.dart';
import 'package:gallery/src/schemas/tags.dart';

import '../db/isar.dart';
import 'interface.dart';

class SearchBooru extends StatefulWidget {
  final void Function(String) onSubmitted;
  const SearchBooru({super.key, required this.onSubmitted});

  @override
  State<SearchBooru> createState() => _SearchBooruState();
}

class _SearchBooruState extends State<SearchBooru> {
  final BooruTags _tags = BooruTags();
  List<String> _lastTags = [];
  late final StreamSubscription<void> _lastTagsWatcher;
  List<String> _excludedTags = [];
  late final StreamSubscription<void> _excludedTagsWatcher;
  List<Widget> menuItems = [];
  MenuController menuController = MenuController();
  TextEditingController textController = TextEditingController();

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

  List<String> _searchFilter(String value) => value.isEmpty
      ? []
      : _lastTags.where((element) => element.contains(value)).toList();

  @override
  void dispose() {
    _lastTagsWatcher.cancel();
    _excludedTagsWatcher.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search"),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 5, right: 5),
            child: MenuAnchor(
              menuChildren: menuItems,
              style: tagCompleteMenuStyle(),
              controller: menuController,
              child: TextField(
                controller: textController,
                onChanged: (value) {
                  menuItems.clear();
                  autoCompleteTag(value, menuController, textController,
                          getBooru().completeTag)
                      .then((newItems) {
                    if (newItems.isEmpty) {
                      menuController.close();
                    } else {
                      setState(() {
                        menuItems = newItems;
                      });
                      menuController.open();
                    }
                  }).onError((error, stackTrace) {
                    print(error);
                  });
                },
                decoration: const InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(50)))),
                onSubmitted: (value) {
                  _tags.addLatest(value);
                  widget.onSubmitted(value);
                },
              ),
            ),
          ),
          const ListTile(
            title: Text("Last Tags"),
          ),
          TagsWidget(
              tags: _lastTags,
              deleteTag: _tags.deleteTag,
              onPress: widget.onSubmitted),
          ListTile(
            title: const Text("Excluded Tags"),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.of(context).push(DialogRoute(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      content: TextField(
                        onSubmitted: (value) {
                          _tags.addExcluded(value);
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                ));
              },
            ),
          ),
          TagsWidget(
              redBackground: true,
              tags: _excludedTags,
              deleteTag: _tags.deleteExcludedTag,
              onPress: (t) {})
        ],
      ),
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
        children: tags
            .map((tag) => GestureDetector(
                  onLongPress: () {
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
                    backgroundColor: redBackground
                        ? const Color.fromARGB(255, 243, 0, 113)
                        : null,
                    side: redBackground
                        ? const BorderSide(color: Colors.white60)
                        : null,
                    label: Text(tag),
                    onPressed: onPress == null
                        ? null
                        : () {
                            onPress!(tag);
                          },
                  ),
                ))
            .toList(),
      ),
    );
  }
}
