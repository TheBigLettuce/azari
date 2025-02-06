// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:isolate";

import "package:azari/src/db/services/impl/isar/impl.dart";
import "package:azari/src/db/services/impl/isar/schemas/booru/favorite_post.dart";
import "package:azari/src/db/services/isolates/isolate_io.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:flutter/foundation.dart";
import "package:isar/isar.dart";

class FavoritePostsIsolate
    implements IsolateIO<_FavoritePostData, FavoritePostResult> {
  FavoritePostsIsolate(this._directory);

  final _loop = _FavoritePostsLoop();
  final String _directory;

  @override
  Stream<FavoritePostResult> get events => _loop.events;

  Future<void> init() async {
    await _loop.init(_directory);
  }

  @override
  void send(_FavoritePostData i) {
    _loop.sendMessage(i);
  }

  void add(List<FavoritePost> posts) {
    send(AddPosts(posts));
  }

  void remove(List<(int, Booru)> posts) {
    send(RemovePosts(posts));
  }

  void clear() {
    send(const ClearPosts());
  }

  void dispose() {
    _loop.destroy();
  }
}

sealed class _FavoritePostData {
  const _FavoritePostData();
}

class AddPosts implements _FavoritePostData {
  const AddPosts(this.posts);

  final List<FavoritePost> posts;
}

class RemovePosts implements _FavoritePostData {
  const RemovePosts(this.posts);

  final List<(int id, Booru booru)> posts;
}

class ClearPosts implements _FavoritePostData {
  const ClearPosts();
}

@immutable
sealed class FavoritePostResult {
  const FavoritePostResult();
}

@immutable
class PostsAddedResult implements FavoritePostResult {
  const PostsAddedResult(this.posts);

  final List<FavoritePost> posts;
}

class PostsRemovedResult implements FavoritePostResult {
  const PostsRemovedResult(this.posts);

  final List<(int id, Booru booru)> posts;
}

class PostsClearResult implements FavoritePostResult {
  const PostsClearResult();
}

class _FavoritePostsLoop extends IsolateLoop<String> {
  _FavoritePostsLoop() : super("Favorite Posts Isolate");

  final _resultEvents = StreamController<FavoritePostResult>.broadcast();

  Stream<FavoritePostResult> get events => _resultEvents.stream;

  @override
  Future<void> Function(({String data, SendPort port}) data) makeMain() => main;

  static Future<void> main(({String data, SendPort port}) data) async {
    Future<Isar> loadAndSend(String directory, SendPort port) async {
      final favoritePostDb = Isar.openSync(
        const [IsarFavoritePostSchema],
        directory: directory,
        inspector: false,
        name: "favoritePosts",
      );

      List<IsarFavoritePost> list = [];

      void send(FavoritePostResult res) {
        port.send(res);
      }

      try {
        for (final e in IsarCollectionReverseIterable(
          IsarCollectionIterator(
            favoritePostDb.isarFavoritePosts,
            reversed: false,
            bufferLen: 100,
          ),
        )) {
          list.add(e);
          if (list.length == 100) {
            send(PostsAddedResult(List<IsarFavoritePost>.unmodifiable(list)));
            list = [];
          }
        }

        if (list.isNotEmpty) {
          send(PostsAddedResult(List<IsarFavoritePost>.unmodifiable(list)));
          list = const [];
        }
        send(const PostsAddedResult([]));
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }

      return favoritePostDb;
    }

    final mgmt = IsolateManagement(data.port);
    await mgmt.init();

    final db = await mgmt.runCatching(() => loadAndSend(data.data, data.port));
    if (db == null) {
      mgmt.destroy();
      return;
    }

    void send(FavoritePostResult res) {
      data.port.send(res);
    }

    void clearPosts() {
      db.writeTxnSync(() {
        db.isarFavoritePosts.clearSync();
      });

      send(const PostsClearResult());
    }

    void removePosts(List<(int id, Booru booru)> posts) {
      final (listA, listB) = posts.fold((<int>[], <Booru>[]), (lists, e) {
        lists.$1.add(e.$1);
        lists.$2.add(e.$2);

        return lists;
      });

      db.writeTxnSync(() {
        db.isarFavoritePosts.deleteAllByIdBooruSync(listA, listB);
      });

      send(PostsRemovedResult(posts));
    }

    void addPosts(List<FavoritePost> posts) {
      db.writeTxnSync(() {
        db.isarFavoritePosts.putAllByIdBooruSync(posts.cast());
      });

      send(PostsAddedResult(posts));
    }

    void messageEvents(dynamic e) {
      final message = e as _FavoritePostData;

      return switch (message) {
        AddPosts() => addPosts(message.posts),
        RemovePosts() => removePosts(message.posts),
        ClearPosts() => clearPosts(),
      };
    }

    await mgmt.listen(messageEvents);
  }

  @override
  void onEvent(dynamic e) {
    if (_resultEvents.isClosed) {
      return;
    }

    _resultEvents.add(e as FavoritePostResult);
  }

  @override
  void destroy() {
    _resultEvents.close();
    super.destroy();
  }
}
