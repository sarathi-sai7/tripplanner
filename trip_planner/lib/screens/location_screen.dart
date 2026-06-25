import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() =>
      _LocationScreenState();
}

class _LocationScreenState
    extends State<LocationScreen> {

  late GoogleMapController
      _mapController;

  final TextEditingController
      _searchController =
      TextEditingController();

  final LatLng _initialPosition =
      const LatLng(
    10.8505,
    76.2711,
  );

  MapType _currentMapType =
      MapType.normal;

  final Set<Marker> _markers = {};

  bool _mapReady = false;

  bool _isSearching = false;

  final String _googleApiKey =
      dotenv.env[
              'GOOGLE_MAPS_API_KEY'] ??
          '';

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  void _onMapCreated(
    GoogleMapController
        controller,
  ) {
    _mapController = controller;

    setState(() {
      _mapReady = true;
    });
  }

  void _showMapTypeSelector() {
    showModalBottomSheet(
      context: context,

      backgroundColor:
          Colors.white,

      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),

      builder: (context) {

        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(
                    18),

            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [

                Container(
                  width: 45,
                  height: 5,

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.grey
                            .shade300,

                    borderRadius:
                        BorderRadius
                            .circular(
                                20),
                  ),
                ),

                const SizedBox(
                    height: 22),

                const Align(
                  alignment:
                      Alignment
                          .centerLeft,

                  child: Text(
                    "Map Style",

                    style:
                        TextStyle(
                      fontSize: 22,

                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                ),

                const SizedBox(
                    height: 18),

                _mapTypeTile(
                  icon:
                      Icons.map_rounded,

                  title: "Normal",

                  type:
                      MapType.normal,
                ),

                _mapTypeTile(
                  icon: Icons
                      .satellite_alt_rounded,

                  title:
                      "Satellite",

                  type: MapType
                      .satellite,
                ),

                _mapTypeTile(
                  icon:
                      Icons.terrain,

                  title:
                      "Terrain",

                  type:
                      MapType.terrain,
                ),

                _mapTypeTile(
                  icon:
                      Icons.layers,

                  title:
                      "Hybrid",

                  type:
                      MapType.hybrid,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mapTypeTile({
    required IconData icon,
    required String title,
    required MapType type,
  }) {

    final selected =
        _currentMapType == type;

    return Padding(
      padding:
          const EdgeInsets.only(
              bottom: 12),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(
                18),

        onTap: () {

          setState(() {
            _currentMapType =
                type;
          });

          Navigator.pop(context);
        },

        child: Container(
          padding:
              const EdgeInsets.all(
                  16),

          decoration:
              BoxDecoration(
            color: selected
                ? Colors.teal
                    .withOpacity(
                        0.08)
                : Colors.white,

            borderRadius:
                BorderRadius
                    .circular(18),

            border: Border.all(
              color: selected
                  ? Colors.teal
                  : Colors.grey
                      .shade200,
            ),
          ),

          child: Row(
            children: [

              Container(
                padding:
                    const EdgeInsets
                        .all(10),

                decoration:
                    BoxDecoration(
                  color: selected
                      ? Colors.teal
                      : Colors.grey
                          .shade100,

                  borderRadius:
                      BorderRadius
                          .circular(
                              14),
                ),

                child: Icon(
                  icon,

                  color: selected
                      ? Colors.white
                      : Colors.teal,
                ),
              ),

              const SizedBox(
                  width: 14),

              Expanded(
                child: Text(
                  title,

                  style:
                      TextStyle(
                    fontSize: 16,

                    fontWeight:
                        FontWeight
                            .w600,

                    color: selected
                        ? Colors.teal
                        : Colors.black,
                  ),
                ),
              ),

              if (selected)
                const Icon(
                  Icons
                      .check_circle,

                  color:
                      Colors.teal,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _addMarker(
    LatLng position,
    String title,
  ) {

    final marker = Marker(
      markerId:
          MarkerId(title),

      position: position,

      infoWindow:
          InfoWindow(
        title: title,
      ),
    );

    setState(() {
      _markers.add(marker);
    });
  }

  void _clearMarkers() {

    setState(() {
      _markers.clear();
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            const Text(
          "All markers cleared",
        ),

        backgroundColor:
            Colors.teal,

        behavior:
            SnackBarBehavior
                .floating,
      ),
    );
  }

  Future<LatLng?>
      _getCoordinatesFromGoogle(
    String place,
  ) async {

    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(place)}&key=$_googleApiKey",
    );

    try {

      final response =
          await http.get(url);

      if (response.statusCode ==
          200) {

        final data =
            jsonDecode(
                response.body);

        if ((data['results']
                as List)
            .isNotEmpty) {

          final location =
              data['results'][0]
                      ['geometry']
                  ['location'];

          return LatLng(
            location['lat'],
            location['lng'],
          );
        }
      }

      return null;

    } catch (e) {

      debugPrint(
        "Geocoding error: $e",
      );

      return null;
    }
  }

  Future<void> _goToPlace(
      String place) async {

    if (!_mapReady) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Map is not ready yet",
          ),
        ),
      );

      return;
    }

    setState(() {
      _isSearching = true;
    });

    final position =
        await _getCoordinatesFromGoogle(
            place);

    setState(() {
      _isSearching = false;
    });

    if (position != null) {

      _mapController.animateCamera(
        CameraUpdate
            .newLatLngZoom(
          position,
          14,
        ),
      );

      _addMarker(
        position,
        place,
      );

    } else {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Could not find location: $place",
          ),

          behavior:
              SnackBarBehavior
                  .floating,
        ),
      );
    }
  }

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(
      backgroundColor:
          Colors.white,

      appBar: AppBar(
        title: const Text(
          "Explore",

          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        backgroundColor:
            Colors.white,

        foregroundColor:
            Colors.black,

        elevation: 0,

        actions: [

          Container(
            margin:
                const EdgeInsets.only(
              right: 4,
            ),

            child: IconButton(
              icon: const Icon(
                Icons
                    .layers_rounded,
              ),

              onPressed:
                  _showMapTypeSelector,
            ),
          ),

          Container(
            margin:
                const EdgeInsets.only(
              right: 12,
            ),

            child: IconButton(
              icon: const Icon(
                Icons
                    .delete_outline,
              ),

              tooltip:
                  "Clear markers",

              onPressed:
                  _clearMarkers,
            ),
          ),
        ],
      ),

      body: Stack(
        children: [

          // MAP
          GoogleMap(
            onMapCreated:
                _onMapCreated,

            initialCameraPosition:
                CameraPosition(
              target:
                  _initialPosition,

              zoom: 7.5,
            ),

            mapType:
                _currentMapType,

            myLocationEnabled:
                true,

            myLocationButtonEnabled:
                false,

            compassEnabled:
                true,

            zoomControlsEnabled:
                false,

            trafficEnabled:
                true,

            buildingsEnabled:
                true,

            indoorViewEnabled:
                true,

            markers: _markers,
          ),

          // SEARCH BAR
          Positioned(
            top: 16,
            left: 16,
            right: 16,

            child: Container(
              decoration:
                  BoxDecoration(
                color:
                    Colors.white,

                borderRadius:
                    BorderRadius
                        .circular(
                            20),

                boxShadow: [
                  BoxShadow(
                    color: Colors
                        .black
                        .withOpacity(
                            0.08),

                    blurRadius:
                        20,
                  ),
                ],
              ),

              child: TextField(
                controller:
                    _searchController,

                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight
                          .w500,
                ),

                decoration:
                    InputDecoration(
                  hintText:
                      "Search destinations...",

                  hintStyle:
                      TextStyle(
                    color: Colors
                        .grey
                        .shade500,
                  ),

                  prefixIcon:
                      const Icon(
                    Icons.search,
                    color:
                        Colors.teal,
                  ),

                  suffixIcon:
                      _isSearching
                          ? const Padding(
                              padding:
                                  EdgeInsets.all(
                                      14),

                              child:
                                  SizedBox(
                                width:
                                    18,

                                height:
                                    18,

                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,

                                  color:
                                      Colors.teal,
                                ),
                              ),
                            )

                          : IconButton(
                              icon:
                                  const Icon(
                                Icons
                                    .send_rounded,

                                color:
                                    Colors
                                        .teal,
                              ),

                              onPressed:
                                  () {

                                final place =
                                    _searchController
                                        .text
                                        .trim();

                                if (place
                                    .isNotEmpty) {

                                  _goToPlace(
                                      place);
                                }
                              },
                            ),

                  border:
                      InputBorder.none,

                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 18,
                  ),
                ),

                onSubmitted:
                    (value) {

                  final place =
                      value.trim();

                  if (place
                      .isNotEmpty) {

                    _goToPlace(
                        place);
                  }
                },
              ),
            ),
          ),
        ],
      ),

      floatingActionButton:
          FloatingActionButton(
        backgroundColor:
            Colors.white,

        elevation: 6,

        child: const Icon(
          Icons.my_location,

          color: Colors.teal,
        ),

        onPressed: () {

          if (_mapReady) {

            _mapController
                .animateCamera(
              CameraUpdate
                  .newLatLngZoom(
                _initialPosition,
                10,
              ),
            );
          }
        },
      ),
    );
  }
}