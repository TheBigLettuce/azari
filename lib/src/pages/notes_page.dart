import 'package:flutter/material.dart';
import 'package:gallery/src/widgets/skeletons/make_skeleton_settings.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final state = SkeletonState();

  @override
  void dispose() {
    state.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return makeSkeletonSettings(
        context,
        "Notes",
        state,
        SliverList.list(
          children: [],
        ));
  }
}
