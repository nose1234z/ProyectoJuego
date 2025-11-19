import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:iadenfender/main.dart';

class UpgradeButton extends PositionComponent with HasGameReference<MyGame> {
  final String upgradeType;
  final double upgradeCost;
  final VoidCallback onUpgrade;

  late TextComponent buttonText;
  late TextComponent costText;
  late RectangleComponent background;
  double currentCost;
  bool isDisabled = false;

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

    background = RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.blueGrey,
    );
    add(background);

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

    // Special handling for the 'allies' button to act as a "buy" button
    if (upgradeType == 'allies') {
      if (game.totalAllies >= MyGame.maxAllies) {
        if (!isDisabled) {
          isDisabled = true;
          background.paint.color = Colors.red.withAlpha(204);
          buttonText.text = 'Máximo';
          costText.text = '';
        }
      } else {
        if (isDisabled) {
          isDisabled = false;
          background.paint.color = Colors.blueGrey;
          buttonText.text = _getUpgradeName();
          costText.text = '${currentCost.toInt()}G';
        }
      }
    } else {
      // Original level-based upgrade logic for other buttons
      final level = _getCurrentLevel();
      buttonText.text = '${_getUpgradeName()} Lv$level';
    }
  }

  int _getCurrentLevel() {
    switch (upgradeType) {
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
        return 'Comprar Aliado'; // Changed text
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
    if (!isDisabled) {
      costText.text = '${newCost.toInt()}G';
    }
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
    if (isDisabled) return;

    if (canAfford()) {
      game.currentGold -= currentCost;
      game.goldText.text = 'Gold: ${game.currentGold.toInt()}';
      
      // For allies, cost doesn't increase. For others, it does.
      if (upgradeType != 'allies') {
        updateCost(currentCost * 1.2);
      }
      
      onUpgrade();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (isDisabled) return;

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
