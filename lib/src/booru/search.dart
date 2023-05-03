import 'package:flutter/material.dart';
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/schemas/tags.dart';

class SearchBooru extends StatefulWidget {
  final void Function(String) onSubmitted;
  const SearchBooru({super.key, required this.onSubmitted});

  @override
  State<SearchBooru> createState() => _SearchBooruState();
}

class _SearchBooruState extends State<SearchBooru> {
  final Tags _tags = Tags();
  List<LastTag> _lastTags = [];

  @override
  void initState() {
    super.initState();

    () async {
      setState(() {
        _lastTags = _tags.getLatest();
      });
    }();
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
            child: TextField(
              decoration: InputDecoration(border: OutlineInputBorder()),
              onSubmitted: (value) {
                _tags.addLatest(value);
                widget.onSubmitted(value);
              },
            ),
          ),
          const ListTile(
            title: Text("Last Tags"),
          ),
          Wrap(
            children: () {
              List<Widget> list = [];

              for (var tag in _lastTags) {
                list.add(ActionChip(
                  label: Text(tag.tag),
                  onPressed: () {
                    widget.onSubmitted(tag.tag);
                  },
                ));
              }

              return list;
            }(),
          )
        ],
      ),
    );
  }
}
