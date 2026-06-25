// place_search_delegate.dart
import 'package:flutter/material.dart';
import '../models/tourist_place.dart';
import 'trip_builder_screen.dart';

class PlaceSearchDelegate extends SearchDelegate<String> {
  final List<TouristPlace> places;
  final Set<TouristPlace> selectedPlaces = {};

  PlaceSearchDelegate(this.places);

  @override
  String get searchFieldLabel => 'Search destinations, districts...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1A1A2E)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: Color(0xFFAAABB5),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: Color(0xFF1A1A2E),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Color(0xFF666680)),
              ),
              onPressed: () => query = '',
            ),
          ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => close(context, ''),
      );

  List<TouristPlace> get filteredPlaces => places
      .where((p) =>
          p.place.toLowerCase().contains(query.trim().toLowerCase()) ||
          p.district.toLowerCase().contains(query.trim().toLowerCase()))
      .toList();

  @override
  Widget buildResults(BuildContext context) => _SearchBody(
        results: filteredPlaces,
        query: query,
        selectedPlaces: selectedPlaces,
        onSelectionChanged: () {},
        onBuildTrip: () => _navigateToTripBuilder(context),
      );

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _EmptySearchState(places: places);
    }
    return _SearchBody(
      results: filteredPlaces,
      query: query,
      selectedPlaces: selectedPlaces,
      onSelectionChanged: () {},
      onBuildTrip: () => _navigateToTripBuilder(context),
    );
  }

  void _navigateToTripBuilder(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TripBuilderScreen(
          destination: query,
          suggestedPlaces: selectedPlaces
              .map((p) => {"name": p.place, "image": ""})
              .toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Empty / idle state shown before user types
// ─────────────────────────────────────────────────────────────
class _EmptySearchState extends StatelessWidget {
  final List<TouristPlace> places;
  const _EmptySearchState({required this.places});

  @override
  Widget build(BuildContext context) {
    // Collect unique districts for quick-pick chips
    final districts = places.map((p) => p.district).toSet().take(8).toList();

    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Illustration / prompt
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.travel_explore,
                      size: 40, color: Color(0xFF4F5BD5)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Where do you want to go?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Search by place name or district',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9090A8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Popular Districts
          const Text(
            'POPULAR DISTRICTS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9090A8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: districts
                .map((d) => _DistrictChip(label: d))
                .toList(),
          ),

          const SizedBox(height: 32),

          // Stats row
          Row(
            children: [
              _StatCard(
                icon: Icons.place_outlined,
                value: '${places.length}+',
                label: 'Destinations',
                color: const Color(0xFF4F5BD5),
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.map_outlined,
                value: '${places.map((p) => p.district).toSet().length}',
                label: 'Districts',
                color: const Color(0xFF00C896),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DistrictChip extends StatelessWidget {
  final String label;
  const _DistrictChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E3FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_outlined,
              size: 14, color: Color(0xFF4F5BD5)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4F5BD5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9090A8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Search results body
// ─────────────────────────────────────────────────────────────
class _SearchBody extends StatefulWidget {
  final List<TouristPlace> results;
  final String query;
  final Set<TouristPlace> selectedPlaces;
  final VoidCallback onSelectionChanged;
  final VoidCallback onBuildTrip;

  const _SearchBody({
    required this.results,
    required this.query,
    required this.selectedPlaces,
    required this.onSelectionChanged,
    required this.onBuildTrip,
  });

  @override
  State<_SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<_SearchBody> {
  late Set<TouristPlace> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedPlaces;
  }

  void _toggle(TouristPlace p) {
    setState(() {
      if (_selected.contains(p)) {
        _selected.remove(p);
      } else {
        _selected.add(p);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty) {
      return _NoResults(query: widget.query);
    }

    return Container(
      color: const Color(0xFFF8F9FE),
      child: Stack(
        children: [
          Column(
            children: [
              // Results count bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      '${widget.results.length} places found',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const Spacer(),
                    if (_selected.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F5BD5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_selected.length} selected',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEEEFF5)),

              // List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: widget.results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final p = widget.results[index];
                    final isSelected = _selected.contains(p);
                    return _PlaceCard(
                      place: p,
                      isSelected: isSelected,
                      onToggle: () => _toggle(p),
                      onDetail: () => _showDetails(context, p),
                    );
                  },
                ),
              ),
            ],
          ),

          // Build Trip FAB
          if (_selected.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _BuildTripButton(
                count: _selected.length,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TripBuilderScreen(
                        destination: widget.query,
                        suggestedPlaces: _selected
                            .map((p) => {"name": p.place, "image": ""})
                            .toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, TouristPlace p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlaceDetailSheet(place: p),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Individual place card
// ─────────────────────────────────────────────────────────────
class _PlaceCard extends StatelessWidget {
  final TouristPlace place;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onDetail;

  const _PlaceCard({
    required this.place,
    required this.isSelected,
    required this.onToggle,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF4F5BD5)
              : const Color(0xFFEEEFF5),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFF4F5BD5).withOpacity(0.12)
                : Colors.black.withOpacity(0.04),
            blurRadius: isSelected ? 12 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onDetail,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox / icon area
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4F5BD5)
                          : const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSelected ? Icons.check : Icons.place_outlined,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF4F5BD5),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              place.place,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              place.district,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF4F5BD5),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        place.whyVisit,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6E6E8A),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time_outlined,
                              size: 13, color: Color(0xFF9090A8)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              place.timing,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9090A8),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'Details →',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4F5BD5),
                              fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Build Trip floating button
// ─────────────────────────────────────────────────────────────
class _BuildTripButton extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;

  const _BuildTripButton({required this.count, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F5BD5), Color(0xFF7B2FBE)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F5BD5).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Build Trip',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Place detail bottom sheet
// ─────────────────────────────────────────────────────────────
class _PlaceDetailSheet extends StatelessWidget {
  final TouristPlace place;
  const _PlaceDetailSheet({required this.place});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.place,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: Color(0xFF4F5BD5)),
                        const SizedBox(width: 4),
                        Text(
                          place.district,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4F5BD5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF0F0F8)),
          const SizedBox(height: 16),

          // Info rows
          _InfoRow(
            icon: Icons.star_outline_rounded,
            iconColor: const Color(0xFFFFB300),
            label: 'Why Visit',
            value: place.whyVisit,
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.access_time_outlined,
            iconColor: const Color(0xFF00C896),
            label: 'Best Timing',
            value: place.timing,
          ),
          const SizedBox(height: 28),

          // Close button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A2E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Got it',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9090A8),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A2E),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// No results state
// ─────────────────────────────────────────────────────────────
class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 36, color: Color(0xFFAAABBE)),
            ),
            const SizedBox(height: 16),
            Text(
              'No results for "$query"',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try a different place name or district',
              style: TextStyle(fontSize: 13, color: Color(0xFF9090A8)),
            ),
          ],
        ),
      ),
    );
  }
}