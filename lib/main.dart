import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'dart:math';
import 'package:iadenfender/components/base.dart';
import 'package:iadenfender/components/enemy.dart';
import 'package:iadenfender/components/player_unit.dart';
import 'package:iadenfender/components/upgrade_button.dart';
import 'package:iadenfender/components/gold_generator.dart';
import 'package:iadenfender/components/barricade.dart';

class Wave {
  final int numEnemies;
  final double spawnInterval;
  Wave({required this.numEnemies, required this.spawnInterval});
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Flame.device.fullScreen();
  Flame.device.setLandscape();
  final game = MyGame();
  runApp(
    GestureDetector(
      onTapDown: (details) => game.handleTap(
        Vector2(details.localPosition.dx, details.localPosition.dy),
      ),
      child: GameWidget(game: game),
    ),
  );
}

class MyGame extends FlameGame with HasCollisionDetection {
  late Base playerBase;
  double currentGold = 50;
  double goldPerSecond = 0.5;
  GoldGenerator? goldGenerator;

  // Upgrade levels
  int alliesLevel = 0,
      damageLevel = 0,
      attackSpeedLevel = 0,
      healingLevel = 0,
      baseHealthLevel = 0,
      barricadeLevel = 0;

  // Unit stats
  int totalAllies = 0;
  static const int maxAllies = 6;
  double baseUnitDamage = 10.0,
      baseUnitAttackSpeed = 1.0,
      baseHealingAmount = 20.0,
      baseMaxHealth = 100.0,
      baseBarricadeHealth = 150.0;
  Barricade? currentBarricade;

  // Timers
  double _spawnTimer = 0.0, _currentSpawnInterval = 1.0, _autoHealTimer = 0.0;
  static const _autoHealInterval = 5.0;

  late TextComponent goldText, waveText, gameStatusText, statsText;
  bool isGameOver = false, gameWon = false;

  int currentWaveNumber = 0;
  List<Wave> waves = [];
  int enemiesToSpawnInCurrentWave = 0,
      enemiesSpawnedInCurrentWave = 0,
      enemiesRemainingInCurrentWave = 0;

  late List<Sprite> enemySprites;
  late Sprite baseSprite, playerUnitSprite;
  final Random _random = Random();
  late Map<String, UpgradeButton> upgradeButtons;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    upgradeButtons = {};

    final bg = await loadSprite('escenario/mapa1.png');
    add(SpriteComponent(sprite: bg, size: size));

    enemySprites = await Future.wait([
      loadSprite('enemies/malware.png'),
      loadSprite('enemies/gusano.png'),
    ]);

    try {
      baseSprite = await loadSprite('base_placeholder.png');
      playerUnitSprite = await loadSprite('unit_placeholder.png');
    } catch (e) {
      baseSprite = enemySprites[0];
      playerUnitSprite = enemySprites[1];
    }

    playerBase = Base(
      sprite: baseSprite,
      position: Vector2(100, size.y - 300),
      size: Vector2(100, 100),
      health: baseMaxHealth,
      maxHealth: baseMaxHealth,
      onBaseDestroyed: _onGameOver,
    );
    add(playerBase);

    // UI Components
    goldText = TextComponent(
      text: 'Gold: ${currentGold.toInt()}',
      position: Vector2(20, 20),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24.0,
          color: Colors.amber,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(goldText);

    waveText = TextComponent(
      text: 'Wave: 0',
      position: Vector2(size.x / 2, 20),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24.0,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(waveText);

    gameStatusText = TextComponent(
      text: '',
      position: size / 2,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 48.0,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(gameStatusText);

    statsText = TextComponent(
      text: 'Aliados: 0\nDaño: 10.0\nVel. Ataque: 1.00x\nCuración: +20/5s',
      position: Vector2(20, size.y - 100),
      anchor: Anchor.bottomLeft,
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 14.0, color: Colors.white),
      ),
    );
    add(statsText);

    goldGenerator = GoldGenerator(
      position: Vector2(size.x - 120, 20),
      size: Vector2(100, 50),
    );
    add(goldGenerator!);

    // Setup upgrade buttons - horizontal layout at bottom
    const buttonWidth = 100.0, buttonHeight = 70.0, spacing = 8.0;
    final totalButtonsWidth = (buttonWidth + spacing) * 6 - spacing;
    final startX = (size.x - totalButtonsWidth) / 2;
    final startY = size.y - buttonHeight - 20;

    upgradeButtons['allies'] = UpgradeButton(
      upgradeType: 'allies',
      upgradeCost: 30,
      onUpgrade: _upgradeAllies,
      position: Vector2(startX, startY),
      size: Vector2(buttonWidth, buttonHeight),
    );
    add(upgradeButtons['allies']!);

    upgradeButtons['barricade'] = UpgradeButton(
      upgradeType: 'barricade',
      upgradeCost: 50,
      onUpgrade: _upgradeBarricade,
      position: Vector2(startX + (buttonWidth + spacing) * 1, startY),
      size: Vector2(buttonWidth, buttonHeight),
    );
    add(upgradeButtons['barricade']!);

    upgradeButtons['damage'] = UpgradeButton(
      upgradeType: 'damage',
      upgradeCost: 25,
      onUpgrade: _upgradeDamage,
      position: Vector2(startX + (buttonWidth + spacing) * 2, startY),
      size: Vector2(buttonWidth, buttonHeight),
    );
    add(upgradeButtons['damage']!);

    upgradeButtons['attackSpeed'] = UpgradeButton(
      upgradeType: 'attackSpeed',
      upgradeCost: 40,
      onUpgrade: _upgradeAttackSpeed,
      position: Vector2(startX + (buttonWidth + spacing) * 3, startY),
      size: Vector2(buttonWidth, buttonHeight),
    );
    add(upgradeButtons['attackSpeed']!);

    upgradeButtons['healing'] = UpgradeButton(
      upgradeType: 'healing',
      upgradeCost: 50,
      onUpgrade: _upgradeHealing,
      position: Vector2(startX + (buttonWidth + spacing) * 4, startY),
      size: Vector2(buttonWidth, buttonHeight),
    );
    add(upgradeButtons['healing']!);

    upgradeButtons['baseHealth'] = UpgradeButton(
      upgradeType: 'baseHealth',
      upgradeCost: 60,
      onUpgrade: _upgradeBaseHealth,
      position: Vector2(startX + (buttonWidth + spacing) * 5, startY),
      size: Vector2(buttonWidth, buttonHeight),
    );
    add(upgradeButtons['baseHealth']!);

    waves = [
      Wave(numEnemies: 3, spawnInterval: 5.0),
      Wave(numEnemies: 5, spawnInterval: 6.0),
      Wave(numEnemies: 8, spawnInterval: 7.0),
      Wave(numEnemies: 10, spawnInterval: 8.0),
      Wave(numEnemies: 12, spawnInterval: 9.0),
      Wave(numEnemies: 15, spawnInterval: 10.0),
    ];

    startNextWave();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver || gameWon) return;

    _spawnTimer += dt;
    if (_spawnTimer >= _currentSpawnInterval) {
      _spawnTimer = 0.0;
      spawnEnemy();
    }

    _autoHealTimer += dt;
    if (_autoHealTimer >= _autoHealInterval) {
      _autoHealTimer = 0.0;
      if (playerBase.health < playerBase.maxHealth) {
        playerBase.repair(baseHealingAmount * (1 + healingLevel * 0.3));
      }
    }

    if (enemiesSpawnedInCurrentWave >= enemiesToSpawnInCurrentWave &&
        enemiesRemainingInCurrentWave <= 0) {
      if (currentWaveNumber < waves.length) {
        startNextWave();
      } else {
        _onGameWin();
      }
    }

    statsText.text = _getStatsText();
  }

  String _getStatsText() =>
      'Aliados: $totalAllies\n'
      'Daño: ${(baseUnitDamage * (1 + damageLevel * 0.2)).toStringAsFixed(1)}\n'
      'Vel. Ataque: ${(baseUnitAttackSpeed * (1 + attackSpeedLevel * 0.15)).toStringAsFixed(2)}x\n'
      'Curación: +${(baseHealingAmount * (1 + healingLevel * 0.3)).toStringAsFixed(0)}/5s';

  void startNextWave() {
    currentWaveNumber++;
    if (currentWaveNumber > waves.length) return;

    final wave = waves[currentWaveNumber - 1];
    enemiesToSpawnInCurrentWave = wave.numEnemies;
    enemiesSpawnedInCurrentWave = 0;
    enemiesRemainingInCurrentWave = wave.numEnemies;
    _currentSpawnInterval = wave.spawnInterval;
    _spawnTimer = 0.0;
    waveText.text = 'Wave: $currentWaveNumber/${waves.length}';
  }

  void spawnEnemy() {
    if (enemiesSpawnedInCurrentWave < enemiesToSpawnInCurrentWave) {
      final enemyHealth = 30.0 + (currentWaveNumber * currentWaveNumber * 8);
      final enemy = Enemy(
        sprite: enemySprites[_random.nextInt(enemySprites.length)],
        position: Vector2(
          size.x + 25,
          size.y * 0.5 + _random.nextDouble() * 100 - 25,
        ),
        size: Vector2(50, 50),
        health: enemyHealth,
        speed: 30,
        damage: 10,
        goldValue: (10 + (currentWaveNumber * currentWaveNumber * 2))
            .toDouble(),
      );
      add(enemy);
      enemiesSpawnedInCurrentWave++;
    }
  }

  void addGold(double amount) {
    currentGold += amount;
    goldText.text = 'Gold: ${currentGold.toInt()}';
    if (!isGameOver && !gameWon) {
      enemiesRemainingInCurrentWave--;
    }
  }

  void _upgradeAllies() {
    // Cap allies level to 6
    if (alliesLevel >= 6) return;
    alliesLevel++;
    if (totalAllies < maxAllies) {
      totalAllies++;
      goldPerSecond += 0.2;
      goldGenerator?.setGoldPerSecond(goldPerSecond);
      _spawnPlayerUnit();
    }
  }

  void _upgradeBarricade() {
    barricadeLevel++;
    final newHealth = baseBarricadeHealth * (1 + barricadeLevel * 0.3);
    if (currentBarricade != null) {
      currentBarricade!.health = newHealth;
      currentBarricade!.healthBar.maxHealth = newHealth;
    } else {
      _spawnBarricade(newHealth);
    }
  }

  void _spawnBarricade(double health) {
    // Spawn a vertical barricade (wall) between allies and enemies
    final wallWidth = 10.0; // thin vertical wall - reduced
    final wallHeight = 300.0; // tall - reduced
    // Place the wall to the right of the ally formation
    final wallX = 250.0 + 150.0 + 50.0; // = 450.0
    final wallY = size.y - 200.0;
    currentBarricade = Barricade(
      sprite: playerUnitSprite,
      position: Vector2(wallX - wallWidth / 2, wallY - wallHeight / 2),
      size: Vector2(wallWidth, wallHeight),
      health: health,
    );
    add(currentBarricade!);
  }

  void _upgradeDamage() {
    damageLevel++;
    for (final unit in children.whereType<PlayerUnit>()) {
      unit.attackDamage = baseUnitDamage * (1 + damageLevel * 0.2);
    }
  }

  void _upgradeAttackSpeed() {
    attackSpeedLevel++;
    for (final unit in children.whereType<PlayerUnit>()) {
      unit.attackSpeed = baseUnitAttackSpeed * (1 + attackSpeedLevel * 0.15);
    }
  }

  void _upgradeHealing() {
    healingLevel++;
  }

  void _upgradeBaseHealth() {
    baseHealthLevel++;
    final newMaxHealth = baseMaxHealth * (1 + baseHealthLevel * 0.25);
    playerBase.health =
        (playerBase.health / playerBase.maxHealth) * newMaxHealth;
    baseMaxHealth = newMaxHealth;
  }

  void _spawnPlayerUnit() {
    // Arrange allies in a 2x3 formation relative to the base (2 columns x 3 rows).
    // Rows: 0 = bottom, 1 = middle, 2 = top.
    final leftColumnX = playerBase.position.x + playerBase.size.x + 50.0;
    final spacingX = 120.0; // increase horizontal spacing between columns
    final rowSpacing = 100.0; // increase vertical spacing between rows
    final baseY =
        playerBase.position.y +
        playerBase.size.y +
        50.0; // bottom row Y - lowered
    final index = totalAllies - 1; // 0-based index of this newly added ally

    // Define symmetric positions based on the total number of allies.
    final middleRowY = baseY - rowSpacing; // row 1
    final topRowY = baseY - rowSpacing * 2; // row 2
    final centerX = leftColumnX + spacingX / 2.0;

    List<Vector2> positions;
    switch (totalAllies) {
      case 1:
        positions = [Vector2(centerX, topRowY)];
        break;
      case 2:
        positions = [
          Vector2(leftColumnX, topRowY),
          Vector2(leftColumnX + spacingX, topRowY),
        ];
        break;
      case 3:
        positions = [
          Vector2(leftColumnX, topRowY),
          Vector2(leftColumnX + spacingX, topRowY),
          Vector2(centerX, middleRowY),
        ];
        break;
      case 4:
        positions = [
          Vector2(leftColumnX, topRowY),
          Vector2(leftColumnX + spacingX, topRowY),
          Vector2(leftColumnX, middleRowY),
          Vector2(leftColumnX + spacingX, middleRowY),
        ];
        break;
      case 5:
        positions = [
          Vector2(leftColumnX, topRowY),
          Vector2(leftColumnX + spacingX, topRowY),
          Vector2(leftColumnX, middleRowY),
          Vector2(leftColumnX + spacingX, middleRowY),
          Vector2(centerX, baseY),
        ];
        break;
      default:
        positions = [
          Vector2(leftColumnX, topRowY),
          Vector2(leftColumnX + spacingX, topRowY),
          Vector2(leftColumnX, middleRowY),
          Vector2(leftColumnX + spacingX, middleRowY),
          Vector2(leftColumnX, baseY),
          Vector2(leftColumnX + spacingX, baseY),
        ];
    }

    final pos =
        positions[index < positions.length ? index : positions.length - 1];

    add(
      PlayerUnit(
        sprite: playerUnitSprite,
        position: pos,
        size: Vector2(40, 40),
        health: 50,
        attackDamage: baseUnitDamage * (1 + damageLevel * 0.2),
        attackSpeed: baseUnitAttackSpeed * (1 + attackSpeedLevel * 0.15),
        range: 150,
      ),
    );
  }

  void _onGameOver() {
    isGameOver = true;
    gameStatusText.text = 'GAME OVER!';
    children.whereType<Enemy>().forEach((e) => e.removeFromParent());
  }

  void _onGameWin() {
    gameWon = true;
    gameStatusText.text = 'VICTORY!';
  }

  void handleTap(Vector2 pos) {
    if (isGameOver || gameWon) return;
    for (final btn in upgradeButtons.values) {
      if (btn.containsPoint(pos)) {
        btn.onClick();
        break;
      }
    }
  }
}
