import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'trip_builder_screen.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Palette (matches TripBuilderScreen) ──────────────────────────────────
  static const Color _primary   = Color(0xFF4F5BD5);
 // static const Color _accent    = Color(0xFF7B2FBE);
  static const Color _surface   = Color(0xFFF8F9FE);
  static const Color _textDark  = Color(0xFF1A1A2E);
  static const Color _textMuted = Color(0xFF9090A8);

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

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _deleteTrip(BuildContext ctx, String docId, String tripName) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Delete Trip',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textDark)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$tripName"? This cannot be undone.',
          style: const TextStyle(fontSize: 14, color: _textMuted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: _textMuted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('trips')
          .doc(docId)
          .delete();

      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: const Text('Trip deleted',
                style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // ── Bottom sheet detail view ──────────────────────────────────────────────

  void _showTripDetail(
    BuildContext ctx,
    QueryDocumentSnapshot trip,
    List<Map<String, String>> places,
    DateTime? createdAt,
  ) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TripDetailSheet(
        trip: trip,
        places: places,
        createdAt: createdAt,
        tileColors: _tileColors,
        tileIcons: _tileIcons,
        onEdit: () {
          Navigator.pop(ctx);
          Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => TripBuilderScreen(
                destination: trip['destination'] ?? 'Default',
                suggestedPlaces: places,
              ),
            ),
          );
        },
        onDelete: () {
          Navigator.pop(ctx);
          _deleteTrip(
            ctx,
            trip.id,
            trip['tripName'] ?? trip['destination'] ?? 'this trip',
          );
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: _surface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F4FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    size: 36, color: _primary),
              ),
              const SizedBox(height: 16),
              const Text('Please log in to view your trips',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textDark)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: _textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Trips',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _textDark,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(user.uid)
            .collection('trips')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                  color: _primary, strokeWidth: 2.5),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _EmptyTrips();
          }

          final trips = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: trips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final trip = trips[index];
              final places = (trip['places'] as List)
                  .map((p) => Map<String, String>.from(p))
                  .toList();
              final createdAt = trip['createdAt'] != null
                  ? (trip['createdAt'] as Timestamp).toDate()
                  : null;
              final colorIdx = index % _tileColors.length;

              return _TripCard(
                trip: trip,
                places: places,
                createdAt: createdAt,
                accentColor: _tileColors[colorIdx],
                accentIcon: _tileIcons[colorIdx],
                onTap: () => _showTripDetail(context, trip, places, createdAt),
                onEdit: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TripBuilderScreen(
                      destination: trip['destination'] ?? 'Default',
                      suggestedPlaces: places,
                    ),
                  ),
                ),
                onDelete: () => _deleteTrip(
                  context,
                  trip.id,
                  trip['tripName'] ?? trip['destination'] ?? 'this trip',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TRIP CARD
// ═══════════════════════════════════════════════════════════════════════════

class _TripCard extends StatelessWidget {
  final QueryDocumentSnapshot trip;
  final List<Map<String, String>> places;
  final DateTime? createdAt;
  final Color accentColor;
  final IconData accentIcon;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TripCard({
    required this.trip,
    required this.places,
    required this.createdAt,
    required this.accentColor,
    required this.accentIcon,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  //static const Color _textDark  = Color(0xFF1A1A2E);
  static const Color _textMuted = Color(0xFF9090A8);

  @override
  Widget build(BuildContext context) {
    final tripName = trip['tripName'] ?? trip['destination'] ?? 'Unnamed Trip';
    final destination = trip['destination'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Coloured header strip ─────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor,
                      accentColor.withOpacity(0.75),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(accentIcon,
                          size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tripName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (destination.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 12, color: Colors.white70),
                                const SizedBox(width: 3),
                                Text(
                                  destination,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    // ── Action buttons ────────────────────────────────
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _HeaderAction(
                          icon: Icons.edit_outlined,
                          tooltip: 'Edit',
                          onTap: onEdit,
                        ),
                        const SizedBox(width: 4),
                        _HeaderAction(
                          icon: Icons.delete_outline_rounded,
                          tooltip: 'Delete',
                          onTap: onDelete,
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Body ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Place chips
                    if (places.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: places.take(5).map((p) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: accentColor.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.place_outlined,
                                    size: 12, color: accentColor),
                                const SizedBox(width: 4),
                                Text(
                                  p['name'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: accentColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList()
                          ..addAll(places.length > 5
                              ? [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F0FA),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '+${places.length - 5} more',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: _textMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ]
                              : []),
                      ),

                    const SizedBox(height: 12),

                    // Footer row
                    Row(
                      children: [
                        const Icon(Icons.confirmation_number_outlined,
                            size: 14, color: _textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${places.length} ${places.length == 1 ? 'place' : 'places'}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: _textMuted,
                              fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        if (createdAt != null) ...[
                          const Icon(Icons.calendar_today_outlined,
                              size: 12, color: _textMuted),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat.yMMMd().format(createdAt!),
                            style: const TextStyle(
                                fontSize: 12, color: _textMuted),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small action button on the card header ────────────────────────────────

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDestructive;

  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withOpacity(0.18)
                : Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              size: 17,
              color: isDestructive ? Colors.red.shade200 : Colors.white),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TRIP DETAIL BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _TripDetailSheet extends StatelessWidget {
  final QueryDocumentSnapshot trip;
  final List<Map<String, String>> places;
  final DateTime? createdAt;
  final List<Color> tileColors;
  final List<IconData> tileIcons;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TripDetailSheet({
    required this.trip,
    required this.places,
    required this.createdAt,
    required this.tileColors,
    required this.tileIcons,
    required this.onEdit,
    required this.onDelete,
  });

  static const Color _primary   = Color(0xFF4F5BD5);
  //static const Color _accent    = Color(0xFF7B2FBE);
  static const Color _textDark  = Color(0xFF1A1A2E);
  static const Color _textMuted = Color(0xFF9090A8);

  @override
  Widget build(BuildContext context) {
    final tripName =
        trip['tripName'] ?? trip['destination'] ?? 'Unnamed Trip';
    final destination = trip['destination'] ?? '';
    final notes = trip['notes'] ?? '';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      minChildSize: 0.45,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
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
              const SizedBox(height: 4),

              // ── Gradient header ───────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F5BD5), Color(0xFF7B2FBE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.luggage_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tripName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (destination.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(destination,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _SummaryChip(
                          label: '${places.length} Places',
                          icon: Icons.place_outlined,
                        ),
                        if (createdAt != null) ...[
                          const SizedBox(width: 8),
                          _SummaryChip(
                            label: DateFormat.yMMMd().format(createdAt!),
                            icon: Icons.calendar_today_outlined,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ── Scrollable body ───────────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    // Notes
                    if (notes.isNotEmpty) ...[
                      const _SectionLabel(text: 'NOTES'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFFE0E3FF)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.notes_outlined,
                                size: 16, color: _primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                notes,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: _textDark,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Itinerary
                    const _SectionLabel(text: 'YOUR ITINERARY'),
                    const SizedBox(height: 12),

                    if (places.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('No places added',
                              style: TextStyle(color: _textMuted)),
                        ),
                      )
                    else
                      ...places.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final place = entry.value;
                        final color =
                            tileColors[idx % tileColors.length];
                        final icon =
                            tileIcons[idx % tileIcons.length];
                        final isLast = idx == places.length - 1;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Timeline
                              Column(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${idx + 1}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (!isLast)
                                    Container(
                                      width: 2,
                                      height: 28,
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(1),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8, bottom: 16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          place['name'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: _textDark,
                                          ),
                                        ),
                                      ),
                                      Icon(icon,
                                          size: 18,
                                          color:
                                              color.withOpacity(0.6)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 12),

                    // ── Action buttons ────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: BorderSide(
                                  color:
                                      Colors.redAccent.withOpacity(0.4)),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                            ),
                            onPressed: onDelete,
                            icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18),
                            label: const Text('Delete',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF4F5BD5),
                                  Color(0xFF7B2FBE)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: _primary.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                              ),
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit_outlined,
                                  color: Colors.white, size: 18),
                              label: const Text(
                                'Edit Trip',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
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
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SMALL SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF9090A8),
          letterSpacing: 1.2,
        ),
      );
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SummaryChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTrips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: Color(0xFFF0F4FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.luggage_rounded,
                size: 42, color: Color(0xFF4F5BD5)),
          ),
          const SizedBox(height: 20),
          const Text(
            'No trips yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Start building your first adventure!',
            style: TextStyle(fontSize: 14, color: Color(0xFF9090A8)),
          ),
        ],
      ),
    );
  }
}