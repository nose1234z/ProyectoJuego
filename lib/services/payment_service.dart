import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

final supabase = Supabase.instance.client;

class PaymentService {
  // Paquetes de gemas disponibles para compra (precios en MXN - Pesos Mexicanos)
  static final List<Map<String, dynamic>> gemPackages = [
    {
      'id': 'gems_100',
      'name': '100 Gemas',
      'gems': 100,
      'price': 20.0, // $20 MXN
      'priceDisplay': '\$20 MXN',
      'icon': '💎',
    },
    {
      'id': 'gems_500',
      'name': '500 Gemas',
      'gems': 500,
      'price': 80.0, // $80 MXN
      'priceDisplay': '\$80 MXN',
      'icon': '💎💎',
      'badge': '¡Popular!',
    },
    {
      'id': 'gems_1000',
      'name': '1000 Gemas',
      'gems': 1000,
      'price': 140.0, // $140 MXN
      'priceDisplay': '\$140 MXN',
      'icon': '💎💎💎',
    },
    {
      'id': 'gems_5000',
      'name': '5000 Gemas',
      'gems': 5000,
      'price': 600.0, // $600 MXN
      'priceDisplay': '\$600 MXN',
      'icon': '💎💎💎💎',
      'badge': '¡Mejor valor!',
    },
  ];

  /// Crear sesión de checkout en Stripe
  static Future<String> createCheckoutSession({
    required String packageId,
    required double amount,
    required int gems,
  }) async {
    try {
      // Llamar a tu Supabase Edge Function para crear la sesión de Stripe
      final response = await supabase.functions.invoke(
        'create-stripe-checkout',
        body: {
          'packageId': packageId,
          'amount': amount,
          'gems': gems,
          'userId': supabase.auth.currentUser!.id,
        },
      );

      if (response.data != null && response.data['url'] != null) {
        return response.data['url'] as String;
      }
      throw Exception('Error al crear sesión de pago');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Procesar el pago con Stripe en navegador externo
  static Future<bool> processPayment({
    required String packageId,
    required int gems,
    required double price,
    required String title,
  }) async {
    try {
      // print('Iniciando proceso de pago con Stripe...');
      // print('PackageId: $packageId, Gems: $gems, Price: $price');

      // Crear sesión de checkout
      final checkoutUrl = await createCheckoutSession(
        packageId: packageId,
        amount: price,
        gems: gems,
      );

      // print('URL de checkout recibida: $checkoutUrl');

      // Abrir en navegador externo
      final Uri url = Uri.parse(checkoutUrl);

      bool launched = await canLaunchUrl(url);

      if (launched) {
        launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      }

      if (!launched) {
        throw Exception('No se pudo abrir el navegador');
      }

      return true;
    } catch (e) {
      // print('Error detallado en el pago: $e');
      rethrow;
    }
  }

  /// Agregar gemas al usuario después de un pago exitoso
  /// Esta función será llamada por el webhook de Mercado Pago
  static Future<void> addGemsToUser(
    String userId,
    int gems,
    String packageId,
    double amount,
  ) async {
    // Obtener gemas actuales
    final profile = await supabase
        .from('profiles')
        .select('gems')
        .eq('id', userId)
        .single();

    final currentGems = profile['gems'] as int? ?? 0;
    final newTotal = currentGems + gems;

    // Actualizar gemas
    await supabase.from('profiles').update({'gems': newTotal}).eq('id', userId);

    // Registrar la transacción
    await supabase.from('transactions').insert({
      'user_id': userId,
      'package_id': packageId,
      'gems': gems,
      'amount': amount,
      'currency': 'MXN',
      'status': 'completed',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Verificar el estado de un pago (opcional, para mostrar en la app)
  static Future<List<Map<String, dynamic>>> getUserTransactions() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('transactions')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // print('Error al obtener transacciones: $e');
      return [];
    }
  }
}
