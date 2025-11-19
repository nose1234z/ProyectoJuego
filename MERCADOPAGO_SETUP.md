# Configuración de Mercado Pago para IA Defender

## 📋 Pasos de configuración

### 1. Crear tabla de transacciones en Supabase

1. Ve a tu proyecto en Supabase
2. Abre el **SQL Editor**
3. Ejecuta el contenido del archivo: `supabase/migrations/create_transactions_table.sql`
4. Verifica que la tabla `transactions` se haya creado correctamente

### 2. Crear cuenta en Mercado Pago (México)

1. Ve a [mercadopago.com.mx](https://mercadopago.com.mx)
2. Crea una cuenta o inicia sesión
3. Ve a **Tus integraciones** → **Credenciales**
4. Activa el **Modo Prueba** (testing)
5. Copia tu **Access Token de prueba** (TEST-...)
   - Comienza con `TEST-`
   - Lo necesitarás para configurar Supabase

### 3. Desplegar Edge Functions en Supabase

#### Opción A: Usando Supabase CLI (Recomendado)

```bash
# Instalar Supabase CLI (solo una vez)
npm install -g supabase

# Iniciar sesión
supabase login

# Vincular tu proyecto
supabase link --project-ref TU_PROJECT_REF

# Desplegar las funciones
supabase functions deploy create-mercadopago-preference
supabase functions deploy mercadopago-webhook
```

#### Opción B: Desde el Dashboard de Supabase

1. Ve a **Edge Functions** en tu proyecto
2. Haz clic en **Create a new function**
3. Nombre: `create-mercadopago-preference`
4. Copia el contenido de `supabase/functions/create-mercadopago-preference/index.ts`
5. Despliega la función
6. Repite para `mercadopago-webhook`

### 4. Configurar variables de entorno

1. En Supabase Dashboard → **Edge Functions** → **Settings**
2. Agrega la siguiente variable:
   - **Nombre**: `MERCADOPAGO_ACCESS_TOKEN`
   - **Valor**: Tu Access Token de prueba de Mercado Pago (TEST-...)
3. Guarda los cambios

### 5. Configurar webhook en Mercado Pago

1. Ve a Mercado Pago → **Tus integraciones** → **Webhooks**
2. Haz clic en **Crear webhook**
3. **URL de notificación**:
   ```
   https://TU_PROJECT_REF.supabase.co/functions/v1/mercadopago-webhook
   ```
   Reemplaza `TU_PROJECT_REF` con tu ID de proyecto de Supabase
4. **Eventos**: Selecciona `payment`
5. Guarda el webhook

### 6. Probar el sistema

1. Ejecuta tu app: `flutter run`
2. Inicia sesión
3. Abre la tienda de gemas (cuando la integres al menú)
4. Selecciona un paquete
5. Serás redirigido a Mercado Pago
6. Usa estas **tarjetas de prueba** de Mercado Pago:
   - **Aprobada**: 5474 9254 3267 0366
   - **CVV**: 123
   - **Vencimiento**: Cualquier fecha futura
   - **Nombre**: TEST USER

### 7. Verificar el pago

1. Completa el pago en Mercado Pago
2. Vuelve a la app
3. Verifica tus gemas en el perfil
4. En Supabase, revisa la tabla `transactions` para ver el registro

## 🔧 Solución de problemas

### El pago no se procesa

1. Revisa los logs de la Edge Function:
   ```bash
   supabase functions logs mercadopago-webhook
   ```
2. Verifica que el webhook esté configurado correctamente
3. Revisa que el Access Token sea correcto

### No se abre Mercado Pago

1. Verifica que `url_launcher` esté correctamente instalado
2. Revisa que la función `create-mercadopago-preference` esté desplegada
3. Revisa los logs en Supabase

## 💰 Precios configurados (MXN)

- 100 Gemas: $20 MXN
- 500 Gemas: $80 MXN
- 1000 Gemas: $140 MXN
- 5000 Gemas: $600 MXN

Puedes ajustar estos precios en `lib/services/payment_service.dart`

## 🚀 Pasar a producción

Cuando estés listo para producción:

1. En Mercado Pago, desactiva el **Modo Prueba**
2. Copia tu **Access Token de producción** (APP-...)
3. Actualiza la variable `MERCADOPAGO_ACCESS_TOKEN` en Supabase
4. Actualiza el webhook en Mercado Pago con la URL de producción
5. ¡Listo para recibir pagos reales!

## 📱 Integrar la tienda en tu juego

Para mostrar la tienda, agrega un botón en tu menú principal:

```dart
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShopScreen()),
    );
  },
  child: const Text('💎 Comprar Gemas'),
)
```

## 📞 Soporte

Si tienes problemas:
- Revisa la documentación de Mercado Pago: https://www.mercadopago.com.mx/developers
- Verifica los logs en Supabase Dashboard
- Revisa que todas las variables de entorno estén configuradas
