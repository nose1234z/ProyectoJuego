import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HealthBar extends PositionComponent {
  double currentHealth;
  double maxHealth;
  double barWidth;
  double barHeight;
  Color fillColor;
  Color backgroundColor;

  HealthBar({
    required this.currentHealth,
    required this.maxHealth,
    this.barWidth = 50,
    this.barHeight = 5,
    this.fillColor = Colors.green,
    this.backgroundColor = Colors.red,
    super.position,
  }) : super(size: Vector2(barWidth, barHeight));

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw background bar
    canvas.drawRect(
      Rect.fromLTWH(0, 0, barWidth, barHeight),
      Paint()..color = backgroundColor,
    );

    // Draw health fill
    final fillWidth = (currentHealth / maxHealth) * barWidth;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, fillWidth, barHeight),
      Paint()..color = fillColor,
    );
  }

  void updateHealth(double newHealth) {
    currentHealth = newHealth;
    if (currentHealth < 0) currentHealth = 0;
    if (currentHealth > maxHealth) currentHealth = maxHealth;
  }
}
