// trip_builder_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'my_trips_screen.dart';
import 'home_screen.dart';
import '../tourist_place_loader.dart';

class TripBuilderScreen extends StatefulWidget {
  final String destination;
  final List<Map<String, String>> suggestedPlaces;

  const TripBuilderScreen({
    super.key,
    required this.destination,
    required this.suggestedPlaces,
  });

  @override
  State<TripBuilderScreen> createState() => _TripBuilderScreenState();
}

class _TripBuilderScreenState extends State<TripBuilderScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, String>> selectedPlaces = [];
  List<Map<String, String>> filteredPlaces = [];
  List<Map<String, String>> _allPlaces = []; // full CSV dataset
  bool _isLoadingPlaces = true;

  final TextEditingController _tripNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isSaving = false;
  int _currentStep = 0; // 0 = name, 1 = places, 2 = review

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Colour palette used throughout
  static const Color _primary   = Color(0xFF4F5BD5);
 // static const Color _accent    = Color(0xFF7B2FBE);
  static const Color _surface   = Color(0xFFF8F9FE);
 // static const Color _cardBg    = Colors.white;
  static const Color _textDark  = Color(0xFF1A1A2E);
  static const Color _textMuted = Color(0xFF9090A8);

  // Icon palette for place tiles (cycles through these)
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

  @override
  void initState() {
    super.initState();
    filteredPlaces = List.from(widget.suggestedPlaces);
    _searchController.addListener(_filterPlaces);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();

    // Load the full place list from CSV so the search bar can find any place
    _loadAllPlaces();
  }

  Future<void> _loadAllPlaces() async {
    try {
      final places = await TouristPlaceLoader.loadFromCsv();
      // Merge CSV places with suggestedPlaces — CSV wins on duplicates
      final csvMaps = places
          .map((p) => {'name': p.place, 'image': ''})
          .toList();

      // Build a combined list: suggestedPlaces first (they may carry extra data),
      // then any additional CSV places not already in the list
      final suggestedNames =
          widget.suggestedPlaces.map((p) => p['name']).toSet();
      final extra = csvMaps
          .where((p) => !suggestedNames.contains(p['name']))
          .toList();

      setState(() {
        _allPlaces = [...widget.suggestedPlaces, ...extra];
        filteredPlaces = List.from(_allPlaces);
        _isLoadingPlaces = false;
      });
    } catch (_) {
      // Fallback: use suggestedPlaces only
      setState(() {
        _allPlaces = List.from(widget.suggestedPlaces);
        filteredPlaces = List.from(widget.suggestedPlaces);
        _isLoadingPlaces = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tripNameController.dispose();
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _filterPlaces() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      filteredPlaces = query.isEmpty
          ? List.from(_allPlaces)
          : _allPlaces
              .where((p) => p['name']!.toLowerCase().contains(query))
              .toList();
    });
  }

  void _togglePlace(Map<String, String> place) {
    setState(() {
      final idx = selectedPlaces.indexWhere((p) => p['name'] == place['name']);
      if (idx >= 0) {
        selectedPlaces.removeAt(idx);
      } else {
        selectedPlaces.add(place);
      }
    });
  }

  void _goToStep(int step) {
    _fadeController.reset();
    setState(() => _currentStep = step);
    _fadeController.forward();
  }

  Future<void> _saveTrip() async {
    if (_tripNameController.text.trim().isEmpty) {
      _showSnack('Please enter a trip name', Colors.redAccent);
      _goToStep(0);
      return;
    }
    if (selectedPlaces.isEmpty) {
      _showSnack('Please select at least one place', Colors.redAccent);
      _goToStep(1);
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      _showSnack('You must be logged in to save a trip', Colors.orange);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('trips')
          .doc(_tripNameController.text.trim())
          .set({
        'tripName'   : _tripNameController.text.trim(),
        'destination': widget.destination,
        'places'     : selectedPlaces,
        'notes'      : _notesController.text.trim(),
        'createdAt'  : FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSnack('Trip saved successfully!', const Color(0xFF00C896));
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MyTripsScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) _showSnack('Error saving trip: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _StepIndicator(currentStep: _currentStep, onTap: _goToStep),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildStep(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  AppBar _buildAppBar() {
    final titles = ['Name Your Trip', 'Choose Places', 'Review & Save'];
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            size: 18, color: _textDark),
        onPressed: () {
          if (_currentStep > 0) {
            _goToStep(_currentStep - 1);
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titles[_currentStep],
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _textDark,
              letterSpacing: -0.3,
            ),
          ),
          if (widget.destination.isNotEmpty)
            Text(
              widget.destination,
              style: const TextStyle(
                fontSize: 12,
                color: _primary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      actions: [
        if (_currentStep == 1 && selectedPlaces.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${selectedPlaces.length} selected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _buildStepName();
      case 1:
        return _buildStepPlaces();
      case 2:
        return _buildStepReview();
      default:
        return const SizedBox();
    }
  }

  // ─── Step 0 : Name ────────────────────────────────────────────────────────

  Widget _buildStepName() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero illustration
          Center(
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F5BD5), Color(0xFF7B2FBE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.luggage_rounded,
                  size: 52, color: Colors.white),
            ),
          ),
          const SizedBox(height: 28),

          const Text(
            'What should we call\nyour trip?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _textDark,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Give your adventure a memorable name.',
            style: TextStyle(fontSize: 14, color: _textMuted),
          ),
          const SizedBox(height: 32),

          // Trip name field
          const _FieldLabel(label: 'Trip Name'),
          const SizedBox(height: 8),
          _StyledTextField(
            controller: _tripNameController,
            hint: 'e.g. Ooty Getaway 2025',
            icon: Icons.edit_outlined,
            maxLines: 1,
          ),
          const SizedBox(height: 20),

          // Notes field
          const _FieldLabel(label: 'Notes (optional)'),
          const SizedBox(height: 8),
          _StyledTextField(
            controller: _notesController,
            hint: 'Add any notes, budget, travel dates...',
            icon: Icons.notes_outlined,
            maxLines: 4,
          ),
          const SizedBox(height: 32),

          // Info chip row
          Row(
            children: [
              _InfoChip(
                icon: Icons.place_outlined,
                label: '${widget.suggestedPlaces.length} places ready',
                color: _primary,
              ),
              const SizedBox(width: 10),
              _InfoChip(
                icon: Icons.map_outlined,
                label: widget.destination.isEmpty
                    ? 'Tamil Nadu'
                    : widget.destination,
                color: const Color(0xFF00C896),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Step 1 : Places ──────────────────────────────────────────────────────

  Widget _buildStepPlaces() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF1A1A2E),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Search any place or district...',
              hintStyle: const TextStyle(
                color: Color(0xFFAAABB5),
                fontSize: 14,
              ),
              prefixIcon: const Icon(Icons.search,
                  color: Color(0xFF4F5BD5), size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0F0F5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 15, color: Color(0xFF666680)),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _filterPlaces();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFEEEFF5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFEEEFF5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFF4F5BD5), width: 1.5),
              ),
            ),
          ),
        ),

        // Count row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              if (_isLoadingPlaces)
                const Text(
                  'Loading places...',
                  style: TextStyle(
                    fontSize: 13,
                    color: _textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                Text(
                  '${filteredPlaces.length} places',
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const Spacer(),
              if (selectedPlaces.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => selectedPlaces.clear()),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Clear all',
                      style: TextStyle(fontSize: 13)),
                ),
            ],
          ),
        ),

        // Place list
        Expanded(
          child: _isLoadingPlaces
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4F5BD5),
                    strokeWidth: 2.5,
                  ),
                )
              : filteredPlaces.isEmpty
                  ? _EmptyPlaces()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filteredPlaces.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final place = filteredPlaces[index];
                        final isSelected = selectedPlaces
                            .any((p) => p['name'] == place['name']);
                        final colorIdx = index % _tileColors.length;

                        return _PlaceTile(
                          place: place,
                          isSelected: isSelected,
                          color: _tileColors[colorIdx],
                          icon: _tileIcons[colorIdx],
                          order: isSelected
                              ? selectedPlaces.indexWhere(
                                      (p) => p['name'] == place['name']) +
                                  1
                              : null,
                          onTap: () => _togglePlace(place),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // ─── Step 2 : Review ─────────────────────────────────────────────────────

  Widget _buildStepReview() {
    final tripName = _tripNameController.text.trim();
    final notes    = _notesController.text.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F5BD5), Color(0xFF7B2FBE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.luggage_rounded,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tripName.isEmpty ? 'Unnamed Trip' : tripName,
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
                if (widget.destination.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        widget.destination,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    _SummaryChip(
                      label: '${selectedPlaces.length} Places',
                      icon: Icons.place_outlined,
                    ),
                    const SizedBox(width: 10),
                    const _SummaryChip(
                      label: 'Custom Trip',
                      icon: Icons.auto_awesome,
                    ),
                  ],
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notes,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notes,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Selected places list
          Row(
            children: [
              const Text(
                'YOUR ITINERARY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _textMuted,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _goToStep(1),
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 13,
                    color: _primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (selectedPlaces.isEmpty)
            _EmptyItinerary(onAdd: () => _goToStep(1))
          else
            ...selectedPlaces.asMap().entries.map((entry) {
              final idx   = entry.key;
              final place = entry.value;
              final color = _tileColors[idx % _tileColors.length];
              final icon  = _tileIcons[idx % _tileIcons.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ItineraryRow(
                  order: idx + 1,
                  name: place['name'] ?? '',
                  color: color,
                  icon: icon,
                  isLast: idx == selectedPlaces.length - 1,
                ),
              );
            }),

          const SizedBox(height: 32),

          // Validation warnings
          if (tripName.isEmpty)
            _WarningBanner(
              message: 'Trip name is missing',
              onFix: () => _goToStep(0),
            ),
          if (selectedPlaces.isEmpty)
            _WarningBanner(
              message: 'No places selected',
              onFix: () => _goToStep(1),
            ),
        ],
      ),
    );
  }

  // ─── Bottom navigation bar ────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final isLastStep = _currentStep == 2;
   // final canProceed = _currentStep < 1 || selectedPlaces.isNotEmpty;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => _goToStep(_currentStep - 1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textDark,
                  side: const BorderSide(color: Color(0xFFDDDEEA)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Back',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _GradientButton(
              label: isLastStep ? 'Save Trip' : 'Continue',
              isLoading: _isSaving,
              onPressed: isLastStep
                  ? _saveTrip
                  : () => _goToStep(_currentStep + 1),
              icon: isLastStep ? Icons.check_rounded : Icons.arrow_forward_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final ValueChanged<int> onTap;

  const _StepIndicator({required this.currentStep, required this.onTap});

  static const _labels = ['Name', 'Places', 'Review'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: List.generate(_labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIndex = i ~/ 2;
            final filled = currentStep > stepIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: filled
                    ? const Color(0xFF4F5BD5)
                    : const Color(0xFFE8E9F5),
              ),
            );
          }
          final step = i ~/ 2;
          final isActive   = step == currentStep;
          final isComplete = step < currentStep;
          return GestureDetector(
            onTap: () => onTap(step),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isComplete
                        ? const Color(0xFF4F5BD5)
                        : isActive
                            ? const Color(0xFF4F5BD5)
                            : const Color(0xFFF0F0FA),
                    shape: BoxShape.circle,
                    border: isActive
                        ? Border.all(
                            color: const Color(0xFF4F5BD5).withValues(alpha: 0.3),
                            width: 4)
                        : null,
                  ),
                  child: Center(
                    child: isComplete
                        ? const Icon(Icons.check,
                            size: 16, color: Colors.white)
                        : Text(
                            '${step + 1}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFFAAABBE),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _labels[step],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive || isComplete
                        ? const Color(0xFF4F5BD5)
                        : const Color(0xFFAAABBE),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  final Map<String, String> place;
  final bool isSelected;
  final Color color;
  final IconData icon;
  final int? order;
  final VoidCallback onTap;

  const _PlaceTile({
    required this.place,
    required this.isSelected,
    required this.color,
    required this.icon,
    required this.onTap,
    this.order,
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
                ? color.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon / order badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color
                        : color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: isSelected && order != null
                        ? Text(
                            '$order',
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
                const SizedBox(width: 14),

                Expanded(
                  child: Text(
                    place['name'] ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFF1A1A2E)
                          : const Color(0xFF3A3A55),
                    ),
                  ),
                ),

                // Check
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isSelected
                      ? Icon(Icons.check_circle_rounded,
                          key: const ValueKey('check'),
                          color: color,
                          size: 22)
                      : const Icon(Icons.add_circle_outline_rounded,
                          key: ValueKey('add'),
                          color: Color(0xFFCCCCDD),
                          size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItineraryRow extends StatelessWidget {
  final int order;
  final String name;
  final Color color;
  final IconData icon;
  final bool isLast;

  const _ItineraryRow({
    required this.order,
    required this.name,
    required this.color,
    required this.icon,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$order',
                  style: TextStyle(
                    fontSize: 14,
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
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Icon(icon, size: 18, color: color.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A2E),
        ),
      );
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF1A1A2E),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFFAAABB5),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF4F5BD5), size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEEEFF5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEEEFF5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF4F5BD5), width: 1.5),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  final IconData icon;

  const _GradientButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F5BD5), Color(0xFF7B2FBE)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F5BD5).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(icon, color: Colors.white, size: 18),
                  ],
                ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
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
        color: Colors.white.withValues(alpha: 0.2),
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

class _WarningBanner extends StatelessWidget {
  final String message;
  final VoidCallback onFix;

  const _WarningBanner({required this.message, required this.onFix});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: onFix,
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Fix →',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlaces extends StatelessWidget {
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
              color: Color(0xFFF0F4FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded,
                size: 34, color: Color(0xFF4F5BD5)),
          ),
          const SizedBox(height: 14),
          const Text(
            'No places match',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try a different search term',
            style: TextStyle(fontSize: 13, color: Color(0xFF9090A8)),
          ),
        ],
      ),
    );
  }
}

class _EmptyItinerary extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyItinerary({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF4F5BD5).withValues(alpha: 0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.add_location_alt_outlined,
                color: Color(0xFF4F5BD5), size: 24),
            SizedBox(width: 14),
            Text(
              'Tap to add places to your itinerary',
              style: TextStyle(
                color: Color(0xFF4F5BD5),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}