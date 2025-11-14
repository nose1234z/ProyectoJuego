import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:iadenfender/main.dart';
import 'package:iadenfender/components/enemy.dart';
import 'package:iadenfender/components/health_bar.dart';
import 'package:flutter/material.dart';

class PlayerUnit extends PositionComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  double health;
  final double maxHealth;
  double attackDamage;
  double attackSpeed;
  double range;
  double _attackTimer = 0;
  late HealthBar healthBar;

  PlayerUnit({
    required Sprite sprite,
    super.position,
    super.size,
    required this.health,
    required this.attackDamage,
    required this.attackSpeed,
    required this.range,
  }) : maxHealth = health {
    add(SpriteComponent(sprite: sprite, size: size));
    add(RectangleHitbox());
    healthBar = HealthBar(
      currentHealth: health,
      maxHealth: maxHealth,
      barWidth: size.x,
      position: Vector2(0, -10),
      fillColor: Colors.lightGreen,
    );
    add(healthBar);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Draw range circle at unit center
    final centerOffset = Offset(size.x / 2, size.y / 2);

    // Draw filled circle
    canvas.drawCircle(
      centerOffset,
      range / 10, // Scale range to pixels
      Paint()
        ..color = Colors.cyan.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill,
    );

    // Draw border for better visibility
    canvas.drawCircle(
      centerOffset,
      range / 10,
      Paint()
        ..color = Colors.cyan.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _attackTimer += dt;

    Enemy? targetEnemy;
    double closestDistance = range;

    for (final component in game.children.whereType<Enemy>()) {
      final distance = (component.position - position).length;
      if (distance <= range && component.x > x) {
        if (targetEnemy == null || distance < closestDistance) {
          targetEnemy = component;
          closestDistance = distance;
        }
      }
    }

    if (targetEnemy != null && _attackTimer >= (1 / attackSpeed)) {
      targetEnemy.takeDamage(attackDamage);
      _attackTimer = 0;
    }

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
