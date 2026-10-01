import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/google_logo.dart';
import '../customer/customer_main_screen.dart';
import '../loading_screen.dart';
import '../worker/worker_main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isWorker;

  const LoginScreen({
    super.key,
    this.isWorker = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isWorker;

  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isWorker = widget.isWorker;

    // Prefilled demo credentials commented out for clean slate database testing:
    // if (_isWorker) {
    //   _identifierController.text = 'worker1@serviko.com';
    //   _passwordController.text = 'password';
    // } else {
    //   _identifierController.text = 'customer@serviko.com';
    //   _passwordController.text = 'password';
    // }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchRole(bool worker) {
    if (_isWorker == worker) return;
    setState(() {
      _isWorker = worker;
      _errorMessage = null;
      // Prefilled demo credentials commented out for clean slate testing:
      // if (_isWorker) {
      //   _identifierController.text = 'worker1@serviko.com';
      //   _passwordController.text = 'password';
      // } else {
      //   _identifierController.text = 'customer@serviko.com';
      //   _passwordController.text = 'password';
      // }
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await AuthService().login(
      _identifierController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final auth = AuthService();
      final destination = (auth.isWorker || _isWorker)
          ? const WorkerMainScreen()
          : const CustomerMainScreen();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoadingScreen(destination: destination),
        ),
        (route) => false,
      );
    } else {
      setState(() {
        _errorMessage = 'Invalid email or password. Please try again.';
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = await AuthService().signInWithGoogle(
      role: _isWorker ? 'worker' : 'customer',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (user != null) {
      final destination = _isWorker
          ? const WorkerMainScreen()
          : const CustomerMainScreen();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoadingScreen(destination: destination),
        ),
        (route) => false,
      );
    } else {
      // Demo fallback commented out for clean slate database testing:
      // final email = _isWorker ? 'worker1@serviko.com' : 'customer@serviko.com';
      // final success = await AuthService().login(email, 'password');
    }
  }

  void _showForgotPasswordModal() {
    final resetController = TextEditingController(text: _identifierController.text);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.v3White,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(26),
              topRight: Radius.circular(26),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.v3Line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.v3Ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your email address and we will send you a link to reset your password.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.v3InkSoft,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              _buildFieldContainer(
                label: 'Email address',
                child: TextFormField(
                  controller: resetController,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.v3Ink,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'juan@email.com',
                    hintStyle: TextStyle(
                      color: AppTheme.v3InkFaint,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final email = resetController.text.trim();
                  if (email.isEmpty) return;
                  Navigator.pop(ctx);
                  final error = await AuthService().resetPassword(email);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error == null
                            ? 'Password reset email sent! Please check your inbox or spam.'
                            : 'Failed to send reset email: $error',
                      ),
                      backgroundColor: error == null ? AppTheme.v3Green : const Color(0xFFD0453A),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.v3Green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Send Reset Link',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.v3White,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Header (v3Grad + Blob + Back + Pill + Headline + Sub)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppTheme.v3Grad,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Blob top-right
                  Positioned(
                    top: -50,
                    right: -40,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF28B26A).withValues(alpha: 0.50),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.70],
                        ),
                      ),
                    ),
                  ),

                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: back button & pill
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.maybePop(context),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.30),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.chevron_left_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),

                              // Interactive Pill badge (toggles worker / service finder)
                              GestureDetector(
                                onTap: () => _switchRole(!_isWorker),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.30),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _isWorker
                                            ? 'For workers'
                                            : 'For service finders',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.swap_horiz_rounded,
                                        size: 13,
                                        color: Colors.white70,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            'Welcome back',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),

                          Text(
                            _isWorker
                                ? 'Log in to see new bookings near you.'
                                : 'Log in to book trusted help nearby.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Form Body (body-pad)
            Padding(
              padding: const EdgeInsets.all(22),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Google Sign In button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _handleGoogleSignIn,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppTheme.v3White,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.v3Line,
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A10140F),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const GoogleLogo(size: 20),
                              const SizedBox(width: 10),
                              const Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.v3Ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Divider: or log in with email
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Divider(
                              color: AppTheme.v3Line,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'or log in with email',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.v3InkSoft,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(
                              color: AppTheme.v3Line,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Error Message banner
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDECEA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF5B5B0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFD0453A),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFD0453A),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Email or Phone field
                    _buildFieldContainer(
                      label: 'Email or phone number',
                      child: TextFormField(
                        controller: _identifierController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.v3Ink,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'juan@email.com',
                          hintStyle: TextStyle(
                            color: AppTheme.v3InkFaint,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email or phone number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Password field
                    _buildFieldContainer(
                      label: 'Password',
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.v3Ink,
                        ),
                        decoration: InputDecoration(
                          hintText: 'At least 8 characters',
                          hintStyle: const TextStyle(
                            color: AppTheme.v3InkFaint,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppTheme.v3InkSoft,
                              size: 19,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                    ),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 18),
                        child: GestureDetector(
                          onTap: _showForgotPasswordModal,
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.v3Green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Log in button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _handleLogin,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppTheme.v3Grad,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Log in',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Foot-link: New here? Create account
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RegisterScreen(
                                isWorker: _isWorker,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'New here? ',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: AppTheme.v3InkSoft,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _isWorker
                                  ? 'Create a worker account'
                                  : 'Create an account',
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: AppTheme.v3Green,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldContainer({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.v3Ink,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.v3Field,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.v3Line, width: 1.5),
          ),
          child: child,
        ),
      ],
    );
  }
}
