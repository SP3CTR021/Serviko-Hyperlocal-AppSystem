import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'customer/customer_main_screen.dart';
import 'worker/worker_main_screen.dart';
import 'landing_page_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late AnimationController _floatController;
  late AnimationController _barController;
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();

    // 1. Ripple animation (2.6s looping)
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    // 2. Logo Float animation (3.4s smooth float)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();

    // 3. Sliding bar animation (1.5s looping)
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // 4. Entrance pop & rise (900ms)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    // Navigate after splash display
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      final auth = AuthService();
      Widget target;
      if (!auth.isLoggedIn) {
        target = const LandingPageScreen();
      } else if (auth.isWorker) {
        target = const WorkerMainScreen();
      } else {
        target = const CustomerMainScreen();
      }

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => target,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 450),
        ),
      );
    });
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _floatController.dispose();
    _barController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF050805),
      body: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            // LAYER 1: Deep Dark Linear Gradient
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF050805),
                      Color(0xFF0A140D),
                      Color(0xFF0F2A1A),
                      Color(0xFF050805),
                    ],
                    stops: [0.0, 0.38, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            // LAYER 2: Emerald Radial Glow
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, -0.06),
                    radius: 0.95,
                    colors: [
                      Color(0xBF3FD483),
                      Color(0x8C1E8E4F),
                      Color(0x59123422),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.35, 0.60, 0.85],
                  ),
                ),
              ),
            ),

            // LAYER 3: Top & Bottom Vignette Fades
            Positioned.fill(
              child: IgnorePointer(
                child: Column(
                  children: [
                    Container(
                      height: screenHeight * 0.28,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF050805),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: screenHeight * 0.28,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xFF050805),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // LAYER 4: Foreground Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildAnimatedLogo(),
                        const SizedBox(height: 32),
                        _buildBrandName(),
                        const SizedBox(height: 8),
                        _buildTagline(),
                        const SizedBox(height: 40),
                        _buildLoadingBar(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 3 Expanding Ripple Rings
          AnimatedBuilder(
            animation: _rippleController,
            builder: (context, _) {
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  _buildRing((_rippleController.value + 0.0) % 1.0),
                  _buildRing((_rippleController.value + (0.9 / 2.6)) % 1.0),
                  _buildRing((_rippleController.value + (1.8 / 2.6)) % 1.0),
                ],
              );
            },
          ),

          // Floating Glassmorphic Logo
          AnimatedBuilder(
            animation: Listenable.merge([_entranceController, _floatController]),
            builder: (context, child) {
              final popScale = Tween<double>(begin: 0.6, end: 1.0).evaluate(
                CurvedAnimation(
                  parent: _entranceController,
                  curve: const Cubic(0.2, 0.9, 0.3, 1.2),
                ),
              );

              final floatOffset = math.sin(_floatController.value * 2 * math.pi) * 6;

              return Transform.translate(
                offset: Offset(0, floatOffset),
                child: Transform.scale(
                  scale: popScale,
                  child: child,
                ),
              );
            },
            child: _buildLogoBadge(),
          ),
        ],
      ),
    );
  }

  Widget _buildRing(double progress) {
    final scale = 0.8 + (1.1 * progress);
    final opacity = (0.7 * (1.0 - progress)).clamp(0.0, 1.0);

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 132,
        height: 132,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: const Color(0xFF6FE3A0).withValues(alpha: opacity * 0.75),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoBadge() {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.75),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: const Color(0xFF3FD483).withValues(alpha: 0.55),
            blurRadius: 50,
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Center(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFB9F5D3),
                  Color(0xFF6FE3A0),
                ],
                stops: [0.1, 0.6, 1.0],
              ).createShader(bounds),
              child: const Text(
                'S',
                style: TextStyle(
                  fontSize: 66,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -2.0,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandName() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        final progress = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
        ).value;

        return Transform.translate(
          offset: Offset(0, (1.0 - progress) * 8),
          child: Opacity(
            opacity: progress,
            child: child,
          ),
        );
      },
      child: RichText(
        text: const TextSpan(
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: Colors.white,
          ),
          children: [
            TextSpan(text: 'servi'),
            TextSpan(
              text: 'ko',
              style: TextStyle(color: Color(0xFF6FE3A0)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        final progress = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
        ).value;

        return Transform.translate(
          offset: Offset(0, (1.0 - progress) * 8),
          child: Opacity(
            opacity: progress,
            child: child,
          ),
        );
      },
      child: Text(
        'Skilled help, right in your barangay',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.60),
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildLoadingBar() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        final opacity = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
        ).value;

        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: Container(
        width: 120,
        height: 4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          color: Colors.white.withValues(alpha: 0.14),
        ),
        clipBehavior: Clip.antiAlias,
        child: AnimatedBuilder(
          animation: _barController,
          builder: (context, _) {
            final dx = -48.0 + (168.0 * _barController.value);

            return Transform.translate(
              offset: Offset(dx, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0x006FE3A0),
                        Color(0xFF6FE3A0),
                        Colors.white,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
