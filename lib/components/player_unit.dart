import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:iadenfender/main.dart';
import 'package:iadenfender/components/enemy.dart';
import 'package:iadenfender/components/boss.dart';
import 'package:iadenfender/components/health_bar.dart';
import 'package:iadenfender/components/projectile.dart';
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

    PositionComponent? target;
    double closestDistance = range;

    for (final component
        in game.children
            .where((c) => c is Enemy || c is Boss)
            .cast<PositionComponent>()) {
      final distance = (component.position - position).length;
      if (distance <= range && component.x > x) {
        if (target == null || distance < closestDistance) {
          target = component;
          closestDistance = distance;
        }
      }
    }

    if (target != null && _attackTimer >= (1 / attackSpeed)) {
      // Disparar proyectil hacia el objetivo
      _shootProjectile(target);
      _attackTimer = 0;
    }

    if (health <= 0) {
      removeFromParent();
    }
    healthBar.updateHealth(health);
  }

  @override
  void onRemove() {
    super.onRemove();
    game.onAllyRemoved();
  }

  void takeDamage(double amount) {
    health -= amount;
    if (health <= 0) {
      health = 0;
      removeFromParent();
    }
  }

  Future<void> _shootProjectile(PositionComponent target) async {
    // Cargar el sprite del proyectil usando la skin equipada
    final projectileSkin =
        game.dataManager.getEquippedSkin('projectile') ??
        'projectiles/projectile1.png';
    final projectileSprite = await game.loadSprite(projectileSkin);

    // Calcular posición inicial (centro de la unidad)
    final startPos = position + Vector2(size.x / 2, size.y / 2);

    // Crear y agregar el proyectil
    final projectile = Projectile(
      sprite: projectileSprite,
      startPosition: startPos,
      targetPosition:
          target.position + Vector2(target.size.x / 2, target.size.y / 2),
      damage: attackDamage,
      target: target,
    );

    game.add(projectile);
  }
}
