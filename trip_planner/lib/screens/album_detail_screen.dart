// album_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models.dart';
import 'album_storage.dart';
import 'login_screen.dart';
import 'favorites_storage.dart';

class AlbumDetailScreen extends StatefulWidget {
  final Album album;
  const AlbumDetailScreen({super.key, required this.album});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  late Album _album;
  final ImagePicker _picker = ImagePicker();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _album = widget.album;
    _initFavoriteState();
  }

  Future<void> _initFavoriteState() async {
    final fav = await FavoritesStorage.isFavorite(_album);
    if (mounted) setState(() => _isFavorite = fav);
  }

  void _showLoginPrompt(String action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Login Required"),
        content: Text("You must be logged in to $action."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginPrompt("add to favorites");
      return;
    }

    if (_isFavorite) {
      await FavoritesStorage.removeFavorite(_album);
      if (mounted) setState(() => _isFavorite = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed "${_album.name}" from favorites')),
        );
      }
    } else {
      await FavoritesStorage.addFavorite(_album);
      if (mounted) setState(() => _isFavorite = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added "${_album.name}" to favorites')),
        );
      }
      if (mounted) Navigator.pushNamed(context, '/favorites');
    }
  }

  Future<void> _addMemory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginPrompt("add memories");
      return;
    }

    final titleCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    XFile? pickedImage;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateSB) => AlertDialog(
          title: const Text("Add Memory"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    pickedImage = await _picker.pickImage(
                        source: ImageSource.gallery);
                    setStateSB(() {});
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: pickedImage == null
                        ? const Center(child: Text("Tap to add photo"))
                        : Image.file(File(pickedImage!.path),
                            fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                      labelText: "Title (e.g. Day 1: Kochi)"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: locationCtrl,
                  decoration:
                      const InputDecoration(labelText: "Location"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (pickedImage != null &&
                    titleCtrl.text.trim().isNotEmpty &&
                    locationCtrl.text.trim().isNotEmpty) {
                  final newMemory = Memory(
                    title: titleCtrl.text.trim(),
                    location: locationCtrl.text.trim(),
                    imagePath: pickedImage!.path,
                  );
                  final updatedAlbum = _album.copyWith(
                    memories: List.from(_album.memories)..add(newMemory),
                  );
                  // Save to storage first, then update state
                  await AlbumStorage.updateAlbum(updatedAlbum);
                  if (mounted) setState(() => _album = updatedAlbum);
                  // Also sync to favorites if this album is a favorite
                  if (_isFavorite) {
                    await FavoritesStorage.removeFavorite(_album);
                    await FavoritesStorage.addFavorite(updatedAlbum);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMemory(Memory memory) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginPrompt("delete memories");
      return;
    }

    final updatedAlbum = _album.copyWith(
      memories: List.from(_album.memories)..remove(memory),
    );
    await AlbumStorage.updateAlbum(updatedAlbum);
    // Sync favorites if needed
    if (_isFavorite) {
      await FavoritesStorage.removeFavorite(_album);
      await FavoritesStorage.addFavorite(updatedAlbum);
    }
    if (mounted) setState(() => _album = updatedAlbum);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(_album.name),
        actions: [
          IconButton(
            icon: _isFavorite
                ? const Icon(Icons.favorite, color: Colors.pink)
                : const Icon(Icons.favorite_border),
            onPressed: _toggleFavorite,
            tooltip:
                _isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
          IconButton(
            onPressed: user == null
                ? () => _showLoginPrompt("add memories")
                : _addMemory,
            icon: const Icon(Icons.add_a_photo),
          ),
        ],
      ),
      body: _album.memories.isEmpty
          ? const Center(child: Text("No memories yet. Add some!"))
          : ListView.builder(
              itemCount: _album.memories.length,
              itemBuilder: (ctx, i) {
                final mem = _album.memories[i];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Image.file(File(mem.imagePath),
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover),
                          Positioned(
                            right: 5,
                            top: 5,
                            child: IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: user == null
                                  ? () =>
                                      _showLoginPrompt("delete memories")
                                  : () => _deleteMemory(mem),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mem.title,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("📍 ${mem.location}",
                                style:
                                    const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}