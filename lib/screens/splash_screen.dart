import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  bool _checkingAuth = true;
  final bool _isLoggedIn = false;
  
  late PageController _pageController;
  int _currentPage = 0;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Single animation controller to prevent conflicts
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Setup animations with single controller
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    
    // Start animation
    _animationController.forward();
    _checkAuthAndHydrate();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndHydrate() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _checkingAuth = false;
      });
    }
  }

  void _onGetStarted() {
    Navigator.of(context).pushReplacementNamed('/sign-in');
  }
  
  void _onPageChanged(int page) {
    if (_currentPage != page) {
      setState(() {
        _currentPage = page;
      });
      
      // Smooth animation restart
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final secondaryBrandColor = isDark ? AppColors.primaryDark : const Color(0xFF26A69A);
    final headingColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final bodyTextColor = isDark ? const Color(0xFFBCC9C6) : AppColors.textSubLight;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Optimized background with RepaintBoundary
          RepaintBoundary(
            child: _buildOptimizedBackground(isDark),
          ),

          // PageView for scrollable content
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildPage(
                context,
                size,
                isDark,
                brandColor,
                secondaryBrandColor,
                headingColor,
                bodyTextColor,
                Icons.auto_awesome_rounded,
                'Track Your\nWealth',
                'Transform your daily spending into a masterpiece of financial clarity.',
                showButton: false,
              ),
              _buildPage(
                context,
                size,
                isDark,
                brandColor,
                secondaryBrandColor,
                headingColor,
                bodyTextColor,
                Icons.receipt_long_rounded,
                'Track Every\nTransaction',
                'Monitor your income, expenses, and transfers with beautiful insights and reports.',
                showButton: false,
              ),
              _buildPage(
                context,
                size,
                isDark,
                brandColor,
                secondaryBrandColor,
                headingColor,
                bodyTextColor,
                Icons.pie_chart_rounded,
                'Smart Budget\nManagement',
                'Set budgets, get alerts, and achieve your financial goals with intelligent insights.',
                showButton: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildOptimizedBackground(bool isDark) {
    return Stack(
      children: [
        // Simplified glow effects
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark ? const Color(0xFF66D9CC) : const Color(0xFF84F5E8)).withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 50,
          left: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark ? AppColors.expenseDark : const Color(0xFFCFE6F2)).withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPage(
    BuildContext context,
    Size size,
    bool isDark,
    Color brandColor,
    Color secondaryColor,
    Color headingColor,
    Color bodyTextColor,
    IconData icon,
    String heading,
    String body,
    {required bool showButton}
  ) {
    // Responsive sizing
    final isSmallScreen = size.width < 360;
    final isMediumScreen = size.width >= 360 && size.width < 400;
    
    final iconSize = isSmallScreen ? 36.0 : (isMediumScreen ? 40.0 : 44.0);
    final headingSize = isSmallScreen ? 36.0 : (isMediumScreen ? 40.0 : 44.0);
    final bodySize = isSmallScreen ? 14.0 : (isMediumScreen ? 16.0 : 18.0);
    final heroSize = isSmallScreen ? 160.0 : (isMediumScreen ? 180.0 : 200.0);
    
    return SafeArea(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(
                0,
                _slideAnimation.value.dy * 50,
              ),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.08,
                      vertical: 20,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Header
                        Column(
                          children: [
                            SizedBox(height: size.height * 0.02),
                            Icon(
                              Icons.account_balance_wallet_rounded,
                              color: brandColor,
                              size: 28,
                            ),
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
                        ),
                        
                        // Hero Section
                        Transform.scale(
                          scale: _scaleAnimation.value,
                          child: RepaintBoundary(
                            child: _buildSimplifiedHero(
                              isDark,
                              brandColor,
                              icon,
                              heroSize,
                              iconSize,
                            ),
                          ),
                        ),
                        
                        // Content
                        Column(
                          children: [
                            // Page Indicator - Above heading
                            _buildPageIndicator(brandColor, isDark),
                            SizedBox(height: size.height * 0.03),
                            
                            _buildContent(
                              headingColor,
                              bodyTextColor,
                              brandColor,
                              secondaryColor,
                              heading,
                              body,
                              headingSize,
                              bodySize,
                            ),
                            SizedBox(height: size.height * 0.04),
                            
                            // Button or Hint
                            if (showButton)
                              _buildButton(isDark, brandColor, secondaryColor)
                            else
                              _buildSwipeHint(bodyTextColor),
                          ],
                        ),
                        
                        SizedBox(height: size.height * 0.02),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSimplifiedHero(
    bool isDark,
    Color brandColor,
    IconData icon,
    double size,
    double iconSize,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            (isDark ? const Color(0xFF66D9CC) : const Color(0xFF26A69A)).withValues(alpha: 0.2),
            Colors.transparent,
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: size * 0.7,
          height: size * 0.7,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.5)),
            shape: BoxShape.circle,
            border: Border.all(
              color: (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.5)),
              width: 1,
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    Color headingColor,
    Color bodyTextColor,
    Color brandColor,
    Color secondaryColor,
    String heading,
    String body,
    double headingSize,
    double bodySize,
  ) {
    final headingParts = heading.split('\n');
    final lastWord = headingParts.length > 1 ? headingParts.last : '';
    final firstPart = headingParts.length > 1 ? '${headingParts.first}\n' : heading;
    
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.manrope(
              fontSize: headingSize,
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
                        fontSize: headingSize,
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
        const SizedBox(height: 16),
        Text(
          body,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: bodySize,
            height: 1.5,
            color: bodyTextColor,
          ),
        ),
      ],
    );
  }
  
  Widget _buildButton(bool isDark, Color brandColor, Color secondaryColor) {
    if (_checkingAuth || _isLoggedIn) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onGetStarted,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: isDark 
                ? null 
                : LinearGradient(colors: [brandColor, secondaryColor]),
            color: isDark ? const Color(0xFF26A69A) : null,
            boxShadow: [
              BoxShadow(
                color: (isDark ? AppColors.primaryDark : brandColor).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Get Started',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF003430) : Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: isDark ? const Color(0xFF003430) : Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSwipeHint(Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Swipe to continue',
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: textColor.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          Icons.arrow_forward_ios,
          size: 12,
          color: textColor.withValues(alpha: 0.6),
        ),
      ],
    );
  }
  
  Widget _buildPageIndicator(Color brandColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isActive 
                ? brandColor 
                : (isDark ? AppColors.cardDark : AppColors.surfaceContainerHighLight),
          ),
        );
      }),
    );
  }
}
