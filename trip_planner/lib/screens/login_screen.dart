import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  AUTH WRAPPER  – put this as your app's home in main.dart
//  It auto-redirects logged-in users straight to HomeScreen.
//
//  In main.dart:
//    home: const AuthWrapper(),
// ═══════════════════════════════════════════════════════════════════════════
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF6366f1)),
            ),
          );
        }
        if (snapshot.hasData) return const HomeScreen();
        return const LoginScreen();
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  LOGIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool    _isLoading       = false;
  bool    _obscurePassword = true;
  String? _error;

  final _auth = FirebaseAuth.instance;

  void _setError(String? msg) => setState(() => _error = msg);

  void _navigateHome() {
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  // ── Email / Password login ────────────────────────────────────────────────
  Future<void> _loginWithEmail() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _setError("Please enter both email and password.");
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _navigateHome();
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Google login ──────────────────────────────────────────────────────────
  Future<void> _loginWithGoogle() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() { _isLoading = false; _error = "Google Sign-In cancelled."; });
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      _navigateHome();
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Forgot password ───────────────────────────────────────────────────────
  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _setError("Enter your email above, then tap Forgot Password.");
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Password reset link sent to $email"),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Header(
                  title: "Welcome Back 👋",
                  subtitle: "Sign in to your Travel Guide account",
                ),
                const SizedBox(height: 24),

                if (_error != null) _ErrorBanner(_error!),

                // Google
                _GoogleButton(isLoading: _isLoading, onPressed: _loginWithGoogle),
                const SizedBox(height: 20),
                const _OrDivider(),
                const SizedBox(height: 20),

                // Email
                _AppTextField(
                  controller: _emailCtrl,
                  label: "Email",
                  icon: Icons.email_outlined,
                  inputType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),

                // Password
                _AppTextField(
                  controller: _passwordCtrl,
                  label: "Password",
                  icon: Icons.lock_outline,
                  obscure: _obscurePassword,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey, size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text("Forgot password?",
                        style: TextStyle(color: Colors.black54, fontSize: 13)),
                  ),
                ),

                _PrimaryButton(
                  label: "Sign In",
                  isLoading: _isLoading,
                  onPressed: _loginWithEmail,
                ),
                const SizedBox(height: 20),

                // → Create account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?  ",
                        style: TextStyle(color: Colors.black54, fontSize: 14)),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SignUpScreen())),
                      child: const Text("Create one",
                          style: TextStyle(
                            color: Color(0xFF6366f1),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          )),
                    ),
                  ],
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
//  SIGN UP SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool    _isLoading       = false;
  bool    _obscurePassword = true;
  bool    _obscureConfirm  = true;
  String? _error;

  final _auth = FirebaseAuth.instance;

  void _setError(String? msg) => setState(() => _error = msg);

  void _goHome() {
    if (mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    }
  }

  // ── Create account with email ─────────────────────────────────────────────
  Future<void> _signUp() async {
    final name     = _nameCtrl.text.trim();
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm  = _confirmCtrl.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _setError("Please fill in all fields.");
      return;
    }
    if (password != confirm) {
      _setError("Passwords do not match.");
      return;
    }
    if (password.length < 6) {
      _setError("Password must be at least 6 characters.");
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await cred.user?.updateDisplayName(name);
      _goHome();
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Google sign up ────────────────────────────────────────────────────────
  Future<void> _signUpWithGoogle() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() { _isLoading = false; _error = "Google Sign-In cancelled."; });
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      _goHome();
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Header(
                  title: "Create Account ✈️",
                  subtitle: "Join Travel Guide and plan your trips",
                ),
                const SizedBox(height: 24),

                if (_error != null) _ErrorBanner(_error!),

                // Google sign up
                _GoogleButton(
                  isLoading: _isLoading,
                  onPressed: _signUpWithGoogle,
                  label: "Sign up with Google",
                ),
                const SizedBox(height: 20),
                const _OrDivider(label: "or sign up with email"),
                const SizedBox(height: 20),

                // Full name
                _AppTextField(
                  controller: _nameCtrl,
                  label: "Full Name",
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 14),

                // Email
                _AppTextField(
                  controller: _emailCtrl,
                  label: "Email",
                  icon: Icons.email_outlined,
                  inputType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),

                // Password
                _AppTextField(
                  controller: _passwordCtrl,
                  label: "Password",
                  icon: Icons.lock_outline,
                  obscure: _obscurePassword,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey, size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 14),

                // Confirm password
                _AppTextField(
                  controller: _confirmCtrl,
                  label: "Confirm Password",
                  icon: Icons.lock_outline,
                  obscure: _obscureConfirm,
                  suffix: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey, size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: 24),

                _PrimaryButton(
                  label: "Create Account",
                  isLoading: _isLoading,
                  onPressed: _signUp,
                ),
                const SizedBox(height: 20),

                // → Back to login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?  ",
                        style: TextStyle(color: Colors.black54, fontSize: 14)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text("Sign In",
                          style: TextStyle(
                            color: Color(0xFF6366f1),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          )),
                    ),
                  ],
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
//  SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(28),
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: child,
      );
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Image.asset('assets/airplane.png',
              width: 72, height: 72, fit: BoxFit.contain),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
              textAlign: TextAlign.center),
        ],
      );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
          ],
        ),
      );
}

class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final String label;

  const _GoogleButton({
    required this.isLoading,
    required this.onPressed,
    this.label = "Continue with Google",
  });

  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.black12),
          ),
          elevation: 0,
        ),
        icon: Image.asset('assets/search.png', width: 22, height: 22),
        label: isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black))
            : Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
        onPressed: isLoading ? null : onPressed,
      );
}

class _OrDivider extends StatelessWidget {
  final String label;
  const _OrDivider({this.label = "or"});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Expanded(child: Divider(color: Colors.black26)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(label,
                style:
                    const TextStyle(color: Colors.black45, fontSize: 12)),
          ),
          const Expanded(child: Divider(color: Colors.black26)),
        ],
      );
}

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? inputType;
  final Widget? suffix;

  const _AppTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure   = false,
    this.inputType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller:   controller,
        obscureText:  obscure,
        keyboardType: inputType,
        style:        const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          prefixIcon:  Icon(icon, color: Colors.grey, size: 20),
          suffixIcon:  suffix,
          labelText:   label,
          labelStyle:  const TextStyle(color: Colors.black54),
          filled:      true,
          fillColor:   Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:   BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF6366f1), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366f1),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 3,
        ),
        child: isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white)),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  FRIENDLY ERROR MESSAGES
// ═══════════════════════════════════════════════════════════════════════════
String _friendlyError(String code) {
  switch (code) {
    case 'user-not-found':
      return "No account found with this email. Please sign up.";
    case 'wrong-password':
      return "Incorrect password. Try again or reset it.";
    case 'invalid-credential':
      return "Incorrect email or password. Please try again.";
    case 'email-already-in-use':
      return "An account already exists with this email. Please sign in.";
    case 'invalid-email':
      return "Please enter a valid email address.";
    case 'weak-password':
      return "Password is too weak. Use at least 6 characters.";
    case 'network-request-failed':
      return "No internet connection. Please check your network.";
    case 'too-many-requests':
      return "Too many attempts. Please try again later.";
    case 'user-disabled':
      return "This account has been disabled. Contact support.";
    default:
      return "Something went wrong. Please try again.";
  }
}