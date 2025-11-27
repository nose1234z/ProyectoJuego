import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:iadenfender/main.dart';
import 'package:iadenfender/components/enemy.dart';
import 'package:iadenfender/components/boss.dart';

class Projectile extends SpriteAnimationComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  final Vector2 targetPosition;
  final double damage;
  final double speed;
  PositionComponent? target;

  Projectile({
    required Sprite sprite,
    required Vector2 startPosition,
    required this.targetPosition,
    required this.damage,
    this.speed = 500.0,
    this.target,
  }) : super(
         position: startPosition,
         size: Vector2(40, 40), // Tamaño más grande para mejor visibilidad
         anchor: Anchor.center,
       ) {
    // Crear animación simple con el sprite
    animation = SpriteAnimation.spriteList([sprite], stepTime: 0.1, loop: true);

    // Calcular rotación inicial hacia el objetivo
    final direction = targetPosition - startPosition;
    angle = direction.screenAngle();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: 12));
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Si el objetivo sigue vivo, seguir al objetivo
    if (target != null && !target!.isRemoving && !target!.isRemoved) {
      final direction = (target!.position - position).normalized();
      position += direction * speed * dt;

      // Actualizar el ángulo del sprite para que apunte hacia el objetivo
      angle = direction.screenAngle();

      // Verificar si llegó al objetivo
      if (position.distanceTo(target!.position) < 10) {
        _hitTarget();
        removeFromParent();
      }
    } else {
      // Si no hay objetivo o murió, ir a la posición original
      final direction = (targetPosition - position).normalized();
      position += direction * speed * dt;

      // Actualizar el ángulo del sprite
      angle = direction.screenAngle();

      // Verificar si llegó a la posición
      if (position.distanceTo(targetPosition) < 10) {
        removeFromParent();
      }
    }

    // Remover si sale de la pantalla
    if (position.x < 0 ||
        position.x > game.size.x ||
        position.y < 0 ||
        position.y > game.size.y) {
      removeFromParent();
    }
  }

  void _hitTarget() {
    if (target != null) {
      if (target is Enemy) {
        (target as Enemy).takeDamage(damage);
      } else if (target is Boss) {
        (target as Boss).takeDamage(damage);
      }
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // Colisión con enemigos
    if (other is Enemy || other is Boss) {
      _hitTarget();
      removeFromParent();
    }
  }
}
