// place_search_screen.dart
import 'package:flutter/material.dart';
import '../models/tourist_place.dart';
import 'trip_builder_screen.dart';

class PlaceSearchScreen extends StatefulWidget {
  final List<TouristPlace> places;

  const PlaceSearchScreen({super.key, required this.places});

  @override
  State<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<TouristPlace> _filtered = [];
  final Set<TouristPlace> _selected = {};
  String _query = '';

  // Colour + icon palette cycling per tile
  static const List<Color> _tileColors = [
    Color(0xFF4F5BD5), Color(0xFF00C896), Color(0xFFFF6B6B),
    Color(0xFFFFB300), Color(0xFF7B2FBE), Color(0xFF00AEEF),
    Color(0xFFFF8C42), Color(0xFF2ECC71),
  ];
  static const List<IconData> _tileIcons = [
    Icons.landscape_outlined,
    Icons.temple_buddhist_outlined,
    Icons.park_outlined,
    Icons.beach_access_outlined,
    Icons.fort_outlined,
    Icons.museum_outlined,
    Icons.water_outlined,
    Icons.forest_outlined,
  ];

  static const Color _primary  = Color(0xFF4F5BD5);
  static const Color _surface  = Color(0xFFF8F9FE);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _muted    = Color(0xFF9090A8);

  @override
  void initState() {
    super.initState();
    _filtered = List.from(widget.places);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _query = q;
      _filtered = q.isEmpty
          ? List.from(widget.places)
          : widget.places
              .where((p) =>
                  p.place.toLowerCase().contains(q) ||
                  p.district.toLowerCase().contains(q))
              .toList();
    });
  }

  void _togglePlace(TouristPlace p) {
    setState(() {
      if (_selected.contains(p)) {
        _selected.remove(p);
      } else {
        _selected.add(p);
      }
    });
  }

  void _goToBuildTrip() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TripBuilderScreen(
          destination: _query,
          suggestedPlaces:
              _selected.map((p) => {'name': p.place, 'image': ''}).toList(),
        ),
      ),
    );
  }

  void _showDetails(TouristPlace p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlaceDetailSheet(place: p),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            _buildResultsBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: _selected.isNotEmpty ? _buildBuildTripBar() : null,
    );
  }

  // ── Search header ─────────────────────────────────────────────────────────

  Widget _buildSearchHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 18, color: _textDark),
            onPressed: () => Navigator.pop(context),
          ),

          // Search field
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4FB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E6F0)),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 15,
                  color: _textDark,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search destinations, districts...',
                  hintStyle:
                      const TextStyle(color: Color(0xFFAAABB5), fontSize: 14),
                  prefixIcon: const Icon(Icons.search,
                      color: _primary, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Color(0xFFDDDEEA),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 14, color: Color(0xFF666680)),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _focusNode.requestFocus();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Results count bar ─────────────────────────────────────────────────────

  Widget _buildResultsBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Text(
            _query.isEmpty
                ? '${widget.places.length} destinations'
                : '${_filtered.length} results for "$_query"',
            style: const TextStyle(
              fontSize: 13,
              color: _muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (_selected.isNotEmpty) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_selected.length} selected',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _selected.clear()),
              child: const Text(
                'Clear',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    // Idle state — nothing typed yet
    if (_query.isEmpty && _selected.isEmpty) {
      return _IdleState(
        places: widget.places,
        onChipTap: (district) {
          _searchController.text = district;
          _focusNode.unfocus();
        },
      );
    }

    // No results
    if (_filtered.isEmpty) {
      return _NoResults(query: _query);
    }

    // Results list
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, _selected.isNotEmpty ? 100 : 24),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = _filtered[index];
        final isSelected = _selected.contains(p);
        final colorIdx = widget.places.indexOf(p) % _tileColors.length;

        return _PlaceCard(
          place: p,
          isSelected: isSelected,
          color: _tileColors[colorIdx],
          icon: _tileIcons[colorIdx],
          selectionOrder: isSelected
              ? _selected.toList().indexOf(p) + 1
              : null,
          onToggle: () => _togglePlace(p),
          onDetail: () => _showDetails(p),
        );
      },
    );
  }

  // ── Build Trip bottom bar ─────────────────────────────────────────────────

  Widget _buildBuildTripBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      child: GestureDetector(
        onTap: _goToBuildTrip,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4F5BD5), Color(0xFF7B2FBE)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${_selected.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Build Trip',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PLACE CARD
// ═══════════════════════════════════════════════════════════════════════════

class _PlaceCard extends StatelessWidget {
  final TouristPlace place;
  final bool isSelected;
  final Color color;
  final IconData icon;
  final int? selectionOrder;
  final VoidCallback onToggle;
  final VoidCallback onDetail;

  const _PlaceCard({
    required this.place,
    required this.isSelected,
    required this.color,
    required this.icon,
    required this.onToggle,
    required this.onDetail,
    this.selectionOrder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : const Color(0xFFEEEFF5),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? color.withOpacity(0.12)
                : Colors.black.withOpacity(0.04),
            blurRadius: isSelected ? 12 : 5,
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
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tap area for select/deselect
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color
                          : color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Center(
                      child: isSelected && selectionOrder != null
                          ? Text(
                              '$selectionOrder',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : Icon(icon,
                              size: 22,
                              color: isSelected ? Colors.white : color),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Text info
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
                      const SizedBox(height: 5),
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
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(Icons.access_time_outlined,
                              size: 12, color: Color(0xFF9090A8)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              place.timing,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF9090A8)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: onDetail,
                            child: const Text(
                              'Details →',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4F5BD5),
                                fontWeight: FontWeight.w600,
                              ),
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

// ═══════════════════════════════════════════════════════════════════════════
// IDLE STATE (shown before user types)
// ═══════════════════════════════════════════════════════════════════════════

class _IdleState extends StatelessWidget {
  final List<TouristPlace> places;
  final ValueChanged<String> onChipTap;

  const _IdleState({required this.places, required this.onChipTap});

  @override
  Widget build(BuildContext context) {
    final districts = places.map((p) => p.district).toSet().take(10).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        // Hero
        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F5BD5), Color(0xFF7B2FBE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F5BD5).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.travel_explore,
                    size: 38, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Where do you want to go?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Search by place name or district',
                style: TextStyle(fontSize: 13, color: Color(0xFF9090A8)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // District chips
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
              .map((d) => GestureDetector(
                    onTap: () => onChipTap(d),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FF),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: const Color(0xFFE0E3FF)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: Color(0xFF4F5BD5)),
                          const SizedBox(width: 4),
                          Text(
                            d,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4F5BD5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 32),

        // Stats
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
                Text(value,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9090A8),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NO RESULTS
// ═══════════════════════════════════════════════════════════════════════════

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded,
                size: 34, color: Color(0xFFAAABBE)),
          ),
          const SizedBox(height: 14),
          Text(
            'No results for "$query"',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try a different place name or district',
            style: TextStyle(fontSize: 13, color: Color(0xFF9090A8)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PLACE DETAIL BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════

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
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF0F0F8)),
          const SizedBox(height: 16),
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
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A2E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
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