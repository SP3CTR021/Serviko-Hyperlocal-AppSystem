import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../landing_page_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  int _selectedIndex = 0; // 0: customer, 1: worker

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.v3Bg,
      body: Column(
        children: [
          // 46% Top Gradient Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppTheme.v3Grad,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Glow Blob top-right
                Positioned(
                  top: -40,
                  right: -50,
                  child: Container(
                    width: 180,
                    height: 180,
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
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 38),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LandingPageScreen.buildLogo(isDark: false),
                        const SizedBox(height: 22),
                        const Text(
                          'What brings you here today?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            height: 1.28,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Free to join. No sign-up fee.',
                          style: TextStyle(
                            fontSize: 13.5,
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

          // Overlapping White Sheet Bottom
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -22),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppTheme.v3White,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(26),
                    topRight: Radius.circular(26),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1F10140F),
                      blurRadius: 30,
                      offset: Offset(0, -10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Subdued Ambient Glows
                    Positioned(
                      top: 10,
                      left: -50,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF28B26A).withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      right: -50,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF28B26A).withValues(alpha: 0.08),
                        ),
                      ),
                    ),

                    // Content
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Option 1: Customer
                            _buildOptionTile(
                              index: 0,
                              title: "I'm looking for a service",
                              subtitle: "Find trusted workers near you",
                              icon: Icons.search_rounded,
                              onTap: () {
                                setState(() => _selectedIndex = 0);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(
                                      isWorker: false,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 14),

                            // Option 2: Worker
                            _buildOptionTile(
                              index: 1,
                              title: "I'm looking for work",
                              subtitle: "Get booked for jobs nearby",
                              icon: Icons.menu_rounded,
                              onTap: () {
                                setState(() => _selectedIndex = 1);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(
                                      isWorker: true,
                                    ),
                                  ),
                                );
                              },
                            ),

                            const Spacer(),

                            // Footer link: Already have an account? Log in
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LoginScreen(
                                        isWorker: _selectedIndex == 1,
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
                                      'Log in',
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1B9457).withValues(alpha: 0.09)
                : const Color(0x8CFFFFFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1B9457).withValues(alpha: 0.50)
                  : AppTheme.v3Line,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.v3Grad : null,
                  color: isSelected ? null : AppTheme.v3Field,
                  borderRadius: BorderRadius.circular(13),
                  border: isSelected
                      ? null
                      : Border.all(color: AppTheme.v3Line),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? Colors.white : AppTheme.v3Ink,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.v3Ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.v3InkSoft,
                      ),
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
