import 'package:flame/components.dart';
// import 'package:flame/input.dart'; // No longer needed
import 'package:flutter/material.dart';
import 'package:iadenfender/main.dart'; // Import MyGame

class RepairButton extends PositionComponent with HasGameReference<MyGame> {
  // Removed TapCallbacks
  final double repairCost;
  final double repairAmount;
  late TextComponent buttonText;

  RepairButton({
    super.position,
    super.size,
    required this.repairCost,
    required this.repairAmount,
  }) : super() {
    add(
      RectangleComponent(
        size: size,
        paint: Paint()..color = Colors.brown, // Button background color
      ),
    );
    buttonText = TextComponent(
      text: 'Repair\n($repairCost G)',
      position: size / 2,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 14.0, color: Colors.white),
      ),
    );
    add(buttonText);
  }

  // Removed onTapDown override, interaction handled by MyGame.handleTap
}
