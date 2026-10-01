import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/google_logo.dart';
import '../customer/customer_main_screen.dart';
import '../loading_screen.dart';
import '../worker/worker_main_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final bool isWorker;

  const RegisterScreen({
    super.key,
    this.isWorker = false,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isWorker;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityVillageController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedSkill;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _skillsList = [
    'Electrician',
    'Plumber',
    'Carpenter',
    'Aircon Technician',
    'Cleaner / Housekeeping',
    'Painter',
    'Welder',
    'Pest Control Specialist',
    'Massage Therapist',
    'Gardener / Landscaper',
    'Appliance Repair',
    'Handyman',
  ];

  @override
  void initState() {
    super.initState();
    _isWorker = widget.isWorker;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityVillageController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchRole(bool worker) {
    if (_isWorker == worker) return;
    setState(() {
      _isWorker = worker;
      _errorMessage = null;
    });
  }

  void _showSkillsPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
              const SizedBox(height: 16),
              const Text(
                'Choose your job',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.v3Ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select your primary skill or service offering',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.v3InkSoft,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _skillsList.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: AppTheme.v3Line,
                  ),
                  itemBuilder: (context, index) {
                    final skill = _skillsList[index];
                    final isSelected = _selectedSkill == skill;
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      title: Text(
                        skill,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.v3Green
                              : AppTheme.v3Ink,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.v3Green,
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        setState(() => _selectedSkill = skill);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isWorker && _selectedSkill == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your basic skill or trade.'),
          backgroundColor: Color(0xFFD0453A),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final fullName =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
            .trim();

    final success = await AuthService().register(
      fullName: fullName.isEmpty ? _emailController.text.trim().split('@').first : fullName,
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _isWorker ? 'worker' : 'customer',
      phoneNumber: _phoneController.text.trim(),
      city: _cityVillageController.text.trim(),
      skill: _isWorker ? (_selectedSkill ?? 'General Service') : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Please check your email for verification if needed.'),
          backgroundColor: AppTheme.v3Green,
        ),
      );
      final destination =
          _isWorker ? const WorkerMainScreen() : const CustomerMainScreen();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoadingScreen(destination: destination),
        ),
        (route) => false,
      );
    } else {
      setState(() {
        _errorMessage =
            'Unable to complete registration. Please verify your details.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.v3White,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Header
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
                          // Top row: back button & pill badge
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

                              // Interactive Pill badge (Offering / Looking for)
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
                                        _isWorker ? 'Offering' : 'Looking for',
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
                            'Create an account',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),

                          Text(
                            'Free. No sign-up fee.',
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
                    // Worker notification banner
                    if (_isWorker) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B9457).withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF1B9457).withValues(alpha: 0.30),
                          ),
                        ),
                        child: const Text(
                          'As a worker, people in your area will be able to see you and can accept bookings immediately.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.v3Ink,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],

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

                    // Google Sign Up button
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
                              Text(
                                _isWorker
                                    ? 'Continue with Google'
                                    : 'Continue with Google',
                                style: const TextStyle(
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

                    const SizedBox(height: 18),

                    // Divider: or register with email
                    Row(
                      children: const [
                        Expanded(
                          child: Divider(color: AppTheme.v3Line, thickness: 1),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or register with email',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.v3InkSoft,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: AppTheme.v3Line, thickness: 1),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // row2: Name and Last name
                    Row(
                      children: [
                        Expanded(
                          child: _buildFieldContainer(
                            label: 'Name',
                            child: TextFormField(
                              controller: _firstNameController,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.v3Ink,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'John',
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
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildFieldContainer(
                            label: 'Last name',
                            child: TextFormField(
                              controller: _lastNameController,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.v3Ink,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'dela Cruz',
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
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Email
                    _buildFieldContainer(
                      label: 'Email',
                      child: TextFormField(
                        controller: _emailController,
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
                        validator: (val) {
                          if (val == null || !val.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Phone number
                    _buildFieldContainer(
                      label: 'Phone number',
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.v3Ink,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0917 123 4567',
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
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Enter phone number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Basic skills dropdown (Worker only)
                    if (_isWorker) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Basic skills',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.v3Ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _showSkillsPicker,
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: AppTheme.v3Field,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.v3Line,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedSkill ?? 'Choose your job',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: _selectedSkill != null
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: _selectedSkill != null
                                          ? AppTheme.v3Ink
                                          : AppTheme.v3InkFaint,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.expand_more_rounded,
                                    size: 20,
                                    color: AppTheme.v3InkSoft,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],

                    // City and village
                    _buildFieldContainer(
                      label: 'City and village',
                      child: TextFormField(
                        controller: _cityVillageController,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.v3Ink,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Davao City, Matina',
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
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Enter city and village';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Password
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
                              setState(() =>
                                  _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.length < 6) {
                            return 'At least 6 characters required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Primary CTA button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _handleRegister,
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
                                    'Create an account',
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

                    const SizedBox(height: 20),

                    // Foot-link: Already have an account? Log in here
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoginScreen(
                                isWorker: _isWorker,
                              ),
                            ),
                          );
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: AppTheme.v3InkSoft,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Log in here',
                              style: TextStyle(
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
