// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

// import 'dart:async';

// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:gallery/src/db/initalize_db.dart';
// import 'package:gallery/src/db/schemas/booru/post.dart';
// import 'package:gallery/src/db/schemas/grid_settings/booru.dart';
// import 'package:gallery/src/db/schemas/grid_state/grid_booru_paging.dart';
// import 'package:gallery/src/db/schemas/settings/hidden_booru_post.dart';
// import 'package:gallery/src/db/schemas/settings/settings.dart';
// import 'package:gallery/src/db/schemas/statistics/statistics_general.dart';
// import 'package:gallery/src/db/state_restoration.dart';
// import 'package:gallery/src/interfaces/booru/booru.dart';
// import 'package:gallery/src/interfaces/booru/booru_api.dart';
// import 'package:gallery/src/pages/booru/booru_page.dart';
// import 'package:gallery/src/pages/home.dart';
// import 'package:gallery/src/widgets/grid/grid_frame.dart';
// import 'package:isar/isar.dart';

// class MainBooruPage implements BooruPageType {
//   const MainBooruPage({
//     required this.mainGrid,
//     required this.pagingRegistry,
//     required this.procPop,
//   });

//   final Isar mainGrid;

//   final void Function(bool) procPop;
//   final PagingStateRegistry pagingRegistry;

//   @override
//   Post getCell(int i) {
//     return mainGrid.posts.getSync(i + 1)!;
//   }

//   @override
//   Future<int> clearAndRefresh(_MainGridPagingState state) async {
//     mainGrid.writeTxnSync(() => mainGrid.posts.clearSync());

//     StatisticsGeneral.addRefreshes();

//     state.restore.updateTime();

//     final list = await state.api.page(0, "", state.tagManager.excluded);
//     state.currentSkipped = list.$2;

//     mainGrid.writeTxnSync(() {
//       mainGrid.posts.clearSync();
//       return mainGrid.posts.putAllByFileUrlSync(
//         list.$1
//             .where((element) =>
//                 !HiddenBooruPost.isHidden(element.id, state.api.booru))
//             .toList(),
//       );
//     });

//     state.reachedEnd = false;

//     return mainGrid.posts.count();
//   }

//   @override
//   void dispose(BooruPagingEntry p) {
//     final pp = p as _MainGridPagingState;
//     pp.notifiers?.dispose();
//     pp.notifiers = null;
//   }

//   @override
//   BooruPagingEntry init() {
//     final page = pagingRegistry.getOrRegister(
//       mainGrid.name,
//       _MainGridPagingState.prototype,
//     ) as _MainGridPagingState;

//     final settings = Settings.fromDb();

//     page.notifiers?.dispose();
//     page.notifiers = _MainGridNotifiers()..init();

//     // page.
//     // gridSettingsHook();

//     if (page.api.wouldBecomeStale &&
//         settings.autoRefresh &&
//         settings.autoRefreshMicroseconds != 0 &&
//         page.restore.copy.time.isBefore(DateTime.now().subtract(
//             Duration(microseconds: settings.autoRefreshMicroseconds)))) {
//       mainGrid.writeTxnSync(() => mainGrid.posts.clearSync());
//       page.restore.updateTime();
//     }

//     // if (pagingState.restoreSecondaryGrid != null) {
//     //   WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
//     //     final e = Dbs.g.main.gridStateBoorus
//     //         .getByNameSync(pagingState.restoreSecondaryGrid!)!;

//     //     Dbs.g.main.writeTxnSync(() => Dbs.g.main.gridStateBoorus
//     //         .putByNameSync(e.copy(time: DateTime.now())));

//     //     // widget.saveSelectedPage(widget.restoreSelectedPage);

//     //     Navigator.push(context, MaterialPageRoute(
//     //       builder: (context) {
//     //         return RandomBooruGrid(
//     //           booru: e.booru,
//     //           tags: e.tags,
//     //           generateGlue: widget.generateGlue,
//     //         );
//     //       },
//     //     ));
//     //   });
//     // }

//     return page;
//   }

//   @override
//   Future<int> loadNext(_MainGridPagingState state) async {
//     if (state.reachedEnd) {
//       return mainGrid.posts.countSync();
//     }

//     final lastPost = mainGrid.posts.getSync(mainGrid.posts.countSync());
//     if (lastPost == null) {
//       return mainGrid.posts.countSync();
//     }

//     final list = await state.api.fromPost(
//       state.currentSkipped != null && state.currentSkipped! < lastPost.id
//           ? state.currentSkipped!
//           : lastPost.id,
//       "",
//       state.tagManager.excluded,
//     );

//     if (list.$1.isEmpty && state.currentSkipped == null) {
//       state.reachedEnd = true;
//     } else {
//       state.currentSkipped = list.$2;
//       final oldCount = mainGrid.posts.countSync();
//       mainGrid.writeTxnSync(
//         () => mainGrid.posts.putAllByFileUrlSync(
//           list.$1
//               .where((element) =>
//                   !HiddenBooruPost.isHidden(element.id, state.api.booru))
//               .toList(),
//         ),
//       );

//       if (mainGrid.posts.countSync() - oldCount < 3) {
//         return await loadNext(state);
//       }
//     }

//     return mainGrid.posts.count();
//   }
// }

// class _MainGridPagingState implements BooruPagingEntry {
//   _MainGridPagingState(this.restore, int initalCellCount, this.booru)
//       : tagManager = TagManager.fromEnum(booru),
//         client = BooruAPI.defaultClientForBooru(booru) {
//     refreshingStatus = GridRefreshingStatus(initalCellCount, () => reachedEnd);
//   }

//   _MainGridNotifiers? notifiers;

//   final Booru booru;

//   bool reachedEnd = false;

//   @override
//   late final BooruAPI api = BooruAPI.fromEnum(booru, client, this);
//   final TagManager tagManager;
//   final Dio client;

//   int? currentSkipped;

//   @override
//   late final GridRefreshingStatus<Post> refreshingStatus;
//   final StateRestoration restore;

//   String? restoreSecondaryGrid;

//   @override
//   double get offset => restore.current.scrollOffset;

//   @override
//   int get page => restore.mainGrid.gridBooruPagings.getSync(0)!.page;

//   @override
//   void setOffset(double o) {
//     restore.updateScrollPosition(o);
//   }

//   @override
//   void setPage(int p) {
//     restore.mainGrid.writeTxnSync(
//         () => restore.mainGrid.gridBooruPagings.putSync(GridBooruPaging(p)));
//   }

//   @override
//   void save(int page) => setPage(page);

//   @override
//   int get current => page;

//   @override
//   void dispose() {
//     client.close();
//     notifiers?.dispose();
//     refreshingStatus.dispose();
//   }

//   static PagingEntry prototype() {
//     final settings = Settings.fromDb();
//     final mainGrid = DbsOpen.primaryGrid(settings.selectedBooru);

//     return _MainGridPagingState(
//       StateRestoration(
//         mainGrid,
//         settings.selectedBooru.string,
//         settings.safeMode,
//       ),
//       mainGrid.posts.countSync(),
//       settings.selectedBooru,
//     );
//   }
// }

// class _MainGridNotifiers {
//   late final StreamSubscription timeUpdater;
//   late final AppLifecycleListener lifecycleListener;

//   bool inForeground = true;

//   void init() {
//     lifecycleListener = AppLifecycleListener(onHide: () {
//       inForeground = false;
//     }, onShow: () {
//       inForeground = true;
//     });

//     timeUpdater = Stream.periodic(const Duration(seconds: 5)).listen((event) {
//       if (inForeground) {
//         StatisticsGeneral.addTimeSpent(
//           const Duration(seconds: 5).inMilliseconds,
//         );
//       }
//     });
//   }

//   void dispose() {
//     timeUpdater.cancel();
//     lifecycleListener.dispose();
//   }
// }
