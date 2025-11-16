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
import 'package:iadenfender/components/boss.dart';

class Wave {
  final int numEnemies;
  final double spawnInterval;
  Wave({required this.numEnemies, required this.spawnInterval});
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Flame.device.fullScreen();
  Flame.device.setLandscape();
  runApp(MainMenuApp());
}

class MainMenuApp extends StatefulWidget {
  const MainMenuApp({super.key});
  @override
  State<MainMenuApp> createState() => _MainMenuAppState();
}

enum AppScreen { inicio, seleccion, juego }

class _MainMenuAppState extends State<MainMenuApp> {
  AppScreen screen = AppScreen.inicio;
  int selectedLevel = 1;

  @override
  Widget build(BuildContext context) {
    switch (screen) {
      case AppScreen.inicio:
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/escenario/inicio.png',
                  fit: BoxFit.cover,
                ),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () =>
                        setState(() => screen = AppScreen.seleccion),
                    child: const Text('JUGAR'),
                  ),
                ),
              ],
            ),
          ),
        );
      case AppScreen.seleccion:
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/escenario/nivel.jpeg',
                  fit: BoxFit.cover,
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Selecciona un nivel',
                        style: TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => setState(() {
                          selectedLevel = 1;
                          screen = AppScreen.juego;
                        }),
                        child: const Text('Nivel 1'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => setState(() {
                          selectedLevel = 2;
                          screen = AppScreen.juego;
                        }),
                        child: const Text('Nivel 2'),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        onPressed: () =>
                            setState(() => screen = AppScreen.inicio),
                        child: const Text('Volver'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      case AppScreen.juego:
        final game = MyGame(level: selectedLevel);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: GestureDetector(
              child: GameWidget(game: game),
              onTapDown: (details) => game.handleTap(
                Vector2(details.localPosition.dx, details.localPosition.dy),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              tooltip: 'Volver al menú',
              onPressed: () => setState(() => screen = AppScreen.inicio),
              child: const Icon(Icons.home),
            ),
          ),
        );
    }
  }
}

class MyGame extends FlameGame with HasCollisionDetection {
  final int level;
  MyGame({this.level = 1});
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
  static const int maxAllies = 4;
  double baseUnitDamage = 10.0,
      baseUnitAttackSpeed = 1.0,
      baseHealingAmount = 5.0,
      baseMaxHealth = 100.0,
      baseBarricadeHealth = 150.0;
  Barricade? currentBarricade;
  Boss? currentBoss;
  bool isBossPhase = false;
  double baseBossHealth = 500.0;

  // Timers
  double _spawnTimer = 0.0, _currentSpawnInterval = 1.0, _autoHealTimer = 0.0;
  static const _autoHealInterval = 15.0;

  late TextComponent goldText, waveText, gameStatusText, statsText;
  bool isGameOver = false, gameWon = false;

  int currentWaveNumber = 0;
  List<Wave> waves = [];
  int enemiesToSpawnInCurrentWave = 0,
      enemiesSpawnedInCurrentWave = 0,
      enemiesRemainingInCurrentWave = 0;

  late List<Sprite> enemySprites;
  late Sprite baseSprite, playerUnitSprite, bossSprite;
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

    // Load boss sprite (assets/images/boss/ADWARE.png)
    bossSprite = await loadSprite('boss/ADWARE.png');

    try {
      baseSprite = await loadSprite('base/torre.png');
      playerUnitSprite = await loadSprite('base/AI.png');
    } catch (e) {
      // Fallback in case assets are missing
      baseSprite = enemySprites[0];
      playerUnitSprite = enemySprites[1];
    }

    playerBase = Base(
      sprite: baseSprite,
      position: Vector2(100, size.y - 350),
      size: Vector2(150, 250),
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
      text: 'Aliados: 0\nDaño: 10.0\nVel. Ataque: 1.00x\nCuración: +5/15s',
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
      Wave(numEnemies: 10, spawnInterval: 5.0),
      Wave(numEnemies: 12, spawnInterval: 6.0),
      Wave(numEnemies: 15, spawnInterval: 7.0),
      Wave(numEnemies: 18, spawnInterval: 8.0),
      Wave(numEnemies: 20, spawnInterval: 9.0),
      Wave(numEnemies: 25, spawnInterval: 10.0),
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

    if (!isBossPhase) {
      if (enemiesSpawnedInCurrentWave >= enemiesToSpawnInCurrentWave &&
          enemiesRemainingInCurrentWave <= 0) {
        if (currentWaveNumber < waves.length) {
          startNextWave();
        } else {
          _startBossPhase();
        }
      }
    } else {
      // Boss phase: check if boss is defeated
      if (currentBoss == null || currentBoss!.health <= 0) {
        _onGameWin();
      }
    }

    statsText.text = _getStatsText();
  }

  String _getStatsText() =>
      'Aliados: $totalAllies\n'
      'Daño: ${(baseUnitDamage * (1 + damageLevel * 0.2)).toStringAsFixed(1)}\n'
      'Vel. Ataque: ${(baseUnitAttackSpeed * (1 + attackSpeedLevel * 0.15)).toStringAsFixed(2)}x\n'
      'Curación: +${(baseHealingAmount * (1 + healingLevel * 0.3)).toStringAsFixed(0)}/15s';

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw wave progress bar if not in boss phase
    if (!isBossPhase && !isGameOver && !gameWon) {
      const barWidth = 200.0;
      const barHeight = 20.0;
      final barX = (size.x / 2) - (barWidth / 2);
      final barY = 65.0; // Below the wave text

      final killsRequired = enemiesToSpawnInCurrentWave;
      final killsDone = (killsRequired - enemiesRemainingInCurrentWave).clamp(
        0,
        killsRequired,
      );
      final progress = killsRequired > 0 ? killsDone / killsRequired : 0.0;

      // Background bar (dark)
      canvas.drawRect(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill,
      );

      // Progress bar (cyan/green)
      canvas.drawRect(
        Rect.fromLTWH(barX, barY, barWidth * progress, barHeight),
        Paint()
          ..color = Colors.cyan.withValues(alpha: 0.8)
          ..style = PaintingStyle.fill,
      );

      // Border
      canvas.drawRect(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Text with enemy count
      final textPainter = TextPainter(
        text: TextSpan(
          // Show remaining to kill over total required
          text: '$enemiesRemainingInCurrentWave/$enemiesToSpawnInCurrentWave',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          barX + (barWidth / 2) - (textPainter.width / 2),
          barY + (barHeight / 2) - (textPainter.height / 2),
        ),
      );
    }
  }

  void startNextWave() {
    currentWaveNumber++;
    if (currentWaveNumber > waves.length) {
      _startBossPhase();
      return;
    }

    final wave = waves[currentWaveNumber - 1];
    enemiesToSpawnInCurrentWave = wave.numEnemies;
    enemiesSpawnedInCurrentWave = 0;
    enemiesRemainingInCurrentWave = wave.numEnemies;
    _currentSpawnInterval = wave.spawnInterval;
    _spawnTimer = 0.0;
    waveText.text = 'Wave: $currentWaveNumber/${waves.length}';
  }

  void _startBossPhase() {
    isBossPhase = true;
    waveText.text = 'BOSS PHASE';
    gameStatusText.text = 'Defeat the Boss!';

    final bossHealth = baseBossHealth * (1 + (baseHealthLevel * 0.25));
    currentBoss = Boss(
      sprite: bossSprite,
      position: Vector2(size.x - 300, size.y / 2 - 100),
      size: Vector2(200, 200),
      health: bossHealth,
    );
    add(currentBoss!);
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

  void addGold(double amount, {bool fromKill = false}) {
    currentGold += amount;
    goldText.text = 'Gold: ${currentGold.toInt()}';
    // Only decrement remaining enemies when this gold comes from a kill during normal waves
    if (fromKill && !isGameOver && !gameWon && !isBossPhase) {
      if (enemiesRemainingInCurrentWave > 0) {
        enemiesRemainingInCurrentWave--;
      }
    }
  }

  void _upgradeAllies() {
    // Cap allies level to 4
    if (alliesLevel >= 4) return;
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
    final rowSpacing = 45.0; // reduce vertical spacing between rows
    final baseY =
        playerBase.position.y +
        playerBase.size.y +
        10.0; // lower position closer to buttons
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
