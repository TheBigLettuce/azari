// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "main.dart";

/// Entrypoint for the second Android's Activity.
/// Picks a file and returns to the app requested.
@pragma("vm:entry-point")
Future<void> mainPickfile() async {
  await wrapZone(() async {
    await initMain(AppInstanceType.pickFile);

    final accentColor = const AppApi().accentColor;

    // TODO: reimplement this as Android dialog

    runApp(
      injectWidgetEvents(
        PinnedTagsHolder(
          pinnedTags: TagManagerService.safe()?.pinned,
          child: _GalleryPageHolder(
            child: MaterialApp(
              title: "Azari",
              themeAnimationCurve: Easing.standard,
              themeAnimationDuration: const Duration(milliseconds: 300),
              darkTheme: buildTheme(Brightness.dark, accentColor),
              theme: buildTheme(Brightness.light, accentColor),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: ScaffoldSelectionBarInherited(
                child: Builder(
                  builder: (context) => DirectoriesPage(
                    selectionController: SelectionActions.controllerOf(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  });
}

class _GalleryPageHolder extends StatefulWidget {
  const _GalleryPageHolder({
    // super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<_GalleryPageHolder> createState() => __GalleryPageHolderState();
}

class __GalleryPageHolderState extends State<_GalleryPageHolder>
    with CurrentGalleryPageMixin {
  late final SelectionActions _actions;

  @override
  void initState() {
    super.initState();

    _actions = SelectionActions();
  }

  @override
  void dispose() {
    _actions.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GallerySubPage.wrap(
      galleryPage,
      _actions.inject(widget.child),
    );
  }
}
