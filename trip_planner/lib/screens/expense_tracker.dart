import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen>
    with SingleTickerProviderStateMixin {
  final tripController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  String _selectedCategory = 'Food';
  late AnimationController _animController;

  // SAFE USER CHECK
  User? get _currentUser => FirebaseAuth.instance.currentUser;

  // SAFE FIRESTORE REFERENCE
  CollectionReference? get _expensesRef {
    final user = _currentUser;

    if (user == null) {
      return null;
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('expenses');
  }

  final List<String> _categories = [
    'Food',
    'Transport',
    'Hotel',
    'Activities',
    'Shopping',
    'Other',
  ];

  final Map<String, IconData> _categoryIcons = {
    'Food': Icons.restaurant,
    'Transport': Icons.directions_bus,
    'Hotel': Icons.hotel,
    'Activities': Icons.hiking,
    'Shopping': Icons.shopping_bag,
    'Other': Icons.receipt_long,
  };

  final Map<String, Color> _categoryColors = {
    'Food': const Color(0xFFFF7043),
    'Transport': const Color(0xFF42A5F5),
    'Hotel': const Color(0xFF7E57C2),
    'Activities': const Color(0xFF26A69A),
    'Shopping': const Color(0xFFEC407A),
    'Other': const Color(0xFF78909C),
  };

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    tripController.dispose();
    amountController.dispose();
    noteController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _addExpense() async {
    final ref = _expensesRef;

    if (ref == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please login first"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (tripController.text.isEmpty ||
        amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              "Please fill Trip Name and Amount"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final parsed =
        double.tryParse(amountController.text);

    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Enter a valid amount"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    await ref.add({
      "trip": tripController.text.trim(),
      "amount": parsed,
      "category": _selectedCategory,
      "note": noteController.text.trim(),
      "date": _formattedDate(),
      "createdAt": FieldValue.serverTimestamp(),
    });

    tripController.clear();
    amountController.clear();
    noteController.clear();

    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteExpense(String docId) async {
    final ref = _expensesRef;

    if (ref == null) return;

    await ref.doc(docId).delete();
  }

  String _formattedDate() {
    final now = DateTime.now();

    return "${now.day} ${_monthName(now.month)} ${now.year}";
  }

  String _monthName(int m) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return months[m];
  }

  void _showAddExpenseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddExpenseSheet(
        tripController: tripController,
        amountController: amountController,
        noteController: noteController,
        selectedCategory: _selectedCategory,
        categories: _categories,
        categoryIcons: _categoryIcons,
        categoryColors: _categoryColors,
        onCategoryChanged: (val) =>
            setState(() => _selectedCategory = val),
        onAdd: _addExpense,
      ),
    );
  }

  Map<String, double> _categoryTotals(
      List<QueryDocumentSnapshot> docs) {
    final map = <String, double>{};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      final cat = data['category'] as String;

      final amt =
          double.tryParse(data['amount'].toString()) ??
              0;

      map[cat] = (map[cat] ?? 0) + amt;
    }

    return map;
  }

  double _total(List<QueryDocumentSnapshot> docs) =>
      docs.fold(
        0,
        (sum, doc) =>
            sum +
            (double.tryParse(
                    (doc.data()
                            as Map<String, dynamic>)['amount']
                        .toString()) ??
                0),
      );

  @override
  Widget build(BuildContext context) {
    // LOGIN CHECK
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.lock_outline,
                size: 70,
                color: Colors.teal,
              ),
              SizedBox(height: 16),
              Text(
                "Please login first",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      body: StreamBuilder<QuerySnapshot>(
        stream: _expensesRef!
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.teal,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          final total = _total(docs);

          final categoryTotals =
              _categoryTotals(docs);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: Colors.teal,

                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF00796B),
                          Color(0xFF26C6DA),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),

                    child: SafeArea(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(
                                20, 48, 20, 16),

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          mainAxisAlignment:
                              MainAxisAlignment.end,
                          children: [
                            const Text(
                              "Expense Tracker",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              "${docs.length} expense${docs.length == 1 ? '' : 's'} recorded",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),

                              decoration:
                                  BoxDecoration(
                                color: Colors.white
                                    .withOpacity(0.18),
                                borderRadius:
                                    BorderRadius
                                        .circular(12),
                                border: Border.all(
                                  color: Colors.white
                                      .withOpacity(
                                          0.3),
                                ),
                              ),

                              child: Row(
                                mainAxisSize:
                                    MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons
                                        .account_balance_wallet,
                                    color:
                                        Colors.white,
                                    size: 18,
                                  ),

                                  const SizedBox(
                                      width: 8),

                                  Text(
                                    "Total: ₹${total.toStringAsFixed(2)}",
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white,
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (docs.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(
                            16, 16, 16, 0),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        const Text(
                          "Breakdown",
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          height: 44,

                          child: ListView(
                            scrollDirection:
                                Axis.horizontal,

                            children:
                                categoryTotals.entries
                                    .map((entry) {
                              final color =
                                  _categoryColors[
                                          entry.key] ??
                                      Colors.grey;

                              return Container(
                                margin:
                                    const EdgeInsets
                                        .only(
                                            right:
                                                10),

                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),

                                decoration:
                                    BoxDecoration(
                                  color: color
                                      .withOpacity(
                                          0.12),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              22),
                                ),

                                child: Row(
                                  children: [
                                    Icon(
                                      _categoryIcons[
                                              entry
                                                  .key] ??
                                          Icons
                                              .receipt_long,
                                      size: 14,
                                      color: color,
                                    ),

                                    const SizedBox(
                                        width: 6),

                                    Text(
                                      "${entry.key} ₹${entry.value.toStringAsFixed(0)}",
                                      style:
                                          TextStyle(
                                        color:
                                            color,
                                        fontSize:
                                            13,
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (docs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,

                  child: Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,

                      children: [
                        Container(
                          padding:
                              const EdgeInsets.all(
                                  24),

                          decoration:
                              BoxDecoration(
                            color: Colors.teal
                                .withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),

                          child: const Icon(
                            Icons.receipt_long,
                            size: 52,
                            color: Colors.teal,
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          "No expenses yet",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              SliverList(
                delegate:
                    SliverChildBuilderDelegate(
                  (context, index) {
                    final doc = docs[index];

                    final e =
                        doc.data() as Map<String,
                            dynamic>;

                    final color =
                        _categoryColors[
                                e['category']] ??
                            Colors.grey;

                    final icon =
                        _categoryIcons[
                                e['category']] ??
                            Icons.receipt_long;

                    final amount =
                        double.tryParse(
                              e['amount']
                                  .toString(),
                            ) ??
                            0;

                    return Dismissible(
                      key: ValueKey(doc.id),

                      direction:
                          DismissDirection
                              .endToStart,

                      onDismissed: (_) =>
                          _deleteExpense(
                              doc.id),

                      background: Container(
                        margin:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              Colors.redAccent,
                          borderRadius:
                              BorderRadius
                                  .circular(16),
                        ),

                        alignment:
                            Alignment.centerRight,

                        padding:
                            const EdgeInsets.only(
                                right: 20),

                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),

                      child: Container(
                        margin:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),

                        decoration:
                            BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius
                                  .circular(16),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(
                                      0.05),
                              blurRadius: 8,
                              offset:
                                  const Offset(
                                      0, 2),
                            ),
                          ],
                        ),

                        child: ListTile(
                          contentPadding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),

                          leading: Container(
                            width: 46,
                            height: 46,

                            decoration:
                                BoxDecoration(
                              color: color
                                  .withOpacity(
                                      0.12),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          12),
                            ),

                            child: Icon(
                              icon,
                              color: color,
                              size: 22,
                            ),
                          ),

                          title: Text(
                            e['trip'] ?? '',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),

                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              const SizedBox(
                                  height: 2),

                              Text(
                                  e['category'] ??
                                      ''),

                              if ((e['note'] ??
                                      '')
                                  .toString()
                                  .isNotEmpty)
                                Text(e['note']),
                            ],
                          ),

                          trailing: Text(
                            "₹${amount.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: color,
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: docs.length,
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
        },
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _showAddExpenseSheet,
        backgroundColor: Colors.teal,
        icon: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        label: const Text(
          "Add Expense",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AddExpenseSheet extends StatefulWidget {
  final TextEditingController tripController;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final String selectedCategory;
  final List<String> categories;
  final Map<String, IconData> categoryIcons;
  final Map<String, Color> categoryColors;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onAdd;

  const _AddExpenseSheet({
    required this.tripController,
    required this.amountController,
    required this.noteController,
    required this.selectedCategory,
    required this.categories,
    required this.categoryIcons,
    required this.categoryColors,
    required this.onCategoryChanged,
    required this.onAdd,
  });

  @override
  State<_AddExpenseSheet> createState() =>
      _AddExpenseSheetState();
}

class _AddExpenseSheetState
    extends State<_AddExpenseSheet> {
  late String _localCategory;

  @override
  void initState() {
    super.initState();

    _localCategory =
        widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).viewInsets.bottom,
      ),

      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),

        padding:
            const EdgeInsets.fromLTRB(
                20, 16, 20, 28),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,

                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius:
                      BorderRadius.circular(4),
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "New Expense",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller:
                  widget.tripController,
              label:
                  "Trip / Expense Name",
              icon: Icons.edit_note,
            ),

            const SizedBox(height: 12),

            _buildTextField(
              controller:
                  widget.amountController,
              label: "Amount (₹)",
              icon: Icons.currency_rupee,
              keyboardType:
                  TextInputType.number,
            ),

            const SizedBox(height: 12),

            _buildTextField(
              controller:
                  widget.noteController,
              label: "Note (optional)",
              icon:
                  Icons.sticky_note_2_outlined,
            ),

            const SizedBox(height: 16),

            const Text(
              "Category",
              style: TextStyle(
                fontWeight:
                    FontWeight.w600,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 42,

              child: ListView(
                scrollDirection:
                    Axis.horizontal,

                children:
                    widget.categories
                        .map((cat) {
                  final selected =
                      _localCategory ==
                          cat;

                  final color =
                      widget.categoryColors[
                              cat] ??
                          Colors.grey;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _localCategory =
                            cat;
                      });

                      widget
                          .onCategoryChanged(
                              cat);
                    },

                    child: AnimatedContainer(
                      duration:
                          const Duration(
                              milliseconds:
                                  200),

                      margin:
                          const EdgeInsets
                              .only(
                                  right: 10),

                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),

                      decoration:
                          BoxDecoration(
                        color: selected
                            ? color
                            : color
                                .withOpacity(
                                    0.1),

                        borderRadius:
                            BorderRadius
                                .circular(
                                    22),
                      ),

                      child: Row(
                        children: [
                          Icon(
                            widget.categoryIcons[
                                    cat] ??
                                Icons
                                    .receipt_long,
                            size: 14,
                            color: selected
                                ? Colors
                                    .white
                                : color,
                          ),

                          const SizedBox(
                              width: 6),

                          Text(
                            cat,
                            style:
                                TextStyle(
                              color: selected
                                  ? Colors
                                      .white
                                  : color,
                              fontSize: 13,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,

              child: ElevatedButton(
                onPressed: widget.onAdd,

                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      Colors.teal,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(14),
                  ),
                ),

                child: const Text(
                  "Add Expense",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController
        controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,

      decoration: InputDecoration(
        labelText: label,

        prefixIcon: Icon(
          icon,
          size: 20,
          color: Colors.teal,
        ),

        filled: true,
        fillColor: Colors.grey.shade50,

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),

          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),

          borderSide:
              const BorderSide(
            color: Colors.teal,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}