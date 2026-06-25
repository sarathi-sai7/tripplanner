import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../tourist_place_loader.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'trip_builder_screen.dart';
import 'memories_screen.dart';
import 'favorites_screen.dart';
import 'booking_screen.dart';
import 'login_screen.dart';
import 'my_trips_screen.dart';
import 'place_search_delegate.dart';
import 'profile_screen.dart';
import 'location_screen.dart';
import 'expense_tracker.dart';
import 'ai_assistant.dart';
import 'settings_screen.dart';

// ─── Design tokens ───────────────────────────────────────────────────────────

class AppColors {
  static const primary    = Color(0xFF1A6B5A);   // deep teal
  static const accent     = Color(0xFF2FD8A4);   // mint accent
  static const surface    = Color(0xFFF0F4F3);
  static const card       = Colors.white;
  static const textDark   = Color(0xFF0D1F1B);
  static const textMuted  = Color(0xFF6B8580);
  static const danger     = Color(0xFFE05252);

  static const gradient = LinearGradient(
    colors: [primary, Color(0xFF267A65)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];
}

class AppText {
  // headline / display
  static const display = TextStyle(
    fontFamily: 'Georgia',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static const headline = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    letterSpacing: -0.3,
  );

  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    letterSpacing: 0.1,
  );

  static const caption = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );
}

// ─── HomeScreen ───────────────────────────────────────────────────────────────

// Top-level helper so it's accessible from any widget in this file
Route<T> _fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, a, __) => page,
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    );

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {

  int _selectedIndex = 0;

  late AnimationController _entryController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _pulseAnim;

  Map<String, dynamic>? _latestBooking;

  final List<Widget> _navScreens = const [
    SizedBox(),
    BookingScreen(),
    MemoriesScreen(),
    LocationScreen(),
  ];

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── navigation ─────────────────────────────────────────────────────────────

  void _onNavTap(int index) async {
    setState(() => _selectedIndex = index);
    if (index == 0) return;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      _fadeRoute(_navScreens[index]),
    );

    if (result?['bookingConfirmed'] == true) {
      setState(() => _latestBooking = result!['booking']);
    }
  }

  Future<void> _openTrip({Map<String, dynamic>? existingTrip}) async {
    final trip = await Navigator.push(
      context,
      _fadeRoute(TripBuilderScreen(
        destination: existingTrip?['destination'] ?? 'Default',
        suggestedPlaces: existingTrip?['places'] ?? [],
      )),
    );

    if (trip != null && mounted) {
      _showToast("Trip saved! 🗺️");
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) _showToast("Logged out successfully");
  }

  // ── helpers ────────────────────────────────────────────────────────────────



  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── profile menu ───────────────────────────────────────────────────────────

  void _showProfileMenu(BuildContext ctx, Offset position, String email) async {
    final overlay = Overlay.of(ctx).context.findRenderObject() as RenderBox;

    final result = await showMenu<String>(
      context: ctx,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + 8,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      color: Colors.transparent,
      elevation: 0,
      items: [
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _ProfileMenuCard(email: email),
        ),
      ],
    );

    if (!mounted) return;

    switch (result) {
      case 'Logout':
        await _logout();
        break;
      case 'Profile':
        Navigator.push(
  ctx,
  _fadeRoute(
    ProfileScreen(email: email),
  ),
).then((_) {
  if (ctx.mounted) {
    (ctx as Element).markNeedsBuild();
  }
});
        break;
      case 'Assistant':
        Navigator.push(ctx, _fadeRoute(const AIAssistant()));
        break;
      case 'Settings':
        Navigator.push(ctx, _fadeRoute(SettingsScreen(email: email)));
        break;
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(
              onSearch: _handleSearch,
              onNavTap: _onNavTap,
              onProfileTap: _showProfileMenu,
              pulseAnim: _pulseAnim,
            ),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _HomeBody(
                    latestBooking: _latestBooking,
                    onOpenTrip: _openTrip,
                    onNavTap: _onNavTap,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Future<void> _handleSearch() async {
    final allPlaces = await TouristPlaceLoader.loadFromCsv();
    if (allPlaces.isNotEmpty && mounted) {
      await showSearch<String>(
        context: context,
        delegate: PlaceSearchDelegate(allPlaces),
      );
    }
  }
}

// ─── AppBar ───────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.onSearch,
    required this.onNavTap,
    required this.onProfileTap,
    required this.pulseAnim,
  });

  final VoidCallback onSearch;
  final ValueChanged<int> onNavTap;
  final Function(BuildContext, Offset, String) onProfileTap;
  final Animation<double> pulseAnim;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEDF0EF), width: 1)),
      ),
      child: Row(
        children: [
          // Logo pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.flight_rounded, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  "Voyager",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Pulse dot + greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ScaleTransition(
                      scale: pulseAnim,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2FD8A4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text("Ready to explore", style: AppText.caption),
                  ],
                ),
                const SizedBox(height: 2),
                const Text("Good evening 👋", style: AppText.label),
              ],
            ),
          ),

          // Search button
          _IconBtn(
            icon: Icons.search_rounded,
            onTap: onSearch,
          ),

          const SizedBox(width: 8),

          // Avatar / Login
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (ctx, snap) {
              final user = snap.data;
              if (user == null) {
                return _LoginButton(onTap: () {
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                });
              }
              return GestureDetector(
                onTapDown: (d) =>
                    onProfileTap(ctx, d.globalPosition, user.email ?? ""),
                child: const _Avatar(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: AppColors.gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          "Login",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
class _Avatar extends StatefulWidget {
  const _Avatar();

  @override
  State<_Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<_Avatar> {

  String? imagePath;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final prefs =
        await SharedPreferences.getInstance();

    setState(() {
      imagePath =
          prefs.getString("profile_image");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.gradient,

        boxShadow: [
          BoxShadow(
            color: AppColors.primary
                .withOpacity(0.3),

            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      padding: const EdgeInsets.all(2.5),

      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white,

        child: CircleAvatar(
          radius: 17,

          backgroundImage:
              imagePath != null
                  ? FileImage(
                      File(imagePath!),
                    )
                  : const AssetImage(
                          'assets/boy.png')
                      as ImageProvider,
        ),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.latestBooking,
    required this.onOpenTrip,
    required this.onNavTap,
  });

  final Map<String, dynamic>? latestBooking;
  final Function({Map<String, dynamic>? existingTrip}) onOpenTrip;
  final ValueChanged<int> onNavTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _HeroBanner(latestBooking: latestBooking),
          ),

          const SizedBox(height: 30),

          // Quick access
          _SectionHeader(
            title: "Quick Access",
            trailing: null,
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _QuickCard(
                  label: "Package",
                  icon: Icons.card_travel_rounded,
                  color: const Color(0xFFFF7043),
                  onTap: () => onOpenTrip(),
                ),
                _QuickCard(
                  label: "Bookings",
                  icon: Icons.confirmation_number_rounded,
                  color: const Color(0xFF43A047),
                  onTap: () => onNavTap(1),
                ),
                _QuickCard(
                  label: "Memories",
                  icon: Icons.photo_album_rounded,
                  color: const Color(0xFF7E57C2),
                  onTap: () => onNavTap(2),
                ),
                _QuickCard(
                  label: "Favorites",
                  icon: Icons.favorite_rounded,
                  color: const Color(0xFFE53935),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                    );
                  },
                ),
                _QuickCard(
                  label: "My Trips",
                  icon: Icons.map_rounded,
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyTripsScreen()),
                    );
                  },
                ),
                _QuickCard(
                  label: "Expense",
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFF1E88E5),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ExpenseScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Popular destinations
          _SectionHeader(
            title: "Popular Destinations",
            trailing: "See all",
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 190,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: const [
                _DestCard(
                  name: "Athirappilly",
                  tag: "Waterfall",
                  asset: "assets/fall.jpg",
                ),
                _DestCard(
                  name: "Vagamon",
                  tag: "Hill Station",
                  asset: "assets/pineforest.jpg",
                ),
                _DestCard(
                  name: "Kochi Port",
                  tag: "Heritage",
                  asset: "assets/fort.jpg",
                ),
                _DestCard(
                  name: "Pathanamthitta",
                  tag: "Wildlife",
                  asset: "assets/animal.jpg",
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // AI Assistant card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _AIAssistantBanner(),
          ),

          const SizedBox(height: 30),

          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _Footer(),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── Hero Banner ──────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.latestBooking});
  final Map<String, dynamic>? latestBooking;

  @override
  Widget build(BuildContext context) {
    final hasBooking = latestBooking != null;

    return Container(
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              hasBooking ? "assets/train_banner.jpg" : "assets/banner.jpg",
              fit: BoxFit.cover,
            ),
            // gradient scrim
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.08),
                    Colors.black.withOpacity(0.65),
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
            // content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!hasBooking)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.accent.withOpacity(0.5),
                            width: 1),
                      ),
                      child: const Text(
                        "✦ Featured",
                        style: TextStyle(
                          color: Color(0xFF2FD8A4),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    hasBooking
                        ? "${latestBooking!['title']}"
                        : "Discover Your\nNext Adventure",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (hasBooking) ...[
                    const SizedBox(height: 4),
                    Text(
                      "${latestBooking!['subtitle']}",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: Color(0xFF2FD8A4), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "Kerala, India  •  Trending now",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.trailing,
    required this.padding,
  });
  final String title;
  final String? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Text(title, style: AppText.headline),
          const Spacer(),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Quick Card ───────────────────────────────────────────────────────────────

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 78,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withOpacity(0.15), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Destination Card ─────────────────────────────────────────────────────────

class _DestCard extends StatelessWidget {
  const _DestCard({
    required this.name,
    required this.tag,
    required this.asset,
  });
  final String name;
  final String tag;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(asset, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.72),
                  ],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: Color(0xFF2FD8A4),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            // Bookmark icon top-right
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bookmark_border_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── AI Assistant Banner ──────────────────────────────────────────────────────

class _AIAssistantBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AIAssistant()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.gradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.travel_explore_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Voyage Assistant",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Ask me anything about your next trip",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.flight_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                "Travel Guide App",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Plan trips, save favorite places, and explore new adventures around the world.",
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.email_rounded,
                  size: 15, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                "support@travelguide.com",
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.selectedIndex,
    required this.onTap,
  });
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, Icons.home_outlined, "Home"),
      (Icons.confirmation_number_rounded,
          Icons.confirmation_number_outlined, "Bookings"),
      (Icons.photo_album_rounded, Icons.photo_album_outlined, "Memories"),
      (Icons.location_on_rounded, Icons.location_on_outlined, "Location"),
    ];

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final (activeIcon, inactiveIcon, label) = items[i];
          final isSelected = i == selectedIndex;

          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 14 : 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? activeIcon : inactiveIcon,
                    color:
                        isSelected ? AppColors.primary : AppColors.textMuted,
                    size: 22,
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Profile Menu Card ────────────────────────────────────────────────────────

class _ProfileMenuCard extends StatefulWidget {
  const _ProfileMenuCard({
    required this.email,
  });

  final String email;

  @override
  State<_ProfileMenuCard> createState() =>
      _ProfileMenuCardState();
}

class _ProfileMenuCardState
    extends State<_ProfileMenuCard> {

  String? imagePath;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final prefs =
        await SharedPreferences
            .getInstance();

    setState(() {
      imagePath =
          prefs.getString(
        "profile_image",
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
                24),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.1),

            blurRadius: 24,

            offset:
                const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          // HEADER
          Container(
            padding:
                const EdgeInsets.all(
                    18),

            decoration:
                const BoxDecoration(
              gradient:
                  AppColors.gradient,

              borderRadius:
                  BorderRadius
                      .vertical(
                top:
                    Radius.circular(
                        24),
              ),
            ),

            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets
                          .all(2),

                  decoration:
                      BoxDecoration(
                    shape:
                        BoxShape.circle,

                    border:
                        Border.all(
                      color: Colors
                          .white
                          .withOpacity(
                              0.5),

                      width: 2,
                    ),
                  ),

                  child:
                      CircleAvatar(
                    radius: 22,

                    backgroundImage:
                        imagePath !=
                                null
                            ? FileImage(
                                File(
                                  imagePath!,
                                ),
                              )
                            : const AssetImage(
                                    'assets/boy.png')
                                as ImageProvider,
                  ),
                ),

                const SizedBox(
                    width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      const Text(
                        "Welcome Back 👋",

                        style:
                            TextStyle(
                          color: Colors
                              .white,

                          fontSize: 14,

                          fontWeight:
                              FontWeight
                                  .w700,
                        ),
                      ),

                      const SizedBox(
                          height: 3),

                      Text(
                        widget.email,

                        overflow:
                            TextOverflow
                                .ellipsis,

                        style:
                            TextStyle(
                          color: Colors
                              .white
                              .withOpacity(
                                  0.85),

                          fontSize:
                              11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          _menuTile(
            icon: Icons
                .travel_explore_rounded,

            label:
                "Voyage Assistant",

            value:
                'Assistant',
          ),

          _menuTile(
            icon:
                Icons.person_rounded,

            label: "Profile",

            value: 'Profile',
          ),

          _menuTile(
            icon: Icons
                .settings_rounded,

            label: "Settings",

            value:
                'Settings',
          ),

          const Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal: 16,
            ),

            child: Divider(
              height: 1,
              color:
                  Color(0xFFF0F0F0),
            ),
          ),

          _menuTile(
            icon:
                Icons.logout_rounded,

            label: "Logout",

            value:
                'Logout',

            isLogout: true,
          ),

          const SizedBox(
              height: 8),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required String value,
    bool isLogout = false,
  }) {
    final color = isLogout
        ? AppColors.danger
        : AppColors.primary;

    return Builder(
      builder: (ctx) {
        return InkWell(
          onTap: () {
            Navigator.of(
              ctx,
              rootNavigator: true,
            ).pop(value);
          },

          borderRadius:
              BorderRadius.circular(
                  12),

          child: Padding(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 16,
              vertical: 13,
            ),

            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets
                          .all(8),

                  decoration:
                      BoxDecoration(
                    color: color
                        .withOpacity(
                            0.1),

                    borderRadius:
                        BorderRadius
                            .circular(
                                10),
                  ),

                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),

                const SizedBox(
                    width: 12),

                Expanded(
                  child: Text(
                    label,

                    style:
                        TextStyle(
                      fontSize: 14,

                      fontWeight:
                          FontWeight
                              .w600,

                      color: isLogout
                          ? AppColors
                              .danger
                          : AppColors
                              .textDark,
                    ),
                  ),
                ),

                Icon(
                  Icons
                      .chevron_right_rounded,

                  size: 16,

                  color: AppColors
                      .textMuted,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}