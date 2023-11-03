import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/note.dart';
import 'package:gallery/src/db/schemas/note_gallery.dart';
import 'package:gallery/src/db/schemas/system_gallery_directory_file.dart';
import 'package:gallery/src/pages/gallery/directories.dart';
import 'package:gallery/src/pages/image_view.dart';
import 'package:gallery/src/widgets/copy_move_preview.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/grid/wrap_grid_page.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton_state.dart';
import 'package:gallery/src/widgets/skeletons/make_skeleton_settings.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';
import 'package:octo_image/octo_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:palette_generator/palette_generator.dart';

import '../db/schemas/system_gallery_directory.dart';

class NotesPage extends StatefulWidget {
  final CallbackDescriptionNested? callback;

  const NotesPage({super.key, this.callback});

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
            addIcons: widget.callback != null
                ? (n) => [
                      GridAction(
                        Icons.check,
                        (selected) {
                          final note = selected.first;

                          widget.callback!(SystemGalleryDirectoryFile(
                              id: note.id,
                              bucketId: "",
                              name: "",
                              isVideo: note.isVideo,
                              isGif: note.isGif,
                              size: 0,
                              height: note.height,
                              notesFlat: "",
                              width: note.width,
                              isOriginal: false,
                              lastModified: 0,
                              originalUri: note.originalUri));
                        },
                        false,
                      )
                    ]
                : (n) => [
                      GridAction(
                        Icons.forward,
                        (selected) {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                            return WrappedGridPage<SystemGalleryDirectory>(
                                scaffoldKey: GlobalKey(),
                                f: (glue) => GalleryDirectories(
                                      glue: glue,
                                      procPop: (p) {},
                                      nestedCallback: CallbackDescriptionNested(
                                          "Choose file", (chosen) async {
                                        final s = selected.first;
                                        final data = chosen.getCellData(false,
                                            context: context);
                                        final colors = await PaletteGenerator
                                            .fromImageProvider(data.thumb!);
                                        // final n = i.load(s)!;
                                        NoteGallery.add(chosen.id,
                                            text: s.text,
                                            height: chosen.height,
                                            width: chosen.width,
                                            backgroundColor:
                                                colors.dominantColor?.color,
                                            textColor: colors
                                                .dominantColor?.bodyTextColor,
                                            isVideo: chosen.isVideo,
                                            isGif: chosen.isGif,
                                            originalUri: chosen.originalUri);
                                        NoteGallery.removeAll(s.id);
                                        imageViewKey.currentState?.loadNotes();
                                      }, returnBack: true),
                                    ));
                          }));
                        },
                        false,
                      )
                    ],
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
            crossAxisCount: 3, childAspectRatio: 0.7, crossAxisSpacing: 2),
        itemBuilder: (context, index) {
          final note = notes[index];

          return InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              onTap: () => launch(index),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: BoxDecoration(
                      color: note.backgroundColor != null
                          ? Color(note.backgroundColor!).harmonizeWith(
                              Theme.of(context).colorScheme.primary)
                          : Theme.of(context).colorScheme.secondaryContainer,
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
                                    decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10))),
                                    clipBehavior: Clip.antiAlias,
                                    child: OctoImage(
                                        fit: BoxFit.cover,
                                        filterQuality: FilterQuality.high,
                                        progressIndicatorBuilder: (context, _) {
                                          return Container(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondaryContainer)
                                              .animate(
                                                  onComplete: (controller) {
                                            controller.repeat();
                                          }).shimmer(
                                                  delay: 2.seconds,
                                                  duration: 500.ms);
                                        },
                                        image: provider(note)),
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
                                                    style: TextStyle(
                                                        wordSpacing: 2.6,
                                                        color: note.textColor !=
                                                                null
                                                            ? Color(note
                                                                    .textColor!)
                                                                .harmonizeWith(Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primary)
                                                            : null,
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
        .takeWhile((element) => element.text
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
                )))
        .take(15);
  }

  Iterable<Widget> _notesGallery(
      BuildContext context,
      SearchController controller,
      Widget Function(void Function() onPress, ImageProvider provider) f) {
    return notesGallery
        .takeWhile((element) => element.text
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
            }, e1.getCellData(false, context: context).thumb!))
        .take(15);
  }

  Iterable<Widget> _filter(BuildContext context, SearchController controller,
      Widget Function(void Function() onPress, ImageProvider provider) f) {
    return widget.callback != null
        ? _notesGallery(context, controller, f)
        : tabController.index == 0
            ? _notesBooru(context, controller, f)
            : _notesGallery(context, controller, f);
  }

  Tab _makeTab(String title, int length) => Tab(
          child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Badge.count(
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              textColor: Theme.of(context).colorScheme.onSurfaceVariant,
              count: length,
            ),
          )
        ],
      ));

  @override
  Widget build(BuildContext context) {
    return makeSkeletonSettings(
        context,
        "Notes",
        state,
        widget.callback != null
            ? _make(context, notesGallery,
                (e) => e.getCellData(false, context: context).thumb!, (i) {
                _launchGallery(i, NoteGallery.interfaceSelf(setState));
              })
            : TabBarView(controller: tabController, children: [
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
                        (n) => n.getCellData(false, context: context).thumb!,
                        (i) {
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
              viewBuilder: (widgets) {
                final w = widgets.toList();

                if (w.isEmpty) {
                  return const EmptyWidget();
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 12),
                      child: Text(
                        "Showing ${w.length} results", // TODO: change
                        style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    Expanded(child: ListView(children: w))
                  ],
                );
              },
              viewHintText: "Search", // TOOD: change
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
                            clipBehavior: Clip.antiAlias,
                            decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                            ),
                            child: OctoImage(
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                image: provider),
                          ),
                        ).animate().fadeIn());
              },
            )
          ],
          title: Text("Notes"),
          bottom: widget.callback != null
              ? CopyMovePreview.hintWidget(
                  context, widget.callback!.description)
              : TabBar(controller: tabController, tabs: [
                  _makeTab(AppLocalizations.of(context)!.booruLabel,
                      notesBooru.length),
                  _makeTab(AppLocalizations.of(context)!.galleryLabel,
                      notesGallery.length)
                ]),
        ));
  }
}



// class NotesPage2 extends StatefulWidget {
//   final CallbackDescriptionNested? callback;


//   const NotesPage2({super.key, this.callback});

//   @override
//   State<NotesPage2> createState() => _NotesPage2State();
// }

// class _NotesPage2State extends State<NotesPage2> {
//   final state = GridSkeletonState();

//   @override
//   Widget build(BuildContext context) {
//     return WrappedGridPage(scaffoldKey: scaffoldKey, f: f)
//   }
// }
