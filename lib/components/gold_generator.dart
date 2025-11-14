import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:iadenfender/main.dart';

class GoldGenerator extends PositionComponent with HasGameReference<MyGame> {
  double goldPerSecond = 1.0; // Start with 1 gold per second
  double _goldAccumulator = 0.0;

  late TextComponent generatorText;

  GoldGenerator({super.position, super.size});

  @override
  void onMount() {
    super.onMount();

    // Draw generator background
    add(
      RectangleComponent(
        size: size,
        paint: Paint()..color = Colors.amber.withValues(alpha: 0.3),
      ),
    );

    // Generator text
    generatorText = TextComponent(
      text: '+${goldPerSecond.toStringAsFixed(1)}/s',
      position: size / 2,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20.0,
          color: Colors.amber,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(generatorText);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _goldAccumulator += goldPerSecond * dt;

    if (_goldAccumulator >= 1.0) {
      final goldToAdd = _goldAccumulator.floor();
      game.addGold(goldToAdd.toDouble());
      _goldAccumulator -= goldToAdd;
    }
  }

  void setGoldPerSecond(double value) {
    goldPerSecond = value;
    generatorText.text = '+${goldPerSecond.toStringAsFixed(1)}/s';
  }
}
