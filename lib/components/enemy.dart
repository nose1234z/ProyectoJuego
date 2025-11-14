import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:iadenfender/main.dart'; // Import MyGame to access its properties
import 'package:iadenfender/components/base.dart'; // Import Base
import 'package:iadenfender/components/player_unit.dart'; // Import PlayerUnit
import 'package:iadenfender/components/barricade.dart';
import 'package:iadenfender/components/health_bar.dart'; // Import HealthBar
import 'package:flutter/material.dart'; // For Colors

class Enemy extends PositionComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  double health;
  final double maxHealth; // Added maxHealth for health bar
  double speed;
  double damage;
  double goldValue;
  bool _isAttacking = false;
  PlayerUnit? _targetUnit;
  Barricade? _targetBarricade;
  late HealthBar healthBar;

  Enemy({
    required Sprite sprite, // Now required
    super.position,
    super.size,
    required this.health,
    required this.speed,
    required this.damage,
    required this.goldValue,
  }) : maxHealth = health {
    // Initialize maxHealth
    add(
      SpriteComponent(sprite: sprite, size: size),
    ); // Add SpriteComponent as child
    add(RectangleHitbox()); // Add a hitbox for collision detection
    healthBar = HealthBar(
      currentHealth: health,
      maxHealth: maxHealth,
      barWidth: size.x, // Health bar width same as enemy width
      position: Vector2(0, -10), // Position above the enemy
      fillColor: Colors.orange, // Different color for enemy health bar
    );
    add(healthBar);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isAttacking) {
      x -= speed * dt; // Move enemy to the left
    } else {
      // If attacking, deal damage over time (simple implementation)
      if (_targetUnit != null) {
        if (_targetUnit!.health > 0) {
          _targetUnit!.takeDamage(damage * dt); // Damage per second
        } else {
          _isAttacking = false;
          _targetUnit = null;
        }
      } else if (_targetBarricade != null) {
        if (_targetBarricade!.health > 0) {
          _targetBarricade!.takeDamage(damage * dt);
        } else {
          _isAttacking = false;
          _targetBarricade = null;
        }
      } else {
        // No valid target, resume movement
        _isAttacking = false;
      }
    }

    if (x < -size.x) {
      // If enemy goes off-screen, remove it
      removeFromParent();
    }
    healthBar.updateHealth(health);
  }

  void takeDamage(double amount) {
    health -= amount;
    if (health <= 0) {
      health = 0;
      // Award gold to the player
      game.addGold(goldValue); // Assuming MyGame has an addGold method
      removeFromParent(); // Remove enemy when health is zero
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Base) {
      // Enemy reached the base, deal damage and remove itself
      other.takeDamage(damage); // Instant damage for now
      removeFromParent();
    } else if (other is PlayerUnit) {
      // Enemy collided with a player unit, stop and attack
      _isAttacking = true;
      _targetUnit = other;
    } else if (other is Barricade) {
      // Enemy collided with barricade (wall)
      _isAttacking = true;
      _targetBarricade = other;
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is PlayerUnit && _targetUnit == other) {
      // If the target unit is no longer in collision, resume movement
      _isAttacking = false;
      _targetUnit = null;
    }
    if (other is Barricade && _targetBarricade == other) {
      _isAttacking = false;
      _targetBarricade = null;
    }
  }
}
