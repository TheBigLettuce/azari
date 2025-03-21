// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:js_interop";

import "package:web/web.dart";

void init() {
  final req = window.indexedDB.open("main");

  void onSuccess(Event event) {
    WebDbConn().setDb(req.result! as IDBDatabase);
  }

  req.onsuccess = onSuccess.toJS;
}

class WebDbConn {
  factory WebDbConn() {
    if (_instance != null) {
      return _instance!;
    }

    return _instance = WebDbConn._();
  }

  WebDbConn._();

  static WebDbConn? _instance;

  final statusEvents = StreamController<void>.broadcast();
  IDBDatabase? db;

  void setDb(IDBDatabase newDb) {
    if (db != null) {
      return;
    }

    db = newDb;
    statusEvents.add(null);
  }
}
