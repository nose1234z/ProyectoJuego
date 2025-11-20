import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:async';

/// Mini juego para mostrar preview de proyectiles en la tienda
class ProjectilePreviewGame extends FlameGame {
  final String projectileSpritePath;
  Timer? _shootTimer;

  ProjectilePreviewGame({required this.projectileSpritePath});

  @override
  Color backgroundColor() => const Color(0xFF1a1a2e);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Agregar un objetivo estático (enemigo simulado)
    final targetSprite = await loadSprite('enemies/malware.png');
    final target = SpriteComponent(
      sprite: targetSprite,
      position: Vector2(size.x * 0.75, size.y * 0.5),
      size: Vector2(40, 40),
      anchor: Anchor.center,
    );
    add(target);

    // Agregar un aliado simulado
    final allySprite = await loadSprite('base/AI.png');
    final ally = SpriteComponent(
      sprite: allySprite,
      position: Vector2(size.x * 0.25, size.y * 0.5),
      size: Vector2(35, 35),
      anchor: Anchor.center,
    );
    add(ally);

    // Disparar proyectiles cada 1.5 segundos
    _shootTimer = Timer(1.5, repeat: true, onTick: () => _shootProjectile());
    _shootTimer?.start();
  }

  Future<void> _shootProjectile() async {
    final projectileSprite = await loadSprite(projectileSpritePath);

    final startPos = Vector2(size.x * 0.25, size.y * 0.5);
    final endPos = Vector2(size.x * 0.75, size.y * 0.5);

    final projectile = PreviewProjectile(
      sprite: projectileSprite,
      startPosition: startPos,
      targetPosition: endPos,
    );

    add(projectile);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _shootTimer?.update(dt);
  }

  @override
  void onRemove() {
    _shootTimer?.stop();
    super.onRemove();
  }
}

/// Proyectil simplificado para el preview
class PreviewProjectile extends SpriteAnimationComponent {
  final Vector2 targetPosition;
  final double speed = 200.0;

  PreviewProjectile({
    required Sprite sprite,
    required Vector2 startPosition,
    required this.targetPosition,
  }) : super(
         position: startPosition,
         size: Vector2(40, 40),
         anchor: Anchor.center,
       ) {
    animation = SpriteAnimation.spriteList([sprite], stepTime: 0.1, loop: true);

    // Calcular rotación hacia el objetivo
    final direction = targetPosition - startPosition;
    angle =
        direction.screenAngle() -
        1.5708; // -90 grados para apuntar correctamente
  }

  @override
  void update(double dt) {
    super.update(dt);

    final direction = (targetPosition - position).normalized();
    position += direction * speed * dt;

    // Actualizar rotación
    angle =
        direction.screenAngle() -
        1.5708; // -90 grados para apuntar correctamente

    // Remover cuando llega al objetivo
    if (position.distanceTo(targetPosition) < 10) {
      removeFromParent();
    }
  }
}
