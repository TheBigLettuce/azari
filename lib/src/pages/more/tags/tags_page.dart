// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:gallery/src/db/schemas/tags/tags.dart';
// import 'package:gallery/src/interfaces/cell/cell.dart';
// import 'package:gallery/src/interfaces/grid/selection_glue.dart';
// import 'package:gallery/src/widgets/grid/parts/segment_label.dart';
// import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';

// import '../../../interfaces/booru/booru_api.dart';
// import '../../../db/state_restoration.dart';
// import '../../../widgets/search_bar/autocomplete/autocomplete_widget.dart';
// import 'single_post.dart';
// import 'tags_widget.dart';

// class TagsPage extends StatefulWidget {
//   final TagManager tagManager;
//   final SelectionGlue<J> Function<J extends Cell>() generateGlue;
//   final BooruAPI booru;

//   const TagsPage({
//     super.key,
//     required this.tagManager,
//     required this.booru,
//     required this.generateGlue,
//   });

//   @override
//   State<TagsPage> createState() => _TagsPageState();
// }

// class _TagsPageState extends State<TagsPage> with TickerProviderStateMixin {
//   final excludedFocus = FocusNode();
//   final singlePostFocus = FocusNode();

//   final excludedTagsTextController = TextEditingController();
//   final state = SkeletonState();

//   late final StreamSubscription<void> _lastTagsWatcher;

//   List<Tag> _excludedTags = [];
//   List<Tag> _lastTags = [];

//   String searchHighlight = "";
//   String excludedHighlight = "";

//   int currentNavBarIndex = 0;

//   void _focusListener() {
//     if (!state.mainFocus.hasFocus) {
//       searchHighlight = "";
//       state.mainFocus.requestFocus();
//     }
//   }

//   @override
//   void initState() {
//     super.initState();

//     state.mainFocus.addListener(_focusListener);

//     excludedFocus.addListener(() {
//       if (!excludedFocus.hasFocus) {
//         excludedHighlight = "";
//         state.mainFocus.requestFocus();
//       }
//     });

//     singlePostFocus.addListener(() {
//       if (!singlePostFocus.hasFocus) {
//         state.mainFocus.requestFocus();
//       }
//     });

//     _lastTagsWatcher = widget.tagManager.latest.watch((_) {
//       // _lastTags = widget.tagManager.latest.get();
//       // _excludedTags = widget.tagManager.excluded.get();

//       setState(() {});
//     }, true);
//   }

//   @override
//   void dispose() {
//     state.dispose();
//     excludedTagsTextController.dispose();
//     _lastTagsWatcher.cancel();

//     // deleteAllController.dispose();
//     // deleteAllExcludedController.dispose();

//     excludedFocus.dispose();
//     singlePostFocus.dispose();

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SliverMainAxisGroup(slivers: [
//       TagsWidget(
//         tags: _lastTags,
//         searchBar: SinglePost(
//           focus: singlePostFocus,
//           tagManager: widget.tagManager,
//         ),
//         deleteTag: (t) {
//           widget.tagManager.latest.delete(t);
//         },
//         onPress: (t, safeMode) {
//           //   widget.tagManager.onTagPressed(
//           //   context,
//           //   t,
//           //   widget.booru.booru,
//           //   true,
//           //   overrideSafeMode: safeMode,
//           //   generateGlue: widget.generateGlue,
//           // )
//         },
//       ),
//       const SliverToBoxAdapter(
//         child: SegmentLabel("Excluded",
//             hidePinnedIcon: true, onPress: null, sticky: false),
//       ),
//       TagsWidget(
//           redBackground: true,
//           tags: _excludedTags,
//           searchBar: AutocompleteWidget(
//             excludedTagsTextController,
//             (s) {
//               excludedHighlight = s;
//             },
//             swapSearchIcon: false,
//             (s) => widget.tagManager.excluded.add(Tag.string(tag: s)),
//             () => state.mainFocus.requestFocus(),
//             widget.booru.completeTag,
//             excludedFocus,
//             submitOnPress: true,
//             roundBorders: true,
//             plainSearchBar: true,
//             showSearch: true,
//           ),
//           deleteTag: (t) {
//             widget.tagManager.excluded.delete(t);
//           },
//           onPress: null)
//     ]);
//   }
// }
