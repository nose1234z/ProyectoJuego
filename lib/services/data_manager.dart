import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

// Helper function to get the Supabase client instance
final supabase = Supabase.instance.client;

class DataManager {
  // --- Player Data (from Supabase) ---
  int gems = 0;
  Map<String, int> permanentUpgradeLevels = {
    'damage': 0,
    'health': 0,
    'gold': 0,
  };

  // --- Skin System ---
  Set<String> ownedSkins = {
    'base/torre.png',
    'base/AI.png',
    'projectiles/projectile1.png',
  }; // Skins que el usuario posee (las básicas + compradas)

  Map<String, String> equippedSkins = {
    'tower': 'base/torre.png',
    'ally': 'base/AI.png',
    'projectile': 'projectiles/projectile1.png',
  }; // Skins actualmente equipadas

  // The UI will have its own representation of shop items.
  // This can be defined in the UI layer.
  final List<Map<String, dynamic>> shopItems = [
    {
      'id': 'damage',
      'name': 'Daño de Aliados',
      'description': 'Aumenta el daño base de todas las unidades aliadas.',
      'base_cost': 50,
      'icon': '⚔️',
    },
    {
      'id': 'health',
      'name': 'Vida de la Base',
      'description': 'Aumenta la vida máxima de tu base.',
      'base_cost': 40,
      'icon': '❤️',
    },
    {
      'id': 'gold',
      'name': 'Oro Inicial',
      'description': 'Empiezas cada partida con más oro.',
      'base_cost': 100,
      'icon': '💰',
    },
  ];

  /// Loads all user data from Supabase.
  /// If the user is new, it creates their initial records.
  Future<void> load() async {
    if (supabase.auth.currentUser == null) {
      // Not logged in, do nothing.
      return;
    }
    final userId = supabase.auth.currentUser!.id;

    // Try to fetch the user's profile with equipped skins
    final profileResponse = await supabase
        .from('profiles')
        .select(
          'gems, equipped_tower_skin_id, equipped_ally_skin_id, equipped_projectile_skin_id',
        )
        .eq('id', userId)
        .maybeSingle();

    if (profileResponse != null) {
      gems = profileResponse['gems'] as int;

      // Cargar skins equipadas desde la base de datos
      await _loadEquippedSkins(profileResponse);
    } else {
      // This user is new, create a profile for them
      await supabase.from('profiles').insert({'id': userId, 'gems': 0});
      gems = 0;
    }

    // Try to fetch permanent upgrades
    final upgradesResponse = await supabase
        .from('permanent_upgrades')
        .select('damage_level, health_level, gold_level')
        .eq('profile_id', userId)
        .maybeSingle();

    if (upgradesResponse != null) {
      permanentUpgradeLevels['damage'] =
          upgradesResponse['damage_level'] as int;
      permanentUpgradeLevels['health'] =
          upgradesResponse['health_level'] as int;
      permanentUpgradeLevels['gold'] = upgradesResponse['gold_level'] as int;
    } else {
      // This user is new, create an upgrades record for them
      await supabase.from('permanent_upgrades').insert({
        'profile_id': userId,
        'damage_level': 0,
        'health_level': 0,
        'gold_level': 0,
      });
      // Levels are already 0 by default
    }

    // Cargar skins que el usuario posee
    await _loadOwnedSkins();
  }

  Future<void> _loadEquippedSkins(Map<String, dynamic> profile) async {
    // Obtener las skins equipadas desde sus IDs
    final towerSkinId = profile['equipped_tower_skin_id'] as String?;
    final allySkinId = profile['equipped_ally_skin_id'] as String?;
    final projectileSkinId = profile['equipped_projectile_skin_id'] as String?;

    // Consultar las rutas de sprites para cada skin equipada
    if (towerSkinId != null) {
      final skin = await supabase
          .from('skins')
          .select('sprite_path')
          .eq('id', towerSkinId)
          .maybeSingle();
      if (skin != null) {
        equippedSkins['tower'] = skin['sprite_path'] as String;
      }
    }

    if (allySkinId != null) {
      final skin = await supabase
          .from('skins')
          .select('sprite_path')
          .eq('id', allySkinId)
          .maybeSingle();
      if (skin != null) {
        equippedSkins['ally'] = skin['sprite_path'] as String;
      }
    }

    if (projectileSkinId != null) {
      final skin = await supabase
          .from('skins')
          .select('sprite_path')
          .eq('id', projectileSkinId)
          .maybeSingle();
      if (skin != null) {
        equippedSkins['projectile'] = skin['sprite_path'] as String;
      }
    }
  }

  Future<void> _loadOwnedSkins() async {
    final userId = supabase.auth.currentUser!.id;

    // Obtener todas las skins que el usuario posee
    final playerSkinsResponse = await supabase
        .from('player_skins')
        .select('skin_id, skins!inner(sprite_path)')
        .eq('profile_id', userId);

    ownedSkins.clear();
    for (final item in playerSkinsResponse) {
      final skinData = item['skins'] as Map<String, dynamic>;
      ownedSkins.add(skinData['sprite_path'] as String);
    }

    // Debug: mostrar skins cargadas
    print('DEBUG: Skins cargadas desde DB: $ownedSkins');
  }

  /// --- Gem Management ---

  Future<void> addGems(int amount) async {
    final newTotal = gems + amount;
    await supabase
        .from('profiles')
        .update({'gems': newTotal})
        .eq('id', supabase.auth.currentUser!.id);
    gems = newTotal;
  }

  /// --- Upgrade Management ---

  int getUpgradeLevel(String upgradeId) {
    return permanentUpgradeLevels[upgradeId] ?? 0;
  }

  int getUpgradeCost(String upgradeId) {
    final item = shopItems.firstWhere((item) => item['id'] == upgradeId);
    final baseCost = item['base_cost'] as int;
    final level = getUpgradeLevel(upgradeId);
    // Using dart:math's pow
    return (baseCost * pow(1.5, level)).toInt();
  }

  /// Securely purchases an upgrade by calling a Supabase RPC function.
  Future<void> purchaseUpgrade(String upgradeId) async {
    await supabase.rpc('purchase_upgrade', params: {'upgrade_id': upgradeId});
    // After purchase, reload the data to reflect the changes
    await load();
  }

  /// --- Game Stat Calculation ---

  double get permanentDamageBonus {
    return (getUpgradeLevel('damage') * 2.0);
  }

  double get permanentHealthBonus {
    return (getUpgradeLevel('health') * 50.0);
  }

  double get permanentGoldBonus {
    return (getUpgradeLevel('gold') * 25.0);
  }

  /// --- Skin Management ---

  Future<void> equipSkin(String category, String skinPath) async {
    if (!ownedSkins.contains(skinPath)) {
      throw Exception('No posees esta skin');
    }

    // Obtener el skin_id desde sprite_path
    final skinResponse = await supabase
        .from('skins')
        .select('id')
        .eq('sprite_path', skinPath)
        .eq('category', category)
        .maybeSingle();

    if (skinResponse == null) {
      throw Exception('Skin no encontrada');
    }

    final skinId = skinResponse['id'] as String;

    // Llamar a la función RPC para equipar
    await supabase.rpc(
      'equip_skin',
      params: {'p_skin_id': skinId, 'p_category': category},
    );

    // Actualizar localmente
    equippedSkins[category] = skinPath;
  }

  Future<void> purchaseSkin(String skinPath) async {
    // Obtener el skin_id desde sprite_path
    final skinResponse = await supabase
        .from('skins')
        .select('id, gem_cost')
        .eq('sprite_path', skinPath)
        .maybeSingle();

    if (skinResponse == null) {
      throw Exception('Skin no encontrada');
    }

    final skinId = skinResponse['id'] as String;

    // Llamar a la función RPC para comprar
    final result = await supabase.rpc(
      'purchase_skin',
      params: {'p_skin_id': skinId},
    );

    // Actualizar datos locales
    ownedSkins.add(skinPath);
    gems = result['remaining_gems'] as int;
  }

  bool isSkinOwned(String skinPath) {
    return ownedSkins.contains(skinPath);
  }

  String? getEquippedSkin(String category) {
    return equippedSkins[category];
  }

  /// Obtener todas las skins disponibles desde la base de datos
  Future<List<Map<String, dynamic>>> getAvailableSkins(String category) async {
    final response = await supabase
        .from('skins')
        .select('id, name, sprite_path, gem_cost, is_default')
        .eq('category', category)
        .order('gem_cost');

    return List<Map<String, dynamic>>.from(response);
  }
}
