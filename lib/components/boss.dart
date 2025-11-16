import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:iadenfender/main.dart';
import 'package:iadenfender/components/health_bar.dart';
import 'package:iadenfender/components/enemy.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class Boss extends PositionComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  double health;
  final double maxHealth;
  late HealthBar healthBar;
  double spawnTimer = 0.0;
  final double spawnInterval = 2.0; // spawn enemy every 2 seconds
  final Random _random = Random();
  double speed = 12.0; // Boss movement speed

  Boss({
    required Sprite sprite,
    super.position,
    super.size,
    required this.health,
  }) : maxHealth = health {
    add(SpriteComponent(sprite: sprite, size: size));
    add(RectangleHitbox());
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

    // Move towards the left (towards base)
    position.x -= speed * dt;

    // Spawn minion enemies periodically
    spawnTimer += dt;
    if (spawnTimer >= spawnInterval) {
      spawnTimer = 0.0;
      _spawnMinion();
    }
  }

  void _spawnMinion() {
    final minionHealth = 20.0 + (game.currentWaveNumber * 2);
    final enemy = Enemy(
      sprite: game.enemySprites[_random.nextInt(game.enemySprites.length)],
      position: Vector2(
        position.x - 50.0 + _random.nextDouble() * 100,
        position.y + 100.0,
      ),
      size: Vector2(40, 40),
      health: minionHealth,
      speed: 25,
      damage: 5,
      goldValue: 5.0,
    );
    game.add(enemy);
  }

  void takeDamage(double amount) {
    health -= amount;
    if (health <= 0) {
      health = 0;
      removeFromParent();
    }
  }
}
