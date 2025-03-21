// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

// import "package:azari/src/db/services/services.dart";
// import "package:azari/src/pages/search/booru/booru_search_page.dart";
// import "package:azari/src/pages/search/gallery/gallery_search_page.dart";
// import "package:azari/src/typedefs.dart";
// import "package:azari/src/widgets/gesture_dead_zones.dart";
// import "package:azari/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
// import "package:azari/src/widgets/grid_frame/configuration/grid_column.dart";
// import "package:azari/src/widgets/selection_actions.dart";
// import "package:flutter/material.dart";

// class SearchPage extends StatefulWidget {
//   const SearchPage({
//     super.key,
//     this.procPop,
//   });

//   final void Function(bool)? procPop;

//   @override
//   State<SearchPage> createState() => _SearchPageState();
// }

// class _SearchPageState extends State<SearchPage>
//     with SingleTickerProviderStateMixin {
//   late final TabController tabController;

//   @override
//   void initState() {
//     super.initState();

//     tabController = TabController(length: 2, vsync: this);
//   }

//   @override
//   void dispose() {
//     tabController.dispose();

//     super.dispose();
//   }

//   final gridSettings = CancellableWatchableGridSettingsData.noPersist(
//     hideName: true,
//     aspectRatio: GridAspectRatio.one,
//     columns: GridColumn.five,
//     layoutType: GridLayoutType.grid,
//   );

//   @override
//   Widget build(BuildContext context) {
//     final l10n = context.l10n();
//     final theme = Theme.of(context);

//     // final db = DbConn.of(context);

//     final selectedTextStyle = theme.textTheme.headlineLarge
//         ?.copyWith(color: theme.colorScheme.primary);
//     final unselectedTextStyle = theme.textTheme.headlineMedium;

//     return GestureDeadZones(
//       right: true,
//       left: true,
//       child: CustomScrollView(
//         slivers: [
//           SliverPadding(
//             padding: const EdgeInsets.only(top: 42),
//             sliver: SliverToBoxAdapter(
//               child: TabBar(
//                 padding: EdgeInsets.only(
//                   top: MediaQuery.paddingOf(context).top,
//                   left: 12,
//                   right: 12,
//                 ),
//                 splashBorderRadius: const BorderRadius.all(Radius.circular(10)),
//                 controller: tabController,
//                 isScrollable: true,
//                 tabAlignment: TabAlignment.start,
//                 indicator: const BoxDecoration(),
//                 labelStyle: selectedTextStyle,
//                 labelPadding: const EdgeInsets.symmetric(horizontal: 12),
//                 unselectedLabelStyle: unselectedTextStyle,
//                 dividerHeight: 0,
//                 tabs: [
//                   Tab(text: l10n.booruLabel),
//                   Tab(text: l10n.galleryLabel),
//                 ],
//               ),
//             ),
//           ),
//           ListenableBuilder(
//             listenable: tabController,
//             builder: (context, child) => tabController.index == 0
//                 ? BooruSearchPage(
//                     l10n: l10n,
//                     procPop: widget.procPop, tagManager: null, gridBookmarks: null, settingsService: null,
//                   )
//                 : GallerySearchPage(
//                     l10n: l10n,
//                     procPop: widget.procPop, directoryMetadata: null, blacklistedDirectories: null, directoryTags: null, favoritePosts: null, localTags: null,
//                   ),
//           ),
//           Builder(
//             builder: (context) => SliverPadding(
//               padding: EdgeInsets.only(
//                 bottom: MediaQuery.viewPaddingOf(context).bottom +
//                     8 +
//                     SelectionActions.of(context).size.base,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
