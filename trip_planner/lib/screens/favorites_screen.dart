// favorites_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';

import 'favorites_storage.dart';
import 'models.dart';
import 'album_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() =>
      _FavoritesScreenState();
}

class _FavoritesScreenState
    extends State<FavoritesScreen> {

  List<Album> _favorites = [];

  @override
  void initState() {
    super.initState();

    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final list =
        await FavoritesStorage
            .loadFavorites();

    if (mounted) {
      setState(() {
        _favorites = list;
      });
    }
  }

  Future<void> _openMemories() async {
    await Navigator.pushNamed(
      context,
      '/memories',
    );

    await _loadFavorites();
  }

  Future<void> _openAlbumDetail(
      Album album) async {

    final updated =
        await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AlbumDetailScreen(
          album: album,
        ),
      ),
    );

    await _loadFavorites();

    if (updated != null &&
        updated is Album) {

      await FavoritesStorage
          .removeFavorite(album);

      await FavoritesStorage
          .addFavorite(updated);

      await _loadFavorites();
    }
  }

  void _removeFavorite(
      Album album) async {

    await FavoritesStorage
        .removeFavorite(album);

    await _loadFavorites();

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Removed "${album.name}" from favorites',
          ),

          backgroundColor:
              Colors.red,

          behavior:
              SnackBarBehavior
                  .floating,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
                    14),
          ),
        ),
      );
    }
  }

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FB),

      floatingActionButton:
          FloatingActionButton.extended(
        backgroundColor:
            Colors.teal,

        elevation: 4,

        onPressed:
            _openMemories,

        icon: const Icon(
          Icons.add,
          color: Colors.white,
        ),

        label: const Text(
          "Add Favorites",

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
                10,
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
                        "Favorites ❤️",

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
                        "${_favorites.length} saved albums",

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
                      color: Colors
                          .white,

                      borderRadius:
                          BorderRadius
                              .circular(
                                  16),

                      boxShadow: [
                        BoxShadow(
                          color: Colors
                              .black
                              .withOpacity(
                                  0.05),

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

                      onPressed: () {},
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
                vertical: 10,
              ),

              child: Container(
                height: 56,

                decoration:
                    BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius
                          .circular(
                              18),

                  boxShadow: [
                    BoxShadow(
                      color: Colors
                          .black
                          .withOpacity(
                              0.04),

                      blurRadius:
                          14,
                    ),
                  ],
                ),

                child: TextField(
                  readOnly: true,

                  decoration:
                      InputDecoration(
                    hintText:
                        "Search favorites...",

                    prefixIcon:
                        const Icon(
                      Icons.search,
                      color:
                          Colors.teal,
                    ),

                    suffixIcon:
                        Container(
                      margin:
                          const EdgeInsets
                              .all(8),

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.teal,

                        borderRadius:
                            BorderRadius
                                .circular(
                                    12),
                      ),

                      child:
                          const Icon(
                        Icons.tune,
                        color: Colors
                            .white,
                        size: 18,
                      ),
                    ),

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

            // BODY
            Expanded(
              child:
                  _favorites.isEmpty
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
                                            30),

                                decoration:
                                    BoxDecoration(
                                  color: Colors
                                      .red
                                      .withOpacity(
                                          0.08),

                                  shape:
                                      BoxShape
                                          .circle,
                                ),

                                child:
                                    const Icon(
                                  Icons
                                      .favorite_border_rounded,

                                  size:
                                      70,

                                  color:
                                      Colors
                                          .red,
                                ),
                              ),

                              const SizedBox(
                                  height:
                                      24),

                              const Text(
                                "No Favorites Yet",

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
                                "Save beautiful travel memories\nand revisit them anytime.",

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
                                        24,

                                    vertical:
                                        14,
                                  ),

                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                            18),
                                  ),
                                ),

                                onPressed:
                                    _openMemories,

                                icon:
                                    const Icon(
                                  Icons.add,
                                  color: Colors
                                      .white,
                                ),

                                label:
                                    const Text(
                                  "Add Favorites",

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

                      // GRID VIEW
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
                              _favorites
                                  .length,

                          itemBuilder:
                              (
                            ctx,
                            i,
                          ) {

                            final album =
                                _favorites[
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
                                  () =>
                                      _openAlbumDetail(
                                album,
                              ),

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
                                          .withOpacity(
                                              0.05),

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

                                              gradient: hasImage
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
                                                    child: Icon(
                                                      Icons.favorite_rounded,

                                                      color:
                                                          Colors.white,

                                                      size:
                                                          42,
                                                    ),
                                                  )
                                                : null,
                                          ),

                                          Positioned(
                                            top:
                                                12,

                                            right:
                                                12,

                                            child:
                                                GestureDetector(
                                              onTap:
                                                  () =>
                                                      _removeFavorite(
                                                album,
                                              ),

                                              child:
                                                  Container(
                                                padding:
                                                    const EdgeInsets.all(
                                                        8),

                                                decoration:
                                                    BoxDecoration(
                                                  color: Colors
                                                      .white
                                                      .withOpacity(
                                                          0.92),

                                                  shape:
                                                      BoxShape.circle,
                                                ),

                                                child:
                                                    const Icon(
                                                  Icons.favorite,

                                                  color:
                                                      Colors.red,

                                                  size:
                                                      18,
                                                ),
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
                                            album.name,

                                            maxLines:
                                                1,

                                            overflow:
                                                TextOverflow.ellipsis,

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
                                                      .withOpacity(
                                                          0.08),

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