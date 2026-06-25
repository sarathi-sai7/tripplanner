// album_storage.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trip_planner/models/album_memory.dart';

class AlbumStorage {
  // Each user gets their own key: "albums_uid123abc"
  static String get _key {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("No user logged in");
    return 'albums_$uid';
  }

  static Future<void> saveAlbums(List<Album> albums) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = albums.map((a) => a.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  static Future<List<Album>> loadAlbums() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];
    final List decoded = jsonDecode(jsonString);
    return decoded.map((a) => Album.fromJson(a)).toList();
  }

  static Future<void> updateAlbum(Album updated) async {
    final albums = await loadAlbums();
    final index = albums.indexWhere((a) => a.name == updated.name);
    if (index != -1) {
      albums[index] = updated;
    } else {
      albums.add(updated);
    }
    await saveAlbums(albums);
  }

  static Future<void> deleteAlbum(Album album) async {
    final albums = await loadAlbums();
    albums.removeWhere((a) => a.name == album.name);
    await saveAlbums(albums);
  }

  static Future<void> deleteMemory(Album album, Memory memory) async {
    final updatedMemories = List<Memory>.from(album.memories)..remove(memory);
    final updatedAlbum = album.copyWith(memories: updatedMemories);
    await updateAlbum(updatedAlbum);
  }
}
