import 'package:flutter/cupertino.dart';

import 'package:coffeetimer/splash_particle.dart';
import 'package:coffeetimer/water_layer.dart';

class WaterPainter extends CustomPainter {
  final WaterLayer layer01;
  final double tilt;
  final List<Offset> activeDrops;
  final List<SplashParticle> particles;
  final double surfaceYRatio;

  WaterPainter(this.layer01, this.tilt, this.activeDrops, this.particles, this.surfaceYRatio);

  final Paint _mainPaint = Paint();
  final Path _surfacePath = Path();

  @override
  void paint(Canvas canvas, Size size) {
    _drawSurface(canvas, size);
    _mainPaint.shader = null;
    _mainPaint.color = const Color(0xFF0E0000);
    for (final pos in activeDrops) {
      canvas.drawCircle(pos, 5, _mainPaint);
    }
    for (final p in particles) {
      _mainPaint.color = const Color(0xFF0E0000).withValues(alpha: p.opacity.clamp(0, 1));
      canvas.drawCircle(p.position, 2, _mainPaint);
    }
  }

  void _drawSurface(Canvas canvas, Size size) {
    _mainPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [Color(0xFF0E0000), Color(0xFF701111)],
      stops: [surfaceYRatio,1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    _surfacePath.reset();
    final double colWidth = size.width / (WaterLayer.columns - 1);
    _surfacePath.moveTo(0, size.height);
    for (int i = 0; i < WaterLayer.columns; i++) {
      _surfacePath.lineTo(i * colWidth, layer01.cachedY[i]);
    }
    _surfacePath.lineTo(size.width, size.height);
    _surfacePath.close();
    canvas.drawPath(_surfacePath, _mainPaint);
  }

  @override
  bool shouldRepaint(covariant WaterPainter oldDelegate) => true;
}
