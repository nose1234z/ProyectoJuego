import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:iadenfender/components/health_bar.dart'; // Import HealthBar

class Base extends PositionComponent with CollisionCallbacks {
  double health;
  double maxHealth;
  late HealthBar healthBar;
  final VoidCallback? onBaseDestroyed; // Declared as an instance field

  // Sprites para diferentes estados de la torre
  final Sprite normalSprite;
  final Sprite damagedSprite;
  final Sprite destroyedSprite;
  late SpriteComponent spriteComponent;

  Base({
    required this.normalSprite,
    required this.damagedSprite,
    required this.destroyedSprite,
    super.position,
    super.size,
    required this.health,
    required this.maxHealth,
    this.onBaseDestroyed,
  }) {
    spriteComponent = SpriteComponent(sprite: normalSprite, size: size);
    add(spriteComponent); // Add SpriteComponent as child
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

    // Cambiar sprite según el porcentaje de vida
    final healthPercentage = health / maxHealth;

    if (healthPercentage <= 0.4) {
      // Menos del 40% de vida - torre destruida
      if (spriteComponent.sprite != destroyedSprite) {
        spriteComponent.sprite = destroyedSprite;
      }
    } else if (healthPercentage <= 0.7) {
      // Entre 40% y 70% de vida - torre dañada
      if (spriteComponent.sprite != damagedSprite) {
        spriteComponent.sprite = damagedSprite;
      }
    } else {
      // Más del 70% de vida - torre normal
      if (spriteComponent.sprite != normalSprite) {
        spriteComponent.sprite = normalSprite;
      }
    }
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
