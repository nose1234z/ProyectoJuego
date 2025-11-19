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

    // Try to fetch the user's profile
    final profileResponse = await supabase
        .from('profiles')
        .select('gems')
        .eq('id', userId)
        .maybeSingle();

    if (profileResponse != null) {
      gems = profileResponse['gems'] as int;
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
      permanentUpgradeLevels['damage'] = upgradesResponse['damage_level'] as int;
      permanentUpgradeLevels['health'] = upgradesResponse['health_level'] as int;
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
}