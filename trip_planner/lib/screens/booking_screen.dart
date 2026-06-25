import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ─── API config ──────────────────────────────────────────────────────────────
String get _kRapidApiKey => dotenv.env['RAPID_API_KEY'] ?? '';
const String _kRapidApiHost = 'irctc1.p.rapidapi.com';

// ─── Design tokens ───────────────────────────────────────────────────────────
class BK {
  // Palette
  static const bg = Color(0xFFF4F7FB);
  static const surface   = Color(0xFFFFFFFF); 
  static const card      = Color(0xFFFFFFFF);
  static const border    = Color(0xFFE6ECF2);
 static const textPri   = Color(0xFF1E293B);
static const textSec   = Color(0xFF64748B);
static const textMuted = Color(0xFF94A3B8);

  // Tab accent palette
  static const List<_TabMeta> tabs = [
    _TabMeta('Train', Icons.train_rounded,            Color(0xFF6C63FF), Color(0xFF9D97FF)),
    _TabMeta('Bus',   Icons.directions_bus_rounded,   Color(0xFFFF5C7A), Color(0xFFFF8FA3)),
    _TabMeta('Cab',   Icons.local_taxi_rounded,       Color(0xFF00C9A7), Color(0xFF00ECC5)),
    _TabMeta('Bike',  Icons.electric_moped_rounded,   Color(0xFFFFB400), Color(0xFFFFD260)),
  ];

  static const cardShadow = [
    BoxShadow(color: Color(0x28000000), blurRadius: 20, offset: Offset(0, 8)),
  ];

  static LinearGradient tabGrad(int i) => LinearGradient(
        colors: [tabs[i].color, tabs[i].light],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

class _TabMeta {
  final String label;
  final IconData icon;
  final Color color;
  final Color light;
  const _TabMeta(this.label, this.icon, this.color, this.light);
}

// ─── BookingScreen ────────────────────────────────────────────────────────────
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with TickerProviderStateMixin {
  late TabController _tab;
  late AnimationController _headerAnim;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this)
      ..addListener(() => setState(() {}));

    _headerAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _headerFade  = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerAnim, curve: Curves.easeOutCubic));
    _headerAnim.forward();
  }

  @override
  void dispose() {
    _tab.dispose();
    _headerAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meta = BK.tabs[_tab.index];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: BK.bg,
        body: Column(children: [
          // ── Dynamic header ──────────────────────────────────────────────
          SlideTransition(
            position: _headerSlide,
            child: FadeTransition(
              opacity: _headerFade,
              child: _BookingHeader(
                meta: meta,
                tabIndex: _tab.index,
                tabController: _tab,
                onBack: () => Navigator.pop(context),
              ),
            ),
          ),

          // ── Tab content ─────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tab,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _TrainTab(meta: BK.tabs[0]),
                _ExternalTab(
                  meta: BK.tabs[1],
                  description: "10,000+ operators, AC & sleeper, instant e-ticket.",
                  buildUrl: (f, t, d) =>
                      'https://www.redbus.in/bus-tickets/${_slug(f)}-to-${_slug(t)}?onward=${_redBusDate(d)}',
                  providers: const [
                    _Provider('RedBus',  'https://www.redbus.in',   Icons.confirmation_number_outlined, Color(0xFFFF5C7A)),
                    _Provider('AbhiBus', 'https://www.abhibus.com', Icons.directions_bus_outlined,       Color(0xFFFF9F1C)),
                    _Provider('KSRTC',   'https://ksrtcbus.in',     Icons.airport_shuttle_outlined,      Color(0xFF00C9A7)),
                  ],
                ),
                _ExternalTab(
                  meta: BK.tabs[2],
                  description: "Real-time tracking, live ETAs, cashless rides.",
                  buildUrl: (f, t, d) => 'https://book.olacabs.com/?pickup=$f&drop=$t',
                  providers: const [
                    _Provider('Ola',     'https://book.olacabs.com',          Icons.local_taxi_rounded,     Color(0xFF00C9A7)),
                    _Provider('Uber',    'https://m.uber.com/ul/',            Icons.local_taxi_outlined,    Color(0xFFF0F1FF)),
                    _Provider('InDrive', 'https://indrive.com/en/cities/in', Icons.directions_car_outlined, Color(0xFF6C63FF)),
                  ],
                ),
                _ExternalTab(
                  meta: BK.tabs[3],
                  description: "Beat traffic, save money — the quickest last mile.",
                  buildUrl: (f, t, d) => 'https://rapido.bike/',
                  providers: const [
                    _Provider('Rapido',    'https://rapido.bike',                          Icons.electric_moped_rounded, Color(0xFFFFB400)),
                    _Provider('Ola Bike',  'https://book.olacabs.com/?serviceType=bike',  Icons.pedal_bike_outlined,    Color(0xFF00C9A7)),
                    _Provider('Uber Moto', 'https://m.uber.com/ul/',                      Icons.two_wheeler_outlined,   Color(0xFFF0F1FF)),
                  ],
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Booking Header ───────────────────────────────────────────────────────────
class _BookingHeader extends StatelessWidget {
  const _BookingHeader({
    required this.meta,
    required this.tabIndex,
    required this.tabController,
    required this.onBack,
  });
  final _TabMeta meta;
  final int tabIndex;
  final TabController tabController;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
     decoration: const BoxDecoration(
  gradient: LinearGradient(
    colors: [
      Color(0xFF00695C),
      Color(0xFF26A69A),
    ],

    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
),
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 16, 0),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: BK.textSec),
                onPressed: onBack,
              ),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  'Book ${meta.label}',
                  key: ValueKey(meta.label),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: BK.textPri,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const Spacer(),
              // Notification bell
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: BK.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BK.border),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: BK.textSec, size: 18),
              ),
            ]),
          ),

          const SizedBox(height: 14),

          // Pill tab bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(
              height: 52,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: BK.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BK.border),
              ),
              child: TabBar(
                controller: tabController,
                indicator: BoxDecoration(
                  gradient: BK.tabGrad(tabIndex),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: BK.tabs[tabIndex].color.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: BK.textMuted,
                labelStyle: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600),
                tabs: BK.tabs.map((t) => Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(t.icon, size: 16),
                      const SizedBox(height: 2),
                      Text(t.label),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Train Tab ────────────────────────────────────────────────────────────────
class _TrainTab extends StatefulWidget {
  final _TabMeta meta;
  const _TrainTab({required this.meta});
  @override
  State<_TrainTab> createState() => _TrainTabState();
}

class _TrainTabState extends State<_TrainTab> {
  final _fromCtrl  = TextEditingController(text: 'Chennai Central (MAS)');
  final _toCtrl    = TextEditingController();
  final _dateCtrl  = TextEditingController();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _paxCtrl   = TextEditingController(text: '1');

  List<Map<String, dynamic>> _fromSug = [];
  List<Map<String, dynamic>> _toSug   = [];
  String _fromCode = 'MAS';
  String _toCode   = '';

  Timer? _fromTimer, _toTimer;

  List<Map<String, dynamic>> _trains   = [];
  bool    _searching = false;
  bool    _saving    = false;
  String? _error;
  DateTime? _date;

  String _quota    = 'GN';  // NEW: quota selector
  String _classKey = 'SL';  // NEW: class selector
  bool   _flexible = false; // NEW: flexible date toggle

  static const _quotas   = ['GN', 'TQ', 'LD', 'HP', 'SS', 'YU'];
  static const _classes  = ['SL', '3A', '2A', '1A', 'CC', '2S', 'FC', 'EC'];

  // ── station search ─────────────────────────────────────────────────────────
  Future<void> _searchStations(String q, bool isFrom) async {
    if (q.length < 2) {
      setState(() => isFrom ? _fromSug = [] : _toSug = []);
      return;
    }
    try {
      final uri = Uri.https(_kRapidApiHost, '/api/v1/searchStation', {'query': q});
      final res = await http.get(uri, headers: {
        'x-rapidapi-key' : _kRapidApiKey,
        'x-rapidapi-host': _kRapidApiHost,
      }).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        List<dynamic> raw = [];
        if (body['data'] is List)        raw = body['data'];
        else if (body['result'] is List) raw = body['result'];
        // ignore: unnecessary_cast
        else if (body is List)           raw = body as List;
        final list = raw.map<Map<String, dynamic>>((s) {
          final name = (s['station_name'] ?? s['name'] ?? s['stationName'] ?? '').toString();
          final code = (s['station_code'] ?? s['code'] ?? s['stationCode'] ?? '').toString();
          return {'name': name, 'code': code};
        }).where((s) => s['name']!.isNotEmpty && s['code']!.isNotEmpty).toList();
        setState(() => isFrom ? _fromSug = list : _toSug = list);
      }
    } catch (_) {}
  }

  // ── train search ───────────────────────────────────────────────────────────
  Future<void> _searchTrains() async {
    if (_toCode.isEmpty) {
      setState(() => _error = 'Please select a destination station from the suggestions.');
      return;
    }
    if (_date == null) {
      setState(() => _error = 'Please pick a travel date.');
      return;
    }
    setState(() { _searching = true; _error = null; _trains = []; });

    final dateStr = DateFormat('yyyyMMdd').format(_date!);
    try {
      final uri = Uri.https(_kRapidApiHost, '/api/v3/trainBetweenStations', {
        'fromStationCode': _fromCode,
        'toStationCode'  : _toCode,
        'dateOfJourney'  : dateStr,
      });
      final res = await http.get(uri, headers: {
        'x-rapidapi-key' : _kRapidApiKey,
        'x-rapidapi-host': _kRapidApiHost,
      }).timeout(const Duration(seconds: 15));
      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        List<dynamic> raw = [];
        if (body['data'] is List)        raw = body['data'];
        else if (body['result'] is List) raw = body['result'];
        // ignore: unnecessary_cast
        else if (body is List)           raw = body as List;

        setState(() {
          _trains = raw.map<Map<String, dynamic>>((t) => {
            'number'   : (t['train_number']  ?? t['trainNumber']  ?? t['number']   ?? '').toString(),
            'name'     : (t['train_name']    ?? t['trainName']    ?? t['name']     ?? 'Unknown Train').toString(),
            'departure': (t['from_std']      ?? t['departureTime'] ?? t['dep_time'] ?? '--').toString(),
            'arrival'  : (t['to_std']        ?? t['arrivalTime']  ?? t['arr_time'] ?? '--').toString(),
            'duration' : (t['duration']      ?? t['travel_time']  ?? '--').toString(),
            'classes'  : (t['class_type']    ?? t['classes']      ?? []) as List,
            'days'     : (t['train_base']?['avlDays'] ?? t['run_days'] ?? []) as List,
          }).toList();
          if (_trains.isEmpty) _error = 'No trains found. Try a different date.';
        });
      } else if (res.statusCode == 429) {
        setState(() => _error = 'Rate limit hit. Wait a minute (free plan: 500/month).');
      } else {
        setState(() => _error = 'API error ${res.statusCode}.');
      }
    } catch (e) {
      setState(() => _error = 'Network error: $e');
    }
    setState(() => _searching = false);
  }

  // ── confirm booking ────────────────────────────────────────────────────────
  Future<void> _confirmBooking(Map<String, dynamic> train) async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      _toast('Enter your name and email first.', Colors.orange);
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('bookings').add({
        'bookingType': 'Train',
        'source'     : _fromCtrl.text,
        'destination': _toCtrl.text,
        'fromCode'   : _fromCode,
        'toCode'     : _toCode,
        'date'       : _dateCtrl.text,
        'passengers' : _paxCtrl.text,
        'quota'      : _quota,
        'class'      : _classKey,
        'name'       : _nameCtrl.text.trim(),
        'email'      : _emailCtrl.text.trim(),
        'train'      : train,
        'timestamp'  : FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _toast('Booking saved! ✓', const Color(0xFF00C9A7));
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).pop({
          'bookingConfirmed': true,
          'booking': {
            'title'   : train['name'],
            'subtitle': '${_dateCtrl.text} • ${_paxCtrl.text} pax • ${_toCtrl.text}',
          },
        });
      }
    } catch (e) {
      _toast('Error: $e', Colors.redAccent);
    }
    setState(() => _saving = false);
  }

  void _openIRCTC(Map<String, dynamic> t) =>
      _launch('https://www.irctc.co.in/nget/train-search'
          '?fromStation=$_fromCode&toStation=$_toCode&trainNo=${t['number']}');

  void _toast(String msg, Color c) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
      backgroundColor: c,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ),
  );

  @override
  void dispose() {
    _fromTimer?.cancel(); _toTimer?.cancel();
    for (final c in [_fromCtrl, _toCtrl, _dateCtrl, _nameCtrl, _emailCtrl, _paxCtrl]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.meta.color;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() { _fromSug = []; _toSug = []; });
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [

          // ── Journey card ──────────────────────────────────────────────────
          _DarkCard(
            child: Column(children: [
              _Label('FROM'),
              _StationField(
                controller: _fromCtrl,
                hint: 'Origin station',
                icon: Icons.radio_button_checked_rounded,
                dotColor: color,
                suggestions: _fromSug,
                onChanged: (q) {
                  if (_fromCode.isNotEmpty && !q.contains(_fromCode)) setState(() => _fromCode = '');
                  _fromTimer?.cancel();
                  _fromTimer = Timer(const Duration(milliseconds: 400), () => _searchStations(q, true));
                },
                onSelect: (s) => setState(() {
                  _fromCtrl.text = '${s['name']} (${s['code']})';
                  _fromCode = s['code']!;
                  _fromSug  = [];
                }),
              ),

              // Swap + dotted line
              _SwapDivider(
                color: color,
                onSwap: () => setState(() {
                  final t1 = _fromCtrl.text; final c1 = _fromCode;
                  _fromCtrl.text = _toCtrl.text; _fromCode = _toCode;
                  _toCtrl.text   = t1;           _toCode   = c1;
                  _fromSug = []; _toSug = [];
                }),
              ),

              _Label('TO'),
              _StationField(
                controller: _toCtrl,
                hint: 'Destination station',
                icon: Icons.location_on_rounded,
                dotColor: const Color(0xFFFF5C7A),
                suggestions: _toSug,
                onChanged: (q) {
                  if (_toCode.isNotEmpty && !q.contains(_toCode)) setState(() => _toCode = '');
                  _toTimer?.cancel();
                  _toTimer = Timer(const Duration(milliseconds: 400), () => _searchStations(q, false));
                },
                onSelect: (s) => setState(() {
                  _toCtrl.text = '${s['name']} (${s['code']})';
                  _toCode = s['code']!;
                  _toSug  = [];
                }),
              ),
            ]),
          ),

          const SizedBox(height: 12),

          // ── Date + Pax row ─────────────────────────────────────────────────
          Row(children: [
            Expanded(
              flex: 2,
              child: _DarkCard(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 120)),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: color,
                          surface: BK.card,
                          onSurface: BK.textPri,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (d != null) setState(() {
                    _date = d;
                    _dateCtrl.text = DateFormat('dd MMM yyyy').format(d);
                  });
                },
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.calendar_month_rounded, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Date', style: TextStyle(fontSize: 11, color: BK.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                    const SizedBox(height: 2),
                    Text(
                      _dateCtrl.text.isEmpty ? 'Select date' : _dateCtrl.text,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _dateCtrl.text.isEmpty ? BK.textMuted : BK.textPri,
                      ),
                    ),
                  ])),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DarkCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Pax', style: TextStyle(fontSize: 11, color: BK.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                  const SizedBox(height: 4),
                  Row(children: [
                    _CircleBtn(icon: Icons.remove, color: color, onTap: () {
                      final v = int.tryParse(_paxCtrl.text) ?? 1;
                      if (v > 1) setState(() => _paxCtrl.text = '${v - 1}');
                    }),
                    Expanded(child: Center(child: Text(
                      _paxCtrl.text,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: BK.textPri),
                    ))),
                    _CircleBtn(icon: Icons.add, color: color, onTap: () {
                      final v = int.tryParse(_paxCtrl.text) ?? 1;
                      if (v < 6) setState(() => _paxCtrl.text = '${v + 1}');
                    }),
                  ]),
                ]),
              ),
            ),
          ]),

          const SizedBox(height: 12),

          // ── Class + Quota row ──────────────────────────────────────────────
          Row(children: [
            Expanded(child: _DarkCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Class', style: TextStyle(fontSize: 11, color: BK.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 30,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _classes.map((c) => GestureDetector(
                      onTap: () => setState(() => _classKey = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: _classKey == c ? BK.tabGrad(0) : null,
                          color: _classKey == c ? null : BK.border,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(c, style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _classKey == c ? Colors.white : BK.textSec,
                        )),
                      ),
                    )).toList(),
                  ),
                ),
              ]),
            )),
            const SizedBox(width: 10),
            Expanded(child: _DarkCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Quota', style: TextStyle(fontSize: 11, color: BK.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                const SizedBox(height: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _quota,
                    dropdownColor: BK.card,
                    style: const TextStyle(color: BK.textPri, fontWeight: FontWeight.w700, fontSize: 14),
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 20),
                    isExpanded: true,
                    items: _quotas.map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(),
                    onChanged: (v) => setState(() => _quota = v ?? 'GN'),
                  ),
                ),
              ]),
            )),
          ]),

          const SizedBox(height: 12),

          // ── Flexible date toggle ───────────────────────────────────────────
          _DarkCard(
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.date_range_rounded, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Flexible dates', style: TextStyle(color: BK.textPri, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                const Text('Search ±1 day for best availability', style: TextStyle(color: BK.textMuted, fontSize: 11)),
              ])),
              Switch(
                value: _flexible,
                onChanged: (v) => setState(() => _flexible = v),
                activeColor: color,
                inactiveThumbColor: BK.textMuted,
                inactiveTrackColor: BK.border,
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Passenger details ──────────────────────────────────────────────
          _DarkCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Passenger Details', style: TextStyle(
                  color: BK.textPri, fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 14),
              _DarkField(controller: _nameCtrl,  hint: 'Full Name',  icon: Icons.person_outline, color: color),
              const SizedBox(height: 10),
              _DarkField(controller: _emailCtrl, hint: 'Email',      icon: Icons.email_outlined,  color: color,
                  keyboardType: TextInputType.emailAddress),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Search button ──────────────────────────────────────────────────
          _GlowButton(
            label: 'Search Trains',
            icon: Icons.search_rounded,
            isLoading: _searching,
            gradient: BK.tabGrad(0),
            glowColor: widget.meta.color,
            onPressed: _searchTrains,
          ),

          // ── Error ──────────────────────────────────────────────────────────
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5C7A).withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFF5C7A).withOpacity(0.25)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.error_outline_rounded,
                    color: Color(0xFFFF5C7A), size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(_error!,
                    style: const TextStyle(color: Color(0xFFFF5C7A), fontSize: 13, fontWeight: FontWeight.w500))),
              ]),
            ),
          ],

          const SizedBox(height: 16),

          // ── Results ────────────────────────────────────────────────────────
          if (_trains.isNotEmpty) ...[
            Row(children: [
              Text('${_trains.length} trains found',
                  style: const TextStyle(color: BK.textPri, fontWeight: FontWeight.w800, fontSize: 15)),
              const Spacer(),
              Text('${_dateCtrl.text}',
                  style: const TextStyle(color: BK.textSec, fontSize: 12)),
            ]),
            const SizedBox(height: 12),
          ],

          ..._trains.asMap().entries.map((e) => _TrainCard(
            train: e.value,
            meta: widget.meta,
            index: e.key,
            isSaving: _saving,
            selectedClass: _classKey,
            onBook: () => _showSheet(e.value),
            onIRCTC: () => _openIRCTC(e.value),
          )),
        ],
      ),
    );
  }

  void _showSheet(Map<String, dynamic> train) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingSheet(
        train: train,
        from: _fromCtrl.text,
        to: _toCtrl.text,
        date: _dateCtrl.text,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        pax: _paxCtrl.text,
        quota: _quota,
        classKey: _classKey,
        meta: widget.meta,
        isSaving: _saving,
        onConfirm: () { Navigator.pop(context); _confirmBooking(train); },
        onIRCTC: () { Navigator.pop(context); _openIRCTC(train); },
      ),
    );
  }
}

// ─── External Tab ─────────────────────────────────────────────────────────────
class _Provider {
  final String name, url;
  final IconData icon;
  final Color color;
  const _Provider(this.name, this.url, this.icon, this.color);
}

class _ExternalTab extends StatefulWidget {
  final _TabMeta meta;
  final String description;
  final String Function(String, String, String) buildUrl;
  final List<_Provider> providers;
  const _ExternalTab({required this.meta, required this.description,
      required this.buildUrl, required this.providers});
  @override
  State<_ExternalTab> createState() => _ExternalTabState();
}

class _ExternalTabState extends State<_ExternalTab> {
  final _fromCtrl = TextEditingController(text: 'Chennai');
  final _toCtrl   = TextEditingController();
  final _dateCtrl = TextEditingController();
  // ignore: unused_field
  DateTime? _date;

  @override
  Widget build(BuildContext context) {
    final color = widget.meta.color;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [

        // Hero gradient pill
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: BK.tabGrad(BK.tabs.indexOf(widget.meta)),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(widget.meta.icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Book ${widget.meta.label}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(widget.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
            ])),
          ]),
        ),

        const SizedBox(height: 20),

        // Route card
        _DarkCard(child: Column(children: [
          _DarkField(controller: _fromCtrl, hint: 'From City', icon: Icons.radio_button_checked_rounded, color: color),
          const SizedBox(height: 10),
          _DarkField(controller: _toCtrl,   hint: 'To City',   icon: Icons.location_on_rounded, color: const Color(0xFFFF5C7A)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 120)),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: ColorScheme.dark(
                      primary: color, surface: BK.card, onSurface: BK.textPri),
                  ),
                  child: child!,
                ),
              );
              if (d != null) setState(() {
                _date = d;
                _dateCtrl.text = DateFormat('dd MMM yyyy').format(d);
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: BK.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BK.border),
              ),
              child: Row(children: [
                Icon(Icons.calendar_month_rounded, color: color, size: 18),
                const SizedBox(width: 10),
                Text(
                  _dateCtrl.text.isEmpty ? 'Select travel date' : _dateCtrl.text,
                  style: TextStyle(
                    color: _dateCtrl.text.isEmpty ? BK.textMuted : BK.textPri,
                    fontSize: 14, fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
            ),
          ),
        ])),

        const SizedBox(height: 16),

        _GlowButton(
          label: 'Search on ${widget.providers.first.name}',
          icon: Icons.open_in_new_rounded,
          isLoading: false,
          gradient: BK.tabGrad(BK.tabs.indexOf(widget.meta)),
          glowColor: color,
          onPressed: () => _launch(widget.buildUrl(
              _fromCtrl.text.trim(), _toCtrl.text.trim(), _dateCtrl.text)),
        ),

        const SizedBox(height: 24),

        const Text('OR CHOOSE PROVIDER',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                color: BK.textMuted, letterSpacing: 1.5)),
        const SizedBox(height: 12),

        ...widget.providers.asMap().entries.map((e) {
          final p = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => _launch(p.url),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BK.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: p.color.withOpacity(0.2)),
                  boxShadow: [BoxShadow(
                      color: p.color.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 4))],
                ),
                child: Row(children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: p.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(p.icon, color: p.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.name, style: const TextStyle(
                        color: BK.textPri, fontSize: 15, fontWeight: FontWeight.w800)),
                    Text(p.url.replaceFirst('https://', ''),
                        style: const TextStyle(color: BK.textMuted, fontSize: 11)),
                  ])),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: p.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: p.color),
                  ),
                ]),
              ),
            ),
          );
        }),

        const SizedBox(height: 12),
        Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: const [
            Icon(Icons.lock_outline_rounded, size: 12, color: BK.textMuted),
            SizedBox(width: 6),
            Text("You'll be redirected to the provider's secure app or website.",
                style: TextStyle(fontSize: 11, color: BK.textMuted)),
          ]),
        ),
      ],
    );
  }
}

// ─── Train result card ────────────────────────────────────────────────────────
class _TrainCard extends StatelessWidget {
  const _TrainCard({
    required this.train, required this.meta, required this.index,
    required this.isSaving, required this.selectedClass,
    required this.onBook, required this.onIRCTC,
  });
  final Map<String, dynamic> train;
  final _TabMeta meta;
  final int index;
  final bool isSaving;
  final String selectedClass;
  final VoidCallback onBook, onIRCTC;

  @override
  Widget build(BuildContext context) {
    final color   = meta.color;
    final classes = (train['classes'] as List?) ?? [];
    final days    = (train['days'] as List?) ?? [];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: BK.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.18)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(children: [
          // Top gradient strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.18), color.withOpacity(0.04)],
                begin: Alignment.centerLeft, end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(children: [
              Icon(Icons.train_rounded, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(train['name'],
                  style: const TextStyle(color: BK.textPri, fontWeight: FontWeight.w800, fontSize: 14),
                  overflow: TextOverflow.ellipsis)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('#${train['number']}',
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(children: [
              // Time row
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(train['departure'],
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color, letterSpacing: -1)),
                  const Text('Departure', style: TextStyle(color: BK.textMuted, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                ])),
                Column(children: [
                  Row(children: [
                    Container(width: 30, height: 1, color: BK.border),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(train['duration'],
                          style: const TextStyle(color: BK.textSec, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    Container(width: 30, height: 1, color: BK.border),
                  ]),
                  const SizedBox(height: 4),
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: BK.textMuted),
                ]),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(train['arrival'],
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: BK.textPri, letterSpacing: -1)),
                  const Text('Arrival', style: TextStyle(color: BK.textMuted, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                ])),
              ]),

              if (classes.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 26,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: classes.map<Widget>((c) {
                      final isSelected = c.toString() == selectedClass;
                      return Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: isSelected ? BK.tabGrad(0) : null,
                          color: isSelected ? null : BK.border,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(c.toString(),
                            style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : BK.textSec,
                            )),
                      );
                    }).toList(),
                  ),
                ),
              ],

              if (days.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.schedule_rounded, size: 12, color: BK.textMuted),
                  const SizedBox(width: 4),
                  Text('Runs on: ${days.join(', ')}',
                      style: const TextStyle(color: BK.textMuted, fontSize: 11)),
                ]),
              ],

              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: _OutlineBtn(
                    label: 'IRCTC',
                    icon: Icons.open_in_new_rounded,
                    color: color,
                    onTap: onIRCTC,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _GlowButton(
                    label: 'Book Now',
                    icon: Icons.bolt_rounded,
                    isLoading: isSaving,
                    gradient: BK.tabGrad(0),
                    glowColor: color,
                    onPressed: onBook,
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Booking bottom sheet ─────────────────────────────────────────────────────
class _BookingSheet extends StatelessWidget {
  const _BookingSheet({
    required this.train, required this.from, required this.to,
    required this.date, required this.name, required this.email,
    required this.pax, required this.quota, required this.classKey,
    required this.meta, required this.isSaving,
    required this.onConfirm, required this.onIRCTC,
  });
  final Map<String, dynamic> train;
  final String from, to, date, name, email, pax, quota, classKey;
  final _TabMeta meta;
  final bool isSaving;
  final VoidCallback onConfirm, onIRCTC;

  @override
  Widget build(BuildContext context) {
    final color = meta.color;
    return Container(
      decoration: const BoxDecoration(
        color: BK.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle bar
        Center(child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(color: BK.border, borderRadius: BorderRadius.circular(2)),
        )),
        const SizedBox(height: 20),

        // Train summary
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: BK.tabGrad(0),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.train_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('${train['name']} (${train['number']})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _WhiteTag('${train['departure']} → ${train['arrival']}', Icons.schedule_rounded),
              const SizedBox(width: 8),
              _WhiteTag(train['duration'], Icons.timer_outlined),
              const SizedBox(width: 8),
              _WhiteTag(classKey, Icons.airline_seat_recline_normal_rounded),
            ]),
          ]),
        ),

        const SizedBox(height: 20),

        // Details grid
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BK.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BK.border),
          ),
          child: Column(children: [
            _SheetRow('From',   from),
            _SheetRow('To',     to),
            _SheetRow('Date',   date),
            _SheetRow('Class',  classKey),
            _SheetRow('Quota',  quota),
            _SheetRow('Pax',    pax),
            _SheetRow('Name',   name.isEmpty  ? '—' : name),
            _SheetRow('Email',  email.isEmpty ? '—' : email, isLast: true),
          ]),
        ),

        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _OutlineBtn(
            label: 'IRCTC',
            icon: Icons.open_in_new_rounded,
            color: color,
            onTap: onIRCTC,
          )),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: _GlowButton(
            label: 'Confirm & Save',
            icon: Icons.check_circle_rounded,
            isLoading: isSaving,
            gradient: BK.tabGrad(0),
            glowColor: color,
            onPressed: onConfirm,
          )),
        ]),
      ]),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _DarkCard extends StatelessWidget {
  const _DarkCard({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BK.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BK.border),
        boxShadow: BK.cardShadow,
      ),
      child: child,
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(
        fontSize: 10, color: BK.textMuted, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
  );
}

class _SwapDivider extends StatelessWidget {
  const _SwapDivider({required this.color, required this.onSwap});
  final Color color;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(children: [
      Expanded(child: Row(children: List.generate(12, (i) => Expanded(child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        height: 1,
        color: i.isEven ? BK.border : Colors.transparent,
      ))))),
      GestureDetector(
        onTap: onSwap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: const Icon(Icons.swap_vert_rounded, color: Colors.white, size: 18),
        ),
      ),
      Expanded(child: Row(children: List.generate(12, (i) => Expanded(child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        height: 1,
        color: i.isEven ? BK.border : Colors.transparent,
      ))))),
    ]),
  );
}

class _StationField extends StatelessWidget {
  const _StationField({
    required this.controller, required this.hint, required this.icon,
    required this.dotColor, required this.suggestions,
    required this.onChanged, required this.onSelect,
  });
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color dotColor;
  final List<Map<String, dynamic>> suggestions;
  final ValueChanged<String> onChanged;
  final ValueChanged<Map<String, dynamic>> onSelect;

  @override
  Widget build(BuildContext context) => Column(children: [
    TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15, color: BK.textPri, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: BK.textMuted, fontSize: 14),
        prefixIcon: Icon(icon, color: dotColor, size: 18),
        filled: true,
        fillColor: BK.bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: BK.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: BK.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: dotColor, width: 1.5)),
      ),
    ),
    if (suggestions.isNotEmpty)
      Container(
        margin: const EdgeInsets.only(top: 2),
        decoration: BoxDecoration(
          color: BK.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BK.border),
          boxShadow: BK.cardShadow,
        ),
        child: Column(
          children: suggestions.take(6).toList().asMap().entries.map((e) {
            final s = e.value; final isLast = e.key == (suggestions.length - 1).clamp(0, 5);
            return Column(children: [
              InkWell(
                onTap: () => onSelect(s),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: dotColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.train_outlined, size: 14, color: dotColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: BK.textPri)),
                      Text(s['code']!, style: const TextStyle(fontSize: 11, color: BK.textMuted)),
                    ])),
                  ]),
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 46, color: BK.border),
            ]);
          }).toList(),
        ),
      ),
  ]);
}

class _DarkField extends StatelessWidget {
  const _DarkField({
    required this.controller, required this.hint,
    required this.icon, required this.color,
  // ignore: unused_element_parameter
  this.keyboardType, this.readOnly = false, this.onTap,
  });
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color color;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    readOnly: readOnly,
    onTap: onTap,
    keyboardType: keyboardType,
    style: const TextStyle(fontSize: 14, color: BK.textPri, fontWeight: FontWeight.w600),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: BK.textMuted, fontSize: 14),
      prefixIcon: Icon(icon, color: color, size: 18),
      filled: true,
      fillColor: BK.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: BK.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: BK.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color, width: 1.5)),
    ),
  );
}

class _GlowButton extends StatelessWidget {
  const _GlowButton({
    required this.label, required this.icon, required this.isLoading,
    required this.gradient, required this.glowColor, required this.onPressed,
  });
  final String label;
  final IconData icon;
  final bool isLoading;
  final LinearGradient gradient;
  final Color glowColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: isLoading ? null : onPressed,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 52,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(isLoading ? 0.15 : 0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 18),
              ]),
      ),
    ),
  );
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({required this.label, required this.icon, required this.color, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
      ])),
    ),
  );
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 16),
    ),
  );
}

class _WhiteTag extends StatelessWidget {
  const _WhiteTag(this.label, this.icon);
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: Colors.white),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _SheetRow extends StatelessWidget {
  const _SheetRow(this.label, this.value, {this.isLast = false});
  final String label, value;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        SizedBox(width: 56, child: Text(label,
            style: const TextStyle(color: BK.textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
        const SizedBox(width: 8),
        Expanded(child: Text(value,
            style: const TextStyle(color: BK.textPri, fontSize: 13, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis)),
      ]),
    ),
    if (!isLast) const Divider(height: 1, color: BK.border),
  ]);
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
Future<void> _launch(String url) async {
  final uri = Uri.parse(url);
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    try { await launchUrl(uri, mode: LaunchMode.platformDefault); } catch (_) {}
  }
}

String _slug(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

String _redBusDate(String d) {
  try { return DateFormat('dd-MMM-yyyy').format(DateFormat('dd MMM yyyy').parse(d)); }
  catch (_) { return ''; }
}