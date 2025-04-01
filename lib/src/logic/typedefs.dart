// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/widgets/grid_cell/contentable.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view_notifiers.dart";
import "package:flutter/material.dart";

extension OpenLicensePageExt on LicensePage {
  void open(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) {
          return this;
        },
      ),
    );
  }
}

extension AppLocalizationsContextExt on BuildContext {
  AppLocalizations l10n() => AppLocalizations.of(this)!;
}

typedef ContextCallback = void Function(BuildContext context);

typedef GetCellCallback<T> = T Function(int idx);

typedef OnBooruTagPressedFunc = void Function(
  BuildContext context,
  Booru booru,
  String tag,
  SafeMode? overrideSafeMode,
);

typedef OpenSearchCallback = void Function(
  BuildContext context,
  String tag, [
  SafeMode? safeMode,
]);

typedef BuilderCallback = Widget Function(BuildContext context);

/// Progress callback which receives [c] values between 0.0 to 1.0.
typedef PercentageCallback = void Function(double c);

typedef DestinationCallback = void Function(
  BuildContext context,
  CurrentRoute route,
);

typedef CompleteBooruTagFunc = Future<List<BooruTag>> Function(String str);

typedef StringCallback = void Function(String str);

typedef WatchTagsCallback = StreamSubscription<List<ImageTag>> Function(
  ContentWidgets content,
  void Function(List<ImageTag> l) f,
);
