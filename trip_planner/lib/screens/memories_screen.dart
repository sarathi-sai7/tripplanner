import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'album_detail_screen.dart';
import 'models.dart';
import 'album_storage.dart';
import 'favorites_storage.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() =>
      _MemoriesScreenState();
}

class _MemoriesScreenState
    extends State<MemoriesScreen> {
  List<Album> _albums = [];

  List<Album> _filteredAlbums = [];

  final TextEditingController
      _searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    _loadAlbums();

    _searchController.addListener(() {
      _filterAlbums();
    });
  }

  Future<void> _loadAlbums() async {
    final loaded =
        await AlbumStorage.loadAlbums();

    if (mounted) {
      setState(() {
        _albums = loaded;
        _filteredAlbums = loaded;
      });
    }
  }

  void _filterAlbums() {
    final query =
        _searchController.text
            .toLowerCase();

    setState(() {
      _filteredAlbums =
          _albums.where((album) {
        return album.name
            .toLowerCase()
            .contains(query);
      }).toList();
    });
  }

  void _showLoginPrompt(
      String action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
                  22),
        ),
        title: const Text(
          "Login Required",
        ),
        content: Text(
          "You must be logged in to $action.",
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx),
            child:
                const Text("Cancel"),
          ),
          ElevatedButton(
            style:
                ElevatedButton
                    .styleFrom(
              backgroundColor:
                  Colors.teal,
            ),
            onPressed: () {
              Navigator.pop(ctx);

              Navigator.pushNamed(
                context,
                '/login',
              );
            },
            child: const Text(
              "Login",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _createAlbum() {
    final user =
        FirebaseAuth.instance
            .currentUser;

    if (user == null) {
      _showLoginPrompt(
          "create an album");
      return;
    }

    final controller =
        TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
                  24),
        ),
        title: const Text(
          "Create Album",
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          decoration:
              InputDecoration(
            hintText:
                "Album name",
            filled: true,
            fillColor:
                Colors.grey.shade100,
            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius
                      .circular(18),
              borderSide:
                  BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx),
            child:
                const Text("Cancel"),
          ),
          ElevatedButton(
            style:
                ElevatedButton
                    .styleFrom(
              backgroundColor:
                  Colors.teal,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius
                        .circular(
                            12),
              ),
            ),
            onPressed: () async {
              final name =
                  controller.text
                      .trim();

              if (name
                  .isNotEmpty) {
                final newAlbum =
                    Album(
                  name: name,
                  memories: [],
                );

                await AlbumStorage
                    .updateAlbum(
                        newAlbum);

                await _loadAlbums();

                if (mounted && ctx.mounted) {
                  Navigator.pop(
                      ctx);

                  ScaffoldMessenger.of(
                          context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        'Album "$name" created.',
                      ),
                      backgroundColor:
                          Colors.teal,
                      behavior:
                          SnackBarBehavior
                              .floating,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Create",
              style: TextStyle(
                color:
                    Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  void _deleteAlbum(
      int index) async {
    final album =
        _filteredAlbums[index];

    await AlbumStorage
        .deleteAlbum(album);

    await FavoritesStorage
        .removeFavorite(album);

    await _loadAlbums();

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Album "${album.name}" deleted.',
          ),
          backgroundColor:
              Colors.red,
          behavior:
              SnackBarBehavior
                  .floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(
      BuildContext context) {
    final user =
        FirebaseAuth.instance
            .currentUser;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FB),

      floatingActionButton:
          FloatingActionButton.extended(
        backgroundColor:
            Colors.teal,
        elevation: 4,
        onPressed: user == null
            ? () => _showLoginPrompt(
                "create an album")
            : _createAlbum,
        icon: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        label: const Text(
          "New Album",
          style: TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                22,
                18,
                22,
                12,
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Text(
                        "My Memories ✨",
                        style:
                            TextStyle(
                          fontSize:
                              30,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                      const SizedBox(
                          height: 4),
                      Text(
                        "${_albums.length} albums saved",
                        style:
                            TextStyle(
                          color: Colors
                              .grey
                              .shade600,
                          fontSize:
                              13,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,
                      borderRadius:
                          BorderRadius
                              .circular(
                                  16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors
                              .black
                              .withValues(
                                  alpha: 0.05),
                          blurRadius:
                              12,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.favorite,
                        color:
                            Colors.red,
                      ),
                      onPressed:
                          () async {
                        await Navigator
                            .pushNamed(
                          context,
                          '/favorites',
                        );

                        await _loadAlbums();
                      },
                    ),
                  ),
                ],
              ),
            ),

            // SEARCH BAR
            Padding(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 22,
              ),
              child: Container(
                height: 56,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,
                  borderRadius:
                      BorderRadius
                          .circular(
                              18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors
                          .black
                          .withValues(
                              alpha: 0.04),
                      blurRadius:
                          14,
                    ),
                  ],
                ),
                child: TextField(
                  controller:
                      _searchController,
                  decoration:
                      InputDecoration(
                    hintText:
                        "Search albums...",
                    prefixIcon:
                        const Icon(
                      Icons.search,
                      color:
                          Colors.teal,
                    ),
                    suffixIcon:
                        _searchController
                                .text
                                .isNotEmpty
                            ? IconButton(
                                icon:
                                    const Icon(
                                  Icons
                                      .close,
                                ),
                                onPressed:
                                    () {
                                  _searchController
                                      .clear();
                                },
                              )
                            : null,
                    border:
                        InputBorder.none,
                    hintStyle:
                        TextStyle(
                      color: Colors
                          .grey
                          .shade500,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(
                height: 16),

            // BODY
            Expanded(
              child:
                  _filteredAlbums
                          .isEmpty
                      ? Center(
                          child:
                              Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets
                                        .all(
                                            28),
                                decoration:
                                    BoxDecoration(
                                  color: Colors
                                      .teal
                                      .withValues(
                                          alpha: 0.08),
                                  shape:
                                      BoxShape
                                          .circle,
                                ),
                                child:
                                    const Icon(
                                  Icons
                                      .photo_album_rounded,
                                  size:
                                      64,
                                  color:
                                      Colors
                                          .teal,
                                ),
                              ),
                              const SizedBox(
                                  height:
                                      22),
                              const Text(
                                "No Albums Yet",
                                style:
                                    TextStyle(
                                  fontSize:
                                      24,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                              const SizedBox(
                                  height:
                                      10),
                              Text(
                                "Create albums and save\nbeautiful travel memories.",
                                textAlign:
                                    TextAlign
                                        .center,
                                style:
                                    TextStyle(
                                  color: Colors
                                      .grey
                                      .shade600,
                                  height:
                                      1.5,
                                  fontSize:
                                      14,
                                ),
                              ),
                              const SizedBox(
                                  height:
                                      30),
                              ElevatedButton
                                  .icon(
                                style:
                                    ElevatedButton
                                        .styleFrom(
                                  backgroundColor:
                                      Colors
                                          .teal,
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal:
                                        22,
                                    vertical:
                                        14,
                                  ),
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                            16),
                                  ),
                                ),
                                onPressed: user ==
                                        null
                                    ? () => _showLoginPrompt(
                                        "create an album")
                                    : _createAlbum,
                                icon:
                                    const Icon(
                                  Icons.add,
                                  color: Colors
                                      .white,
                                ),
                                label:
                                    const Text(
                                  "Create Album",
                                  style:
                                      TextStyle(
                                    color: Colors
                                        .white,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )

                      // GRID
                      : GridView.builder(
                          padding:
                              const EdgeInsets
                                  .all(
                                      18),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                2,
                            mainAxisSpacing:
                                18,
                            crossAxisSpacing:
                                18,
                            childAspectRatio:
                                0.78,
                          ),
                          itemCount:
                              _filteredAlbums
                                  .length,
                          itemBuilder:
                              (
                            ctx,
                            i,
                          ) {
                            final album =
                                _filteredAlbums[
                                    i];

                            final hasImage =
                                album.memories
                                        .isNotEmpty &&
                                    album
                                        .memories
                                        .first
                                        .imagePath
                                        .isNotEmpty;

                            return GestureDetector(
                              onTap:
                                  () async {
                                await Navigator
                                    .push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) =>
                                            AlbumDetailScreen(
                                      album:
                                          album,
                                    ),
                                  ),
                                );

                                await _loadAlbums();
                              },
                              child:
                                  Container(
                                decoration:
                                    BoxDecoration(
                                  color: Colors
                                      .white,
                                  borderRadius:
                                      BorderRadius.circular(
                                          28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors
                                          .black
                                          .withValues(
                                              alpha: 0.05),
                                      blurRadius:
                                          18,
                                      offset:
                                          const Offset(
                                              0,
                                              8),
                                    ),
                                  ],
                                ),
                                child:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    // IMAGE
                                    Expanded(
                                      child:
                                          Stack(
                                        children: [
                                          Container(
                                            width:
                                                double.infinity,
                                            decoration:
                                                BoxDecoration(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                top:
                                                    Radius.circular(
                                                        28),
                                              ),
                                              image: hasImage
                                                  ? DecorationImage(
                                                      image: FileImage(
                                                        File(
                                                          album.memories.first.imagePath,
                                                        ),
                                                      ),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                              gradient:
                                                  hasImage
                                                      ? null
                                                      : const LinearGradient(
                                                          colors: [
                                                            Color(
                                                                0xFF009688),
                                                            Color(
                                                                0xFF4DB6AC),
                                                          ],
                                                        ),
                                            ),
                                            child: !hasImage
                                                ? const Center(
                                                    child:
                                                        Icon(
                                                      Icons.photo_album_rounded,
                                                      color:
                                                          Colors.white,
                                                      size:
                                                          42,
                                                    ),
                                                  )
                                                : null,
                                          ),

                                          Positioned(
                                            top: 12,
                                            right: 12,
                                            child:
                                                Container(
                                              padding:
                                                  const EdgeInsets
                                                      .all(
                                                          8),
                                              decoration:
                                                  BoxDecoration(
                                                color: Colors
                                                    .white
                                                    .withValues(
                                                        alpha: 0.92),
                                                shape:
                                                    BoxShape.circle,
                                              ),
                                              child:
                                                  const Icon(
                                                Icons
                                                    .photo_library_outlined,
                                                color:
                                                    Colors.teal,
                                                size:
                                                    18,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // CONTENT
                                    Padding(
                                      padding:
                                          const EdgeInsets
                                              .all(
                                                  16),
                                      child:
                                          Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            album
                                                .name,
                                            maxLines:
                                                1,
                                            overflow:
                                                TextOverflow
                                                    .ellipsis,
                                            style:
                                                const TextStyle(
                                              fontSize:
                                                  17,
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(
                                              height:
                                                  8),
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(
                                                        6),
                                                decoration:
                                                    BoxDecoration(
                                                  color: Colors
                                                      .teal
                                                      .withValues(
                                                          alpha: 0.08),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10),
                                                ),
                                                child:
                                                    const Icon(
                                                  Icons.photo_library_outlined,
                                                  size:
                                                      15,
                                                  color:
                                                      Colors.teal,
                                                ),
                                              ),
                                              const SizedBox(
                                                  width:
                                                      8),
                                              Text(
                                                "${album.memories.length} memories",
                                                style:
                                                    TextStyle(
                                                  color: Colors
                                                      .grey
                                                      .shade700,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize:
                                                      12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                              height:
                                                  14),
                                          SizedBox(
                                            width:
                                                double.infinity,
                                            child:
                                                ElevatedButton(
                                              style:
                                                  ElevatedButton.styleFrom(
                                                elevation:
                                                    0,
                                                backgroundColor:
                                                    Colors.teal,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical:
                                                      12,
                                                ),
                                                shape:
                                                    RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          14),
                                                ),
                                              ),
                                              onPressed:
                                                  () async {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        AlbumDetailScreen(
                                                      album: album,
                                                    ),
                                                  ),
                                                );

                                                await _loadAlbums();
                                              },
                                              child:
                                                  const Text(
                                                "Open Album",
                                                style:
                                                    TextStyle(
                                                  color:
                                                      Colors.white,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}