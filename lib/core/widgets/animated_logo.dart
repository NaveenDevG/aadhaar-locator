import 'package:flutter/material.dart';

class AnimatedLogo extends StatefulWidget {
  final double size;
  final bool showText;
  final Duration animationDuration;
  final bool autoAnimate;

  const AnimatedLogo({
    super.key,
    this.size = 80.0,
    this.showText = true,
    this.animationDuration = const Duration(seconds: 2),
    this.autoAnimate = true,
  });

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _rotationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Initialize animations
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1, // Small rotation for subtle effect
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations if autoAnimate is enabled
    if (widget.autoAnimate) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    // Start with scale and fade
    _scaleController.forward();
    _fadeController.forward();
    
    // Start rotation after a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _rotationController.repeat(reverse: true);
      }
    });
    
    // Start pulse after scale completes
    _scaleController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _rotationAnimation,
        _scaleAnimation,
        _fadeAnimation,
        _pulseAnimation,
      ]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.scale(
            scale: _scaleAnimation.value * _pulseAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Logo Container
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFFFF6B35),
                          Color(0xFFE55A2B),
                        ],
                        stops: [0.0, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(widget.size * 0.25),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated background glow
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: widget.size * 0.8,
                              height: widget.size * 0.8,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(widget.size * 0.2),
                              ),
                            );
                          },
                        ),
                        
                        // Shield container
                        Container(
                          width: widget.size * 0.6,
                          height: widget.size * 0.6,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(widget.size * 0.1),
                            border: Border.all(
                              color: const Color(0xFFE0E0E0),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Animated shield shape
                              CustomPaint(
                                size: Size(widget.size * 0.4, widget.size * 0.4),
                                painter: AnimatedShieldPainter(
                                  animation: _pulseAnimation,
                                ),
                              ),
                              
                              // Animated location pin
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 0.8 + (_pulseAnimation.value - 1.0) * 0.3,
                                    child: const Icon(
                                      Icons.location_on,
                                      size: 20,
                                      color: Color(0xFFFF6B35),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // App name text with animation
                  if (widget.showText) ...[
                    const SizedBox(height: 12),
                    AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 10 * (1 - _fadeAnimation.value)),
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: const Text(
                              'Rakshak',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF6B35),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AnimatedShieldPainter extends CustomPainter {
  final Animation<double> animation;

  AnimatedShieldPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B35)
      ..style = PaintingStyle.fill;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Create shield shape with animation
    final scale = 0.9 + (animation.value - 1.0) * 0.1;
    final scaledSize = size * scale;
    final offsetX = (size.width - scaledSize.width) / 2;
    final offsetY = (size.height - scaledSize.height) / 2;
    
    path.moveTo(centerX, offsetY + scaledSize.height * 0.2); // Top point
    path.lineTo(offsetX + scaledSize.width * 0.7, offsetY + scaledSize.height * 0.4); // Top right
    path.lineTo(offsetX + scaledSize.width * 0.7, offsetY + scaledSize.height * 0.7); // Right side
    path.lineTo(centerX, offsetY + scaledSize.height * 0.9); // Bottom point
    path.lineTo(offsetX + scaledSize.width * 0.3, offsetY + scaledSize.height * 0.7); // Left side
    path.lineTo(offsetX + scaledSize.width * 0.3, offsetY + scaledSize.height * 0.4); // Top left
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

