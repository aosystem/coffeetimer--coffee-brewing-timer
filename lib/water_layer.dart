class WaterLayer {
  static const int columns = 50;
  List<double> heights = List.filled(columns, 0.0);
  List<double> velocities = List.filled(columns, 0.0);
  final double tension;
  final double damping;
  final double spread;

  WaterLayer({required this.tension, required this.damping, required this.spread});

  List<double> cachedY = List.filled(columns, 0.0);

  void updateSurfaceCache(double viewWidth, double viewHeight, double tiltAngle, double surfaceYRatio) {
    double centerY = viewHeight * surfaceYRatio;
    for (int i = 0; i < columns; i++) {
      double tiltEffect = (i / (columns - 1) - 0.5) * viewWidth * tiltAngle;
      cachedY[i] = centerY + tiltEffect + heights[i].clamp(-150.0, 150.0);
    }
  }
  double getCachedY(double xPos, double viewWidth) {
    double colWidth = viewWidth / (columns - 1);
    int index = (xPos / colWidth).floor().clamp(0, columns - 1);
    return cachedY[index];
  }

  void updatePhysics() {
    for (int i = 0; i < columns; i++) {
      velocities[i] += tension * (0 - heights[i]);
      heights[i] += velocities[i];
      velocities[i] *= damping;
    }

    List<double> leftDeltas = List.filled(columns, 0.0);
    List<double> rightDeltas = List.filled(columns, 0.0);
    for (int t = 0; t < 4; t++) {
      for (int i = 0; i < columns; i++) {
        if (i > 0) {
          leftDeltas[i] = spread * (heights[i] - heights[i - 1]);
          velocities[i - 1] += leftDeltas[i];
        }
        if (i < columns - 1) {
          rightDeltas[i] = spread * (heights[i] - heights[i + 1]);
          velocities[i + 1] += rightDeltas[i];
        }
      }
      for (int i = 0; i < columns; i++) {
        if (i > 0) {
          heights[i - 1] += leftDeltas[i];
        }
        if (i < columns - 1) {
          heights[i + 1] += rightDeltas[i];
        }
      }
    }
  }

  void splash(double xPos, double viewWidth, double force) {
    int index = ((xPos / viewWidth) * columns).floor().clamp(0, columns - 1);
    velocities[index] = force;
  }

  double getSurfaceY(double xPos, double viewWidth, double viewHeight, double tiltAngle, double surfaceYRatio) {
    double colWidth = viewWidth / (columns - 1);
    int index = (xPos / colWidth).floor().clamp(0, columns - 1);
    double centerY = viewHeight * surfaceYRatio;
    double tiltEffect = (index / (columns - 1) - 0.5) * viewWidth * tiltAngle;
    return centerY + tiltEffect + heights[index];
  }
}
