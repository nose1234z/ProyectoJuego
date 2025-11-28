import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:iadenfender/components/health_bar.dart'; // Import HealthBar

class Base extends PositionComponent with CollisionCallbacks {
  double health;
  double maxHealth;
  late HealthBar healthBar;
  final VoidCallback? onBaseDestroyed; // Declared as an instance field

  // Sprite sheet con las 3 fases de la torre
  final List<Sprite> towerSprites; // [0: normal, 1: dañada, 2: destruida]
  late SpriteComponent spriteComponent;

  Base({
    required this.towerSprites,
    super.position,
    super.size,
    required this.health,
    required this.maxHealth,
    this.onBaseDestroyed,
  }) {
    spriteComponent = SpriteComponent(sprite: towerSprites[0], size: size);
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
    Sprite targetSprite;

    if (healthPercentage <= 0.4) {
      // Menos del 40% de vida - torre destruida (frame 2)
      targetSprite = towerSprites[2];
    } else if (healthPercentage <= 0.7) {
      // Entre 40% y 70% de vida - torre dañada (frame 1)
      targetSprite = towerSprites[1];
    } else {
      // Más del 70% de vida - torre normal (frame 0)
      targetSprite = towerSprites[0];
    }

    if (spriteComponent.sprite != targetSprite) {
      spriteComponent.sprite = targetSprite;
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
