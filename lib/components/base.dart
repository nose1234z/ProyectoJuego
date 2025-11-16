import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:iadenfender/components/health_bar.dart'; // Import HealthBar

class Base extends PositionComponent with CollisionCallbacks {
  double health;
  final double maxHealth;
  late HealthBar healthBar;
  final VoidCallback? onBaseDestroyed; // Declared as an instance field

  Base({
    required Sprite sprite, // Now required
    super.position,
    super.size,
    required this.health,
    required this.maxHealth,
    this.onBaseDestroyed,
  }) {
    add(
      SpriteComponent(sprite: sprite, size: size),
    ); // Add SpriteComponent as child
    // Add a hitbox so enemies can collide with the base
    add(RectangleHitbox());
    healthBar = HealthBar(
      currentHealth: health,
      maxHealth: maxHealth,
      barWidth: size.x, // Health bar width same as base width
      position: Vector2(0, -10), // Position above the base
    );
    add(healthBar);
  }

  @override
  void update(double dt) {
    super.update(dt);
    healthBar.updateHealth(health);
  }

  void takeDamage(double amount) {
    health -= amount;
    if (health <= 0) {
      health = 0;
      // Base destroyed - game over
      onBaseDestroyed?.call(); // Call the callback
    }
  }

  void repair(double amount) {
    health += amount;
    if (health > maxHealth) {
      health = maxHealth;
    }
  }
}
