import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  bool _checkingAuth = true;
  final bool _isLoggedIn = false;
  
  late PageController _pageController;
  int _currentPage = 0;
  
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Setup animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    _slideController.forward();
    
    _checkAuthAndHydrate();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndHydrate() async {
    setState(() {
      _checkingAuth = false;
    });
  }

  void _onGetStarted() {
    Navigator.of(context).pushReplacementNamed('/sign-in');
  }
  
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    
    // Restart animations for new page
    _fadeController.reset();
    _scaleController.reset();
    _slideController.reset();
    
    _fadeController.forward();
    _scaleController.forward();
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Derived from Figma
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final brandColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final secondaryBrandColor = isDark ? AppColors.primaryDark : const Color(0xFF26A69A);
    final headingColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final bodyTextColor = isDark ? const Color(0xFFBCC9C6) : AppColors.textSubLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background Decorative Shapes
          _buildAmbientShapes(cs, isDark),

          // PageView for scrollable content
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              // Page 1: Welcome
              _buildPage1(cs, isDark, brandColor, secondaryBrandColor, headingColor, bodyTextColor),
              
              // Page 2: Track Expenses
              _buildPage2(cs, isDark, brandColor, secondaryBrandColor, headingColor, bodyTextColor),
              
              // Page 3: Get Started
              _buildPage3(cs, isDark, brandColor, secondaryBrandColor, headingColor, bodyTextColor),
            ],
          ),

          // Page Indicator
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: _buildPageIndicator(brandColor, isDark),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPage1(ColorScheme cs, bool isDark, Color brandColor, Color secondaryColor, Color headingColor, Color bodyTextColor) {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildHeader(brandColor),
              const Spacer(),
              ScaleTransition(
                scale: _scaleAnimation,
                child: _buildHeroSection(cs, isDark),
              ),
              const Spacer(),
              _buildContent(
                headingColor,
                bodyTextColor,
                brandColor,
                secondaryColor,
                'Track Your\nWealth',
                'Transform your daily spending into a masterpiece of financial clarity.',
              ),
              const SizedBox(height: 48),
              _buildSwipeHint(bodyTextColor),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPage2(ColorScheme cs, bool isDark, Color brandColor, Color secondaryColor, Color headingColor, Color bodyTextColor) {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildHeader(brandColor),
              const Spacer(),
              ScaleTransition(
                scale: _scaleAnimation,
                child: _buildTrackingSection(cs, isDark, brandColor),
              ),
              const Spacer(),
              _buildContent(
                headingColor,
                bodyTextColor,
                brandColor,
                secondaryColor,
                'Track Every\nTransaction',
                'Monitor your income, expenses, and transfers with beautiful insights and reports.',
              ),
              const SizedBox(height: 48),
              _buildSwipeHint(bodyTextColor),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPage3(ColorScheme cs, bool isDark, Color brandColor, Color secondaryColor, Color headingColor, Color bodyTextColor) {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildHeader(brandColor),
              const Spacer(),
              ScaleTransition(
                scale: _scaleAnimation,
                child: _buildBudgetSection(cs, isDark, brandColor),
              ),
              const Spacer(),
              _buildContent(
                headingColor,
                bodyTextColor,
                brandColor,
                secondaryColor,
                'Smart Budget\nManagement',
                'Set budgets, get alerts, and achieve your financial goals with intelligent insights.',
              ),
              const SizedBox(height: 48),
              _buildFooter(cs, isDark, brandColor, secondaryColor),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPageIndicator(Color brandColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isActive 
                ? brandColor 
                : (isDark ? AppColors.cardDark : AppColors.surfaceContainerHighLight),
            boxShadow: isActive ? [
              BoxShadow(
                color: brandColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
        );
      }),
    );
  }
  
  Widget _buildSwipeHint(Color textColor) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Swipe to continue',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: textColor.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: textColor.withValues(alpha: 0.6),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAmbientShapes(ColorScheme cs, bool isDark) {
    return Stack(
      children: [
        // Top Right Glow
        Positioned(
          top: -100,
          right: -100,
          child: _GlowCircle(
            size: 500,
            color: isDark 
                ? const Color(0xFF66D9CC).withValues(alpha: 0.1)
                : const Color(0xFF84F5E8).withValues(alpha: 0.2),
            blur: 50,
          ),
        ),
        // Bottom Left Glow
        Positioned(
          bottom: 100,
          left: -100,
          child: _GlowCircle(
            size: 400,
            color: isDark
                ? AppColors.expenseDark.withValues(alpha: 0.1)
                : const Color(0xFFCFE6F2).withValues(alpha: 0.3),
            blur: 40,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Color brandColor) {
    return Column(
      children: [
        Icon(Icons.account_balance_wallet_rounded, color: brandColor, size: 28),
        const SizedBox(height: 12),
        Text(
          'SPNDLY',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.8,
            color: brandColor,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(ColorScheme cs, bool isDark) {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main Background Glow
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isDark ? const Color(0xFF66D9CC) : const Color(0xFF26A69A)).withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),

          // Central Glass Card
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(48),
              border: Border.all(
                color: (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 50,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(48),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 44,
                      color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Floating Accents
          // Top Right Accent (Trend)
          Positioned(
            top: 40,
            right: 40,
            child: _FloatingAccent(
              icon: Icons.trending_up_rounded,
              iconColor: Colors.white,
              bgColor: const Color(0xFF84292D),
              isDark: isDark,
            ),
          ),
          // Bottom Left Accent (Diamond)
          Positioned(
            bottom: 40,
            left: 40,
            child: _FloatingAccent(
              icon: Icons.diamond_outlined,
              iconColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              bgColor: (isDark ? AppColors.primaryDark : const Color(0xFF84F5E8)).withValues(alpha: 0.2),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Color headingColor, Color bodyTextColor, Color brandColor, Color secondaryColor, String heading, String body) {
    final headingParts = heading.split('\n');
    final lastWord = headingParts.length > 1 ? headingParts.last : '';
    final firstPart = headingParts.length > 1 ? '${headingParts.first}\n' : heading;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.manrope(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                height: 1.1,
                letterSpacing: -1.2,
                color: headingColor,
              ),
              children: [
                TextSpan(text: firstPart),
                if (lastWord.isNotEmpty)
                  WidgetSpan(
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [brandColor, secondaryColor],
                      ).createShader(Offset.zero & bounds.size),
                      child: Text(
                        lastWord,
                        style: GoogleFonts.manrope(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          letterSpacing: -1.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            body,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 18,
              height: 1.5,
              color: bodyTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ColorScheme cs, bool isDark, Color brandColor, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // CTA Button - Only show on last page
          if (!_isLoggedIn && !_checkingAuth && _currentPage == 2)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: GestureDetector(
                      onTap: _onGetStarted,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: isDark 
                              ? null 
                              : LinearGradient(colors: [brandColor, secondaryColor]),
                          color: isDark ? const Color(0xFF26A69A) : null,
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? AppColors.primaryDark : brandColor).withValues(alpha: 0.25),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Get Started',
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF003430) : Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: isDark ? const Color(0xFF003430) : Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            )
          else if (_checkingAuth || _isLoggedIn)
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
  
  Widget _buildTrackingSection(ColorScheme cs, bool isDark, Color brandColor) {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isDark ? const Color(0xFF66D9CC) : const Color(0xFF26A69A)).withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),

          // Central Card
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(48),
              border: Border.all(
                color: (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 50,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(48),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      size: 44,
                      color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Floating Accents
          Positioned(
            top: 40,
            right: 40,
            child: _FloatingAccent(
              icon: Icons.add_circle_outline,
              iconColor: Colors.white,
              bgColor: const Color(0xFF26A69A),
              isDark: isDark,
            ),
          ),
          Positioned(
            bottom: 40,
            left: 40,
            child: _FloatingAccent(
              icon: Icons.analytics_outlined,
              iconColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              bgColor: (isDark ? AppColors.primaryDark : const Color(0xFF84F5E8)).withValues(alpha: 0.2),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBudgetSection(ColorScheme cs, bool isDark, Color brandColor) {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isDark ? const Color(0xFF66D9CC) : const Color(0xFF26A69A)).withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),

          // Central Card
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(48),
              border: Border.all(
                color: (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 50,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(48),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.pie_chart_rounded,
                      size: 44,
                      color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Floating Accents
          Positioned(
            top: 40,
            right: 40,
            child: _FloatingAccent(
              icon: Icons.notifications_active_outlined,
              iconColor: Colors.white,
              bgColor: const Color(0xFFFF9800),
              isDark: isDark,
            ),
          ),
          Positioned(
            bottom: 40,
            left: 40,
            child: _FloatingAccent(
              icon: Icons.savings_outlined,
              iconColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              bgColor: (isDark ? AppColors.primaryDark : const Color(0xFF84F5E8)).withValues(alpha: 0.2),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double blur;

  const _GlowCircle({
    required this.size,
    required this.color,
    required this.blur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: blur,
            spreadRadius: 0,
          ),
        ],
      ),
    );
  }
}

class _FloatingAccent extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final bool isDark;

  const _FloatingAccent({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.cardDark : Colors.white).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 25,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 8,
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.textPrimaryDark : AppColors.textSubLight).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: 8,
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.textPrimaryDark : AppColors.textSubLight).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

