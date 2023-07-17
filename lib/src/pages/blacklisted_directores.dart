// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/gallery/android_api/android_api_directories.dart';
import 'package:gallery/src/schemas/blacklisted_directory.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BlacklistedDirectories extends StatefulWidget {
  const BlacklistedDirectories({super.key});

  @override
  State<BlacklistedDirectories> createState() => _BlacklistedDirectoriesState();
}

class _BlacklistedDirectoriesState extends State<BlacklistedDirectories> {
  final state = SkeletonState.settings();
  List<BlacklistedDirectory> elems =
      GalleryImpl.instance().db.blacklistedDirectorys.where().findAllSync();

  @override
  Widget build(BuildContext context) {
    return makeSkeletonInnerSettings(
        context,
        AppLocalizations.of(context)!.blacklistedDirectoriesPageName,
        state,
        elems
            .map((e) => ListTile(
                  title: Text(e.name),
                  trailing: IconButton(
                      onPressed: () {
                        GalleryImpl.instance().db.writeTxnSync(() {
                          GalleryImpl.instance()
                              .db
                              .blacklistedDirectorys
                              .deleteSync(e.isarId);
                        });
                        elems = GalleryImpl.instance()
                            .db
                            .blacklistedDirectorys
                            .where()
                            .findAllSync();
                        setState(() {});
                        GalleryImpl.instance().notify(null);
                      },
                      icon: const Icon(Icons.close)),
                  subtitle: Text(e.bucketId),
                ))
            .toList(),
        appBarActions: [
          IconButton(
              onPressed: () {
                setState(() {
                  elems.clear();
                });
                GalleryImpl.instance().db.writeTxnSync(() =>
                    GalleryImpl.instance()
                        .db
                        .blacklistedDirectorys
                        .clearSync());
                GalleryImpl.instance().notify(null);
              },
              icon: const Icon(Icons.delete))
        ]);
  }
}
