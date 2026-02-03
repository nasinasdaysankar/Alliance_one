import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

/// ANIMATED SPLASH SCREEN - Alliance One 4.0
/// Features: Flexible ribbon animation + Smooth spiral morph to circle

class SplashScreen extends StatefulWidget {
  final Widget? nextScreen;
  final Duration duration;

  const SplashScreen({
    super.key,
    this.nextScreen,
    this.duration = const Duration(milliseconds: 6500),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pathController;
  late AnimationController _morphController;
  late AnimationController _spinController;
  
  late Animation<double> _pathProgress;
  late Animation<double> _morph;
  late Animation<double> _textFade;
  late Animation<double> _badgeScale;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    // Path animation - ribbon flows through curved path
    _pathController = AnimationController(
      duration: const Duration(milliseconds: 3200),
      vsync: this,
    );
    
    // Morph animation - smoother and longer for spiral effect
    _morphController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    
    _spinController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
    
    _pathProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pathController,
        curve: Curves.easeInOutSine,
      ),
    );
    
    // Use a smooth elastic curve for natural spiral-in effect
    _morph = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _morphController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.62, 0.78, curve: Curves.easeIn),
      ),
    );
    
    _badgeScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 40),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.72, 0.88),
      ),
    );
    
    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 0.95),
      ),
    );
    
    // Start animations
    _mainController.forward();
    _pathController.forward();
    
    // Start morph after path completes - with slight overlap for smoothness
    _pathController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _morphController.forward();
      }
    });
    
    // Start spinning after morph
    _morphController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _spinController.repeat();
      }
    });
    
    // Navigate
    Future.delayed(widget.duration + const Duration(milliseconds: 400), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => widget.nextScreen ?? const HomeScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pathController.dispose();
    _morphController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final centerY = screenSize.height / 2 - 80;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.deepIndigo,
              AppColors.royalPurple,
              AppColors.midPurple,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Flexible Ribbon SDG Strip
            AnimatedBuilder(
              animation: Listenable.merge([_pathController, _morphController, _spinController]),
              builder: (context, _) {
                return CustomPaint(
                  size: screenSize,
                  painter: FlexibleRibbonPainter(
                    pathProgress: _pathProgress.value,
                    morphProgress: _morph.value,
                    spinAngle: _morphController.isCompleted ? _spinController.value * 2 * math.pi : 0.0,
                    screenSize: screenSize,
                    isPathComplete: _pathController.isCompleted,
                  ),
                );
              },
            ),
            
            // ALLIANCE text
            Positioned(
              top: centerY + 110,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, _) {
                  return Opacity(
                    opacity: _textFade.value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _textFade.value)),
                      child: Text(
                        "ALLIANCE",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color: AppColors.pureWhite,
                          letterSpacing: 8,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // ONE 4.0
            Positioned(
              top: centerY + 165,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: _textFade.value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - _textFade.value)),
                          child: Text(
                            "ONE",
                            style: GoogleFonts.poppins(
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              color: AppColors.pureWhite,
                              letterSpacing: 6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Transform.scale(
                        scale: _badgeScale.value.clamp(0.01, 1.5),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: AppGradients.cyanButton,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.brightCyan.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            "4.0",
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.pureWhite,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            
            // Loading bar
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, _) {
                  return Opacity(
                    opacity: _textFade.value,
                    child: Column(
                      children: [
                        Container(
                          width: 220,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.glassWhite,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 50),
                                  width: 220 * _progress.value.clamp(0.0, 1.0),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AppColors.vibrantOrange, AppColors.brightCyan],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "${(_progress.value * 100).toInt()}%",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.pureWhite.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints a flexible ribbon that flows and smoothly spirals into a circle
class FlexibleRibbonPainter extends CustomPainter {
  final double pathProgress;
  final double morphProgress;
  final double spinAngle;
  final Size screenSize;
  final bool isPathComplete;
  
  FlexibleRibbonPainter({
    required this.pathProgress,
    required this.morphProgress,
    required this.spinAngle,
    required this.screenSize,
    required this.isPathComplete,
  });
  
  final List<Color> sdgColors = [
    const Color(0xFFE5243B), const Color(0xFFDDA63A), const Color(0xFF4C9F38),
    const Color(0xFFC5192D), const Color(0xFFFF3A21), const Color(0xFF26BDE2),
    const Color(0xFFFCC30B), const Color(0xFFA21942), const Color(0xFFFD6925),
    const Color(0xFFDD1367), const Color(0xFFFD9D24), const Color(0xFFBF8B2E),
    const Color(0xFF3F7E44), const Color(0xFF0A97D9), const Color(0xFF56C02B),
    const Color(0xFF00689D), const Color(0xFF19486A),
  ];

  /// Get position along a flowing curved path
  Offset _getPathPosition(double t, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2 - 80;
    
    final extendedT = t.clamp(0.0, 1.0);
    
    if (extendedT < 0.2) {
      final localT = extendedT / 0.2;
      return _cubicBezier(
        Offset(size.width + 50, -50),
        Offset(size.width * 0.9, size.height * 0.25),
        Offset(size.width * 0.6, size.height * 0.5),
        Offset(size.width * 0.25, size.height * 0.65),
        localT,
      );
    } else if (extendedT < 0.4) {
      final localT = (extendedT - 0.2) / 0.2;
      return _cubicBezier(
        Offset(size.width * 0.25, size.height * 0.65),
        Offset(-size.width * 0.05, size.height * 0.7),
        Offset(size.width * 0.1, size.height * 0.35),
        Offset(size.width * 0.3, size.height * 0.2),
        localT,
      );
    } else if (extendedT < 0.6) {
      final localT = (extendedT - 0.4) / 0.2;
      return _cubicBezier(
        Offset(size.width * 0.3, size.height * 0.2),
        Offset(size.width * 0.5, -size.height * 0.05),
        Offset(size.width * 0.75, size.height * 0.15),
        Offset(size.width * 0.8, size.height * 0.4),
        localT,
      );
    } else if (extendedT < 0.8) {
      final localT = (extendedT - 0.6) / 0.2;
      return _cubicBezier(
        Offset(size.width * 0.8, size.height * 0.4),
        Offset(size.width * 0.85, size.height * 0.55),
        Offset(size.width * 0.7, size.height * 0.5),
        Offset(centerX + 40, centerY + 20),
        localT,
      );
    } else {
      final localT = (extendedT - 0.8) / 0.2;
      return _cubicBezier(
        Offset(centerX + 40, centerY + 20),
        Offset(centerX + 20, centerY - 10),
        Offset(centerX - 10, centerY + 5),
        Offset(centerX, centerY),
        localT,
      );
    }
  }
  
  Offset _cubicBezier(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final u = 1 - t;
    final x = u*u*u*p0.dx + 3*u*u*t*p1.dx + 3*u*t*t*p2.dx + t*t*t*p3.dx;
    final y = u*u*u*p0.dy + 3*u*u*t*p1.dy + 3*u*t*t*p2.dy + t*t*t*p3.dy;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final numSegments = sdgColors.length;
    final center = Offset(size.width / 2, size.height / 2 - 80);
    
    // Circle properties
    final wheelRadius = 75.0;
    final innerRadius = wheelRadius * 0.55;
    final segmentAngle = (2 * math.pi) / numSegments;
    
    // Ribbon properties
    final ribbonWidth = 20.0;
    final segmentSpacing = 0.035;
    
    for (int i = 0; i < numSegments; i++) {
      // Each segment trails behind
      final segmentT = (pathProgress - i * segmentSpacing).clamp(0.0, 1.0);
      
      if (segmentT <= 0 && morphProgress <= 0) continue;
      
      // Get ribbon position from path
      Offset ribbonPos = _getPathPosition(segmentT, screenSize);
      
      // Calculate path tangent for ribbon rotation
      final nextT = (segmentT + 0.01).clamp(0.0, 1.0);
      final nextPos = _getPathPosition(nextT, screenSize);
      double ribbonAngle = math.atan2(nextPos.dy - ribbonPos.dy, nextPos.dx - ribbonPos.dx);
      
      // Target position on circle (each segment spirals to its spot)
      final targetCircleAngle = i * segmentAngle - math.pi / 2 + spinAngle;
      final midRadius = innerRadius + (wheelRadius - innerRadius) / 2;
      final circlePos = Offset(
        center.dx + midRadius * math.cos(targetCircleAngle),
        center.dy + midRadius * math.sin(targetCircleAngle),
      );
      
      if (isPathComplete && morphProgress > 0) {
        // SMOOTH SPIRAL TRANSITION
        // Add a spiral offset that decreases as morph progresses
        final spiralRadius = (1 - morphProgress) * 80; // Spiral inward
        final spiralAngle = targetCircleAngle + (1 - morphProgress) * math.pi * 2; // Extra rotation during spiral
        
        final spiralOffset = Offset(
          spiralRadius * math.cos(spiralAngle),
          spiralRadius * math.sin(spiralAngle),
        );
        
        // Smooth interpolation from ribbon position to circle position
        final easeT = Curves.easeOutCubic.transform(morphProgress);
        ribbonPos = Offset.lerp(ribbonPos, circlePos + spiralOffset * (1 - easeT), easeT)!;
        
        // Angle transitions smoothly to radial orientation
        ribbonAngle = _lerpAngle(ribbonAngle, targetCircleAngle + math.pi / 2, easeT);
      }
      
      // Draw segment as morphing shape
      _drawMorphingSegment(
        canvas, 
        ribbonPos, 
        ribbonAngle, 
        center,
        innerRadius,
        wheelRadius,
        i,
        segmentAngle,
        spinAngle,
        ribbonWidth,
        sdgColors[i], 
        morphProgress,
      );
    }
  }
  
  void _drawMorphingSegment(
    Canvas canvas,
    Offset ribbonPos,
    double ribbonAngle,
    Offset circleCenter,
    double innerR,
    double outerR,
    int index,
    double segAngle,
    double spin,
    double ribbonWidth,
    Color color,
    double morphT,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Ribbon shape corners (rectangle aligned with path)
    final segmentLength = 18.0 + morphT * 8; // Slightly grow during morph
    final halfLen = segmentLength / 2;
    final halfWid = ribbonWidth / 2;
    
    final cosA = math.cos(ribbonAngle);
    final sinA = math.sin(ribbonAngle);
    
    // Four corners of ribbon segment
    final r0 = Offset(ribbonPos.dx - halfLen * cosA - halfWid * sinA, 
                      ribbonPos.dy - halfLen * sinA + halfWid * cosA);
    final r1 = Offset(ribbonPos.dx + halfLen * cosA - halfWid * sinA, 
                      ribbonPos.dy + halfLen * sinA + halfWid * cosA);
    final r2 = Offset(ribbonPos.dx + halfLen * cosA + halfWid * sinA, 
                      ribbonPos.dy + halfLen * sinA - halfWid * cosA);
    final r3 = Offset(ribbonPos.dx - halfLen * cosA + halfWid * sinA, 
                      ribbonPos.dy - halfLen * sinA - halfWid * cosA);
    
    // Circle arc shape corners
    final startAngle = index * segAngle - math.pi / 2 + spin;
    final endAngle = startAngle + segAngle * 0.92;
    
    final c0 = Offset(circleCenter.dx + innerR * math.cos(startAngle),
                      circleCenter.dy + innerR * math.sin(startAngle));
    final c1 = Offset(circleCenter.dx + outerR * math.cos(startAngle),
                      circleCenter.dy + outerR * math.sin(startAngle));
    final c2 = Offset(circleCenter.dx + outerR * math.cos(endAngle),
                      circleCenter.dy + outerR * math.sin(endAngle));
    final c3 = Offset(circleCenter.dx + innerR * math.cos(endAngle),
                      circleCenter.dy + innerR * math.sin(endAngle));
    
    // Smoothly interpolate corners
    final easeT = Curves.easeOutCubic.transform(morphT);
    final p0 = Offset.lerp(r0, c0, easeT)!;
    final p1 = Offset.lerp(r1, c1, easeT)!;
    final p2 = Offset.lerp(r2, c2, easeT)!;
    final p3 = Offset.lerp(r3, c3, easeT)!;
    
    // Draw as smooth path
    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();
    
    canvas.drawPath(path, paint);
  }
  
  double _lerpAngle(double from, double to, double t) {
    double diff = to - from;
    while (diff > math.pi) diff -= 2 * math.pi;
    while (diff < -math.pi) diff += 2 * math.pi;
    return from + diff * t;
  }

  @override
  bool shouldRepaint(FlexibleRibbonPainter oldDelegate) =>
      oldDelegate.pathProgress != pathProgress ||
      oldDelegate.morphProgress != morphProgress ||
      oldDelegate.spinAngle != spinAngle;
}
