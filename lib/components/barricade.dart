import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:iadenfender/main.dart';
import 'package:iadenfender/components/health_bar.dart';
import 'package:flutter/material.dart';

class Barricade extends PositionComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  double health;
  final double maxHealth;
  late HealthBar healthBar;

  Barricade({
    required Sprite sprite,
    super.position,
    super.size,
    required this.health,
  }) : maxHealth = health {
    add(SpriteComponent(sprite: sprite, size: size));
    add(RectangleHitbox());

    // For a vertical wall, show a wider health bar to the right of the wall
    final barWidth = size.x < 60 ? 80.0 : size.x * 2.0;
    healthBar = HealthBar(
      currentHealth: health,
      maxHealth: maxHealth,
      barWidth: barWidth,
      barHeight: 8.0,
      position: Vector2(size.x + 6, -10),
      fillColor: Colors.blue,
    );
    add(healthBar);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (health <= 0) {
      removeFromParent();
    }
    healthBar.updateHealth(health);
  }

  void takeDamage(double amount) {
    health -= amount;
    if (health <= 0) {
      health = 0;
      removeFromParent();
    }
  }
}
