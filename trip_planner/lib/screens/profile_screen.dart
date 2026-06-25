import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  final String email;

  const ProfileScreen({
    super.key,
    required this.email,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController
      _nameController =
      TextEditingController();

  final TextEditingController
      _phoneController =
      TextEditingController();

  final TextEditingController
      _ageController =
      TextEditingController();

  String? _gender;

  bool _isLoading = true;

  File? _profileImage;

  final ImagePicker _picker =
      ImagePicker();

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs =
        await SharedPreferences
            .getInstance();

    final imagePath =
        prefs.getString(
      'profile_image',
    );

    setState(() {
      _nameController.text =
          prefs.getString(
                  'name') ??
              '';

      _phoneController.text =
          prefs.getString(
                  'phone') ??
              '';

      _ageController.text =
          prefs.getString(
                  'age') ??
              '';

      _gender = prefs.getString(
          'gender');

      if (imagePath != null) {
        _profileImage =
            File(imagePath);
      }

      _isLoading = false;
    });
  }

  Future<void>
      _pickProfileImage() async {
    final pickedFile =
        await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedFile == null) return;

    final directory =
        await getApplicationDocumentsDirectory();

    final imagePath =
        '${directory.path}/profile.jpg';

    final imageFile =
        File(pickedFile.path);

    final savedImage =
        await imageFile.copy(
      imagePath,
    );

    final prefs =
        await SharedPreferences
            .getInstance();

    await prefs.setString(
      'profile_image',
      savedImage.path,
    );
    if (mounted) {
  setState(() {});
}
    setState(() {
      _profileImage =
          savedImage;
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!
        .validate()) {
      final prefs =
          await SharedPreferences
              .getInstance();

      await prefs.setString(
        'name',
        _nameController.text
            .trim(),
      );

      await prefs.setString(
        'phone',
        _phoneController.text
            .trim(),
      );

      await prefs.setString(
        'age',
        _ageController.text
            .trim(),
      );

      await prefs.setString(
        'gender',
        _gender ?? '',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(
                Icons.check_circle,
                color:
                    Colors.white,
              ),
              SizedBox(width: 10),
              Text(
                "Profile saved successfully!",
              ),
            ],
          ),

          backgroundColor:
              Colors.teal,

          behavior:
              SnackBarBehavior
                  .floating,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius
                    .circular(
                        14),
          ),
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();

    _phoneController.dispose();

    _ageController.dispose();

    super.dispose();
  }

  InputDecoration
      _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,

      prefixIcon: Container(
        margin:
            const EdgeInsets
                .all(10),

        decoration:
            BoxDecoration(
          color: Colors.teal
              .withValues(alpha: 0.1),

          borderRadius:
              BorderRadius
                  .circular(12),
        ),

        child: Icon(
          icon,
          color:
              Colors.teal,
          size: 22,
        ),
      ),

      filled: true,

      fillColor: Colors.white,

      contentPadding:
          const EdgeInsets
              .symmetric(
        horizontal: 18,
        vertical: 20,
      ),

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius
                .circular(20),
        borderSide:
            BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius
                .circular(20),

        borderSide:
            BorderSide(
          color: Colors
              .grey.shade200,
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius
                .circular(20),

        borderSide:
            const BorderSide(
          color: Colors.teal,
          width: 1.5,
        ),
      ),

      labelStyle:
          const TextStyle(
        color: Colors.black54,
        fontWeight:
            FontWeight.w500,
      ),
    );
  }

  @override
  Widget build(
      BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(
            color: Colors.teal,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          const Color(
              0xFFF4F7FB),

      body: CustomScrollView(
        slivers: [
          // APP BAR
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            elevation: 0,
            backgroundColor:
                Colors.teal,

            flexibleSpace:
                FlexibleSpaceBar(
              background:
                  Container(
                decoration:
                    const BoxDecoration(
                  gradient:
                      LinearGradient(
                    colors: [
                      Color(
                          0xFF00695C),
                      Color(
                          0xFF26A69A),
                    ],

                    begin:
                        Alignment
                            .topLeft,

                    end: Alignment
                        .bottomRight,
                  ),
                ),

                child: SafeArea(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,

                    children: [
                      Stack(
                        children: [
                          Container(
                            padding:
                                const EdgeInsets
                                    .all(
                                        5),

                            decoration:
                                BoxDecoration(
                              shape: BoxShape
                                  .circle,

                              border:
                                  Border.all(
                                color: Colors
                                    .white
                                    .withValues(
                                        alpha: 0.4),
                                width:
                                    3,
                              ),

                              boxShadow: [
                                BoxShadow(
                                  color: Colors
                                      .black
                                      .withValues(
                                          alpha: 0.15),
                                  blurRadius:
                                      18,
                                ),
                              ],
                            ),

                            child:
                                CircleAvatar(
                              radius:
                                  58,

                              backgroundColor:
                                  Colors
                                      .white,

                              backgroundImage:
                                  _profileImage !=
                                          null
                                      ? FileImage(
                                          _profileImage!)
                                      : const AssetImage(
                                              "assets/boy.png")
                                          as ImageProvider,
                            ),
                          ),

                          Positioned(
                            bottom: 4,
                            right: 4,

                            child:
                                GestureDetector(
                              onTap:
                                  _pickProfileImage,

                              child:
                                  Container(
                                padding:
                                    const EdgeInsets
                                        .all(
                                            10),

                                decoration:
                                    BoxDecoration(
                                  color:
                                      Colors.white,

                                  shape:
                                      BoxShape.circle,

                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors
                                          .black
                                          .withValues(
                                              alpha: 0.1),
                                      blurRadius:
                                          12,
                                    ),
                                  ],
                                ),

                                child:
                                    const Icon(
                                  Icons
                                      .camera_alt,
                                  size:
                                      18,
                                  color:
                                      Colors.teal,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                          height:
                              18),

                      const Text(
                        "My Profile",

                        style:
                            TextStyle(
                          color: Colors
                              .white,

                          fontSize:
                              30,

                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),

                      const SizedBox(
                          height:
                              8),

                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              14,
                          vertical: 6,
                        ),

                        decoration:
                            BoxDecoration(
                          color: Colors
                              .white
                              .withValues(
                                  alpha: 0.15),

                          borderRadius:
                              BorderRadius
                                  .circular(
                                      30),
                        ),

                        child: Text(
                          widget.email,

                          style:
                              TextStyle(
                            color: Colors
                                .white
                                .withValues(
                                    alpha: 0.95),

                            fontSize:
                                13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // BODY
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets
                      .all(20),

              child: Form(
                key: _formKey,

                child: Column(
                  children: [
                    _buildGlassCard(
                      child: Column(
                        children: [
                          // EMAIL
                          TextFormField(
                            initialValue:
                                widget
                                    .email,

                            readOnly:
                                true,

                            decoration:
                                _inputDecoration(
                              label:
                                  "Email",
                              icon: Icons
                                  .email,
                            ).copyWith(
                              fillColor:
                                  Colors.grey[
                                      100],
                            ),
                          ),

                          const SizedBox(
                              height:
                                  18),

                          // NAME
                          TextFormField(
                            controller:
                                _nameController,

                            decoration:
                                _inputDecoration(
                              label:
                                  "Full Name",
                              icon: Icons
                                  .person,
                            ),

                            validator:
                                (value) {
                              if (value ==
                                      null ||
                                  value
                                      .isEmpty) {
                                return "Please enter your name";
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                              height:
                                  18),

                          // PHONE
                          TextFormField(
                            controller:
                                _phoneController,

                            keyboardType:
                                TextInputType
                                    .phone,

                            decoration:
                                _inputDecoration(
                              label:
                                  "Phone Number",

                              icon: Icons
                                  .phone,
                            ),

                            validator:
                                (value) {
                              if (value ==
                                      null ||
                                  value
                                      .isEmpty) {
                                return "Please enter phone number";
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                              height:
                                  18),

                          // AGE
                          TextFormField(
                            controller:
                                _ageController,

                            keyboardType:
                                TextInputType
                                    .number,

                            decoration:
                                _inputDecoration(
                              label:
                                  "Age",

                              icon: Icons
                                  .calendar_today,
                            ),
                          ),

                          const SizedBox(
                              height:
                                  18),

                          // GENDER
                          DropdownButtonFormField<
                              String>(
                            initialValue:
                                _gender,

                            icon:
                                const Icon(
                              Icons
                                  .keyboard_arrow_down_rounded,
                              color: Colors
                                  .teal,
                            ),

                            borderRadius:
                                BorderRadius
                                    .circular(
                                        18),

                            dropdownColor:
                                Colors
                                    .white,

                            decoration:
                                _inputDecoration(
                              label:
                                  "Gender",

                              icon: Icons
                                  .people,
                            ),

                            items: [
                              "Male",
                              "Female",
                              "Other"
                            ]
                                .map(
                                  (g) =>
                                      DropdownMenuItem(
                                    value:
                                        g,

                                    child:
                                        Text(
                                      g,

                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),

                            onChanged:
                                (
                              value,
                            ) {
                              setState(() {
                                _gender =
                                    value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                        height: 34),

                    // SAVE BUTTON
                    SizedBox(
                      width: double
                          .infinity,

                      height: 60,

                      child:
                          ElevatedButton(
                        onPressed:
                            _saveProfile,

                        style:
                            ElevatedButton
                                .styleFrom(
                          elevation:
                              0,

                          backgroundColor:
                              Colors
                                  .teal,

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    20),
                          ),
                        ),

                        child: const Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,

                          children: [
                            Icon(
                              Icons.save,
                              color: Colors
                                  .white,
                            ),

                            SizedBox(
                                width:
                                    10),

                            Text(
                              "Save Profile",

                              style:
                                  TextStyle(
                                fontSize:
                                    17,

                                fontWeight:
                                    FontWeight.bold,

                                color: Colors
                                    .white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                        height:
                            30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({
    required Widget child,
  }) {
    return Container(
      padding:
          const EdgeInsets
              .all(22),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
                28),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
                    alpha: 0.05),

            blurRadius: 24,

            offset:
                const Offset(0, 8),
          ),
        ],
      ),

      child: child,
    );
  }
}