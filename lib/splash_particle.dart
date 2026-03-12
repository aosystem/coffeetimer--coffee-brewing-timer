import 'dart:ui';

class SplashParticle {
  Offset position;
  Offset velocity;
  double opacity = 1.0;
  SplashParticle({required this.position, required this.velocity});

  void update(double surfaceY) {
    position += velocity;
    velocity += const Offset(0, 0.5);
    opacity -= 0.02;
    if (position.dy > surfaceY) opacity = 0;
  }
}
