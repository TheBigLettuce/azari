// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:flutter/widgets.dart";

mixin BooruSearchMixin<W extends StatefulWidget> on State<W> {
  AppLocalizations? l10n;

  late final BooruAPI api;

  final searchController = TextEditingController();
  final focusNode = FocusNode();

  final filteringEvents = StreamController<String>.broadcast();

  @override
  void initState() {
    super.initState();

    final settings = const SettingsService().current;

    api = BooruAPI.fromEnum(settings.selectedBooru);
  }

  @override
  void dispose() {
    api.destroy();
    filteringEvents.close();

    focusNode.dispose();
    searchController.dispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newl10n = context.l10n();
    if (newl10n != l10n) {
      l10n = newl10n;
    }
  }

  void pinnedTagPressed(String str_) {
    searchController.text = "$str_ ";
    filteringEvents.add(searchController.text.trim());
  }
}

class SearchPagePopScope extends StatefulWidget {
  const SearchPagePopScope({
    super.key,
    required this.searchController,
    required this.sink,
    required this.searchFocus,
    required this.procPop,
    required this.child,
  });

  final TextEditingController searchController;
  final StreamSink<String> sink;
  final FocusNode searchFocus;

  final void Function(bool)? procPop;

  final Widget child;

  @override
  State<SearchPagePopScope> createState() => _SearchPagePopScopeState();
}

class _SearchPagePopScopeState extends State<SearchPagePopScope> {
  @override
  void initState() {
    super.initState();

    widget.searchController.addListener(_listener);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_listener);

    super.dispose();
  }

  void _listener() {
    setState(() {});
  }

  void onPopInvoked(bool didPop, Object? extra) {
    if (widget.searchController.text.isNotEmpty) {
      widget.searchController.clear();
      widget.searchFocus.previousFocus();
      widget.sink.add("");
      return;
    }

    widget.procPop?.call(didPop);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.searchController.text.isEmpty,
      onPopInvokedWithResult: onPopInvoked,
      child: widget.child,
    );
  }
}
