import 'package:flutter/material.dart';

class SearchBooru extends StatefulWidget {
  final void Function(String) onSubmitted;
  const SearchBooru({super.key, required this.onSubmitted});

  @override
  State<SearchBooru> createState() => _SearchBooruState();
}

class _SearchBooruState extends State<SearchBooru> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search"),
      ),
      body: TextField(
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}
