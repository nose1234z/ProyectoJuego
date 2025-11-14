import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:iadenfender/main.dart';

class UpgradeButton extends PositionComponent with HasGameReference<MyGame> {
  final String upgradeType;
  final double upgradeCost;
  final VoidCallback onUpgrade;

  late TextComponent buttonText;
  late TextComponent costText;
  double currentCost;

  UpgradeButton({
    required this.upgradeType,
    required this.upgradeCost,
    required this.onUpgrade,
    super.position,
    super.size,
  }) : currentCost = upgradeCost;

  @override
  void onMount() {
    super.onMount();

    // Draw button background
    add(
      RectangleComponent(size: size, paint: Paint()..color = Colors.blueGrey),
    );

    // Button text (upgrade name)
    final upgradeName = _getUpgradeName();
    buttonText = TextComponent(
      text: upgradeName,
      position: Vector2(size.x / 2, size.y / 2 - 12),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 14.0,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(buttonText);

    // Cost text
    costText = TextComponent(
      text: '${currentCost.toInt()}G',
      position: Vector2(size.x / 2, size.y / 2 + 12),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 11.0, color: Colors.amber),
      ),
    );
    add(costText);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Update button display with current level from game
    final level = _getCurrentLevel();
    buttonText.text = '${_getUpgradeName()} Lv$level';
  }

  int _getCurrentLevel() {
    switch (upgradeType) {
      case 'allies':
        return game.alliesLevel;
      case 'damage':
        return game.damageLevel;
      case 'attackSpeed':
        return game.attackSpeedLevel;
      case 'healing':
        return game.healingLevel;
      case 'baseHealth':
        return game.baseHealthLevel;
      case 'barricade':
        return game.barricadeLevel;
      default:
        return 0;
    }
  }

  String _getUpgradeName() {
    switch (upgradeType) {
      case 'allies':
        return 'Aliados';
      case 'barricade':
        return 'Barricada';
      case 'damage':
        return 'Daño';
      case 'attackSpeed':
        return 'Vel. Ataque';
      case 'healing':
        return 'Curación';
      case 'baseHealth':
        return 'Vida Base';
      default:
        return 'Upgrade';
    }
  }

  void updateCost(double newCost) {
    currentCost = newCost;
    costText.text = '${newCost.toInt()}G';
  }

  bool canAfford() {
    return game.currentGold >= currentCost;
  }

  @override
  bool containsPoint(Vector2 point) {
    return point.x >= position.x &&
        point.x <= position.x + size.x &&
        point.y >= position.y &&
        point.y <= position.y + size.y;
  }

  void onClick() {
    if (canAfford()) {
      game.currentGold -= currentCost;
      game.goldText.text = 'Gold: ${game.currentGold.toInt()}';
      // Increase cost for next upgrade (1.2x multiplier)
      updateCost(currentCost * 1.2);
      onUpgrade();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Draw border if can afford
    if (canAfford()) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()
          ..color = Colors.greenAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }
}
