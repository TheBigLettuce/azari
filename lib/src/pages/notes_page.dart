import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/note.dart';
import 'package:gallery/src/pages/image_view.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/skeletons/make_skeleton_settings.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage>
    with SingleTickerProviderStateMixin {
  final state = SkeletonState();
  late final tabController = TabController(length: 2, vsync: this);
  late final StreamSubscription<void> notesWatcher;
  final imageViewKey = GlobalKey<ImageViewState>();
  var notes = NoteBooru.load();

  @override
  void initState() {
    super.initState();
    notesWatcher = Dbs.g.blacklisted.noteBoorus.watchLazy().listen((event) {
      notes = NoteBooru.load();
      imageViewKey.currentState?.update(context, notes.length);
      setState(() {});
    });
  }

  @override
  void dispose() {
    state.dispose();

    tabController.dispose();

    notesWatcher.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return makeSkeletonSettings(
        context,
        "Notes",
        state,
        TabBarView(controller: tabController, children: [
          notes.isEmpty
              ? const Center(child: EmptyWidget())
              : Padding(
                  padding: const EdgeInsets.all(8),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 8),
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return InkWell(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) {
                                final overlayColor = Theme.of(context)
                                    .colorScheme
                                    .background
                                    .withOpacity(0.5);

                                return ImageView<NoteBooru>(
                                    key: imageViewKey,
                                    updateTagScrollPos: (_, __) {},
                                    cellCount: notes.length,
                                    scrollUntill: (_) {},
                                    startingCell: index,
                                    noteInterface:
                                        NoteBooru.interfaceSelf(setState),
                                    onExit: () {},
                                    getCell: (idx) => notes[idx],
                                    onNearEnd: null,
                                    focusMain: () => state.mainFocus,
                                    systemOverlayRestoreColor: overlayColor);
                              },
                            ));
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer,
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(10))),
                              child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Stack(
                                        children: [
                                          Align(
                                              alignment: Alignment.topLeft,
                                              child: Container(
                                                width:
                                                    constraints.minHeight * 0.2,
                                                height:
                                                    constraints.maxHeight * 0.2,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        const BorderRadius.all(
                                                            Radius.circular(
                                                                10)),
                                                    image: DecorationImage(
                                                        fit: BoxFit.cover,
                                                        filterQuality:
                                                            FilterQuality.high,
                                                        image:
                                                            CachedNetworkImageProvider(
                                                          note.previewUrl,
                                                        ))),
                                              )),
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: Container(
                                                clipBehavior: Clip.antiAlias,
                                                decoration: const BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                8))),
                                                width: (constraints.maxHeight *
                                                    0.8),
                                                height: (constraints.maxHeight *
                                                    0.78),
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: note.text
                                                        .map((e) => Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      bottom:
                                                                          8.3),
                                                              child: Text(
                                                                e,
                                                                softWrap: true,
                                                                style: const TextStyle(
                                                                    wordSpacing:
                                                                        2.6,
                                                                    letterSpacing:
                                                                        1.3),
                                                              ),
                                                            ))
                                                        .toList(),
                                                  ),
                                                )),
                                          )
                                        ],
                                      );
                                    },
                                  )),
                            ),
                          ));
                    },
                    itemCount: notes.length,
                  ),
                ),
          Placeholder()
        ]),
        appBar: AppBar(
          title: Text("Notes"),
          bottom: TabBar(controller: tabController, tabs: [
            Tab(
              text: "Booru",
            ),
            Tab(
              text: "B",
            )
          ]),
        ));
  }
}
