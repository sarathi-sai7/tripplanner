// favorites_storage.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models.dart';

class FavoritesStorage {
  // Each user gets their own key: "favorites_uid123abc"
  static String get _key {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("No user logged in");
    return 'favorites_$uid';
  }

  static Future<List<Album>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];
    final List decoded = jsonDecode(jsonString);
    return decoded.map((a) => Album.fromJson(a)).toList();
  }

  static Future<void> _saveFavorites(List<Album> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = favorites.map((a) => a.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  static Future<void> addFavorite(Album album) async {
    final favorites = await loadFavorites();
    if (!favorites.any((a) => a.name == album.name)) {
      favorites.add(album);
      await _saveFavorites(favorites);
    }
  }

  static Future<void> removeFavorite(Album album) async {
    final favorites = await loadFavorites();
    favorites.removeWhere((a) => a.name == album.name);
    await _saveFavorites(favorites);
  }

  static Future<bool> isFavorite(Album album) async {
    final favorites = await loadFavorites();
    return favorites.any((a) => a.name == album.name);
  }
}