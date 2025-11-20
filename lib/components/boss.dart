import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:iadenfender/main.dart';
import 'package:iadenfender/components/health_bar.dart';
import 'package:iadenfender/components/base.dart';
import 'package:iadenfender/components/barricade.dart';
import 'package:iadenfender/components/player_unit.dart';
import 'package:flutter/material.dart';

class Boss extends PositionComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  double health;
  final double maxHealth;
  late HealthBar healthBar;
  double attackTimer = 0.0;
  final double attackInterval = 1.5; // Ataca cada 1.5 segundos
  final double attackDamage = 15.0;
  double speed = 5.0; // Boss movement speed (reducida para mejor colisión)
  bool isColliding = false; // Para detener movimiento al colisionar

  Boss({
    required Sprite sprite,
    super.position,
    super.size,
    required this.health,
  }) : maxHealth = health {
    add(SpriteComponent(sprite: sprite, size: size));
    // Hitbox sólido que cubre todo el sprite del boss
    add(RectangleHitbox(size: size, position: Vector2.zero()));
    healthBar = HealthBar(
      currentHealth: health,
      maxHealth: maxHealth,
      barWidth: size.x * 1.2,
      barHeight: 20.0,
      position: Vector2(0, -30),
      fillColor: Colors.redAccent,
      backgroundColor: Colors.black54,
    );
    add(healthBar);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw health percentage text above health bar
    final healthPercent = ((health / maxHealth) * 100).toStringAsFixed(0);
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$healthPercent%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size.x / 2) - (textPainter.width / 2), -55),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (health <= 0) {
      removeFromParent();
      return;
    }
    healthBar.updateHealth(health);

    // Move towards the left (towards base) solo si no está colisionando
    if (!isColliding) {
      position.x -= speed * dt;
    }

    // Actualizar timer de ataque
    attackTimer += dt;

    // Reset collision flag cada frame (se volverá true en onCollision si hay colisión)
    isColliding = false;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // Colisión con la base
    if (other is Base) {
      isColliding = true; // Detener movimiento
      if (attackTimer >= attackInterval) {
        other.takeDamage(attackDamage);
        attackTimer = 0.0;
      }
    }

    // Colisión con barricada
    if (other is Barricade) {
      isColliding = true; // Detener movimiento
      if (attackTimer >= attackInterval) {
        other.takeDamage(attackDamage);
        attackTimer = 0.0;
      }
    }

    // Colisión con aliados
    if (other is PlayerUnit) {
      isColliding = true; // Detener movimiento momentáneamente
      if (attackTimer >= attackInterval) {
        other.takeDamage(attackDamage);
        attackTimer = 0.0;
      }
    }
  }

  void takeDamage(double amount) {
    health -= amount;
    if (health <= 0) {
      health = 0;
      removeFromParent();
    }
  }
}
