import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/note.dart';
import 'package:gallery/src/db/schemas/note_gallery.dart';
import 'package:gallery/src/pages/image_view.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/skeletons/make_skeleton_settings.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';

import '../interfaces/cell.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage>
    with SingleTickerProviderStateMixin {
  final state = SkeletonState();
  late final tabController = TabController(length: 2, vsync: this);

  late final StreamSubscription<void> notesBooruWatcher;
  late final StreamSubscription<void> notesGalleryWatcher;

  final imageViewKey = GlobalKey<ImageViewState>();
  final searchController = SearchController();

  var notesBooru = NoteBooru.load();
  var notesGallery = NoteGallery.load();

  @override
  void initState() {
    super.initState();

    tabController.addListener(() {
      searchController.clear();
    });

    notesBooruWatcher =
        Dbs.g.blacklisted.noteBoorus.watchLazy().listen((event) {
      notesBooru = NoteBooru.load();
      imageViewKey.currentState?.update(context, notesBooru.length);
      setState(() {});
    });

    notesGalleryWatcher = Dbs.g.main.noteGallerys.watchLazy().listen((event) {
      notesGallery = NoteGallery.load();
      imageViewKey.currentState?.update(context, notesGallery.length);
      setState(() {});
    });
  }

  @override
  void dispose() {
    state.dispose();

    tabController.dispose();
    searchController.dispose();

    notesGalleryWatcher.cancel();
    notesBooruWatcher.cancel();

    super.dispose();
  }

  void _launchGallery(int index, NoteInterface<NoteGallery> i) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        final overlayColor =
            Theme.of(context).colorScheme.background.withOpacity(0.5);

        return ImageView<NoteGallery>(
            key: imageViewKey,
            updateTagScrollPos: (_, __) {},
            cellCount: notesGallery.length,
            scrollUntill: (_) {},
            startingCell: index,
            noteInterface: i,
            onExit: () {},
            getCell: (idx) => notesGallery[idx],
            onNearEnd: null,
            focusMain: () => state.mainFocus,
            systemOverlayRestoreColor: overlayColor);
      },
    ));
  }

  void _launchBooru(int index, NoteInterface<NoteBooru> i) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        final overlayColor =
            Theme.of(context).colorScheme.background.withOpacity(0.5);

        return ImageView<NoteBooru>(
            key: imageViewKey,
            updateTagScrollPos: (_, __) {},
            cellCount: notesBooru.length,
            scrollUntill: (_) {},
            startingCell: index,
            noteInterface: i,
            onExit: () {},
            getCell: (idx) => notesBooru[idx],
            onNearEnd: null,
            focusMain: () => state.mainFocus,
            systemOverlayRestoreColor: overlayColor);
      },
    ));
  }

  Widget _make<T extends NoteBase>(BuildContext context, List<T> notes,
      ImageProvider Function(T) provider, void Function(int i) launch) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, childAspectRatio: 0.7, crossAxisSpacing: 8),
        itemBuilder: (context, index) {
          final note = notes[index];
          return InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              onTap: () => launch(index),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10))),
                  child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              Align(
                                  alignment: Alignment.topLeft,
                                  child: Container(
                                    width: constraints.minHeight * 0.2,
                                    height: constraints.maxHeight * 0.2,
                                    decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(10)),
                                        image: DecorationImage(
                                            fit: BoxFit.cover,
                                            filterQuality: FilterQuality.high,
                                            image: provider(note))),
                                  )),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                    clipBehavior: Clip.antiAlias,
                                    decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(8))),
                                    width: (constraints.maxHeight * 0.8),
                                    height: (constraints.maxHeight * 0.78),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: note.text
                                            .map((e) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 8.3),
                                                  child: Text(
                                                    e,
                                                    softWrap: true,
                                                    style: const TextStyle(
                                                        wordSpacing: 2.6,
                                                        letterSpacing: 1.3,
                                                        fontFamily:
                                                            "ZenKurenaido"),
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
    );
  }

  Iterable<Widget> _notesBooru(
      BuildContext context,
      SearchController controller,
      Widget Function(void Function() onPress, ImageProvider provider) f) {
    return notesBooru
        .where((element) => element.text
            .firstWhere((e) => e.toLowerCase().contains(controller.text),
                orElse: () => "")
            .isNotEmpty)
        .map((e1) => f(() {
              final i = notesBooru.indexWhere((e2) {
                return e1.booru == e2.booru && e1.postId == e2.postId;
              });

              if (i == -1) {
                return;
              }

              _launchBooru(i, NoteBooru.interfaceSelf(setState));
            },
                CachedNetworkImageProvider(
                  e1.previewUrl,
                )));
  }

  Iterable<Widget> _notesGallery(
      BuildContext context,
      SearchController controller,
      Widget Function(void Function() onPress, ImageProvider provider) f) {
    return notesGallery
        .where((element) => element.text
            .firstWhere((e) => e.toLowerCase().contains(controller.text),
                orElse: () => "")
            .isNotEmpty)
        .map((e1) => f(() {
              final i = notesGallery.indexWhere((e2) {
                return e1.id == e2.id;
              });

              if (i == -1) {
                return;
              }

              _launchGallery(i, NoteGallery.interfaceSelf(setState));
            }, e1.getCellData(false, context: context).thumb!));
  }

  Iterable<Widget> _filter(BuildContext context, SearchController controller,
      Widget Function(void Function() onPress, ImageProvider provider) f) {
    return tabController.index == 0
        ? _notesBooru(context, controller, f)
        : _notesGallery(context, controller, f);
  }

  @override
  Widget build(BuildContext context) {
    return makeSkeletonSettings(
        context,
        "Notes",
        state,
        TabBarView(controller: tabController, children: [
          notesBooru.isEmpty
              ? const Center(child: EmptyWidget())
              : _make(
                  context,
                  notesBooru,
                  (n) => CachedNetworkImageProvider(
                        n.previewUrl,
                      ), (i) {
                  _launchBooru(i, NoteBooru.interfaceSelf(setState));
                }),
          notesGallery.isEmpty
              ? const Center(child: EmptyWidget())
              : _make(context, notesGallery,
                  (n) => n.getCellData(false, context: context).thumb!, (i) {
                  _launchGallery(i, NoteGallery.interfaceSelf(setState));
                })
        ]),
        appBar: AppBar(
          actions: [
            SearchAnchor(
              searchController: searchController,
              builder: (context, controller) {
                return IconButton(
                    onPressed: () {
                      controller.openView();
                    },
                    icon: const Icon(Icons.search_rounded));
              },
              suggestionsBuilder: (context, controller) {
                if (controller.text.isEmpty) {
                  return [];
                }

                return _filter(
                    context,
                    controller,
                    (onPressed, provider) => ListTile(
                          onTap: onPressed,
                          title: Container(
                            height: 100,
                            decoration: BoxDecoration(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(10)),
                                image: DecorationImage(
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.high,
                                    image: provider)),
                          ),
                        ));
              },
            )
          ],
          title: Text("Notes"),
          bottom: TabBar(controller: tabController, tabs: [
            Tab(
              text: "Booru",
            ),
            Tab(
              text: "Gallery",
            )
          ]),
        ));
  }
}
