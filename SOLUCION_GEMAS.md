# 🔧 Solución al problema de compra de mejoras con gemas

## 📝 Problema
Las gemas se compran correctamente pero no se pueden usar para subir el nivel de los atributos permanentes en la tienda.

## 🎯 Causa raíz
La función RPC `purchase_upgrade` no existe en la base de datos de Supabase. El código Dart intenta llamar a esta función pero no ha sido creada.

## ✅ Solución

### Paso 1: Ejecutar la migración SQL

Tienes que ejecutar el archivo `supabase/migrations/create_purchase_upgrade_function.sql` en tu base de datos de Supabase.

#### Opción A: Usando Supabase CLI (Recomendado)

```bash
# Si no tienes Supabase CLI instalado
npm install -g supabase

# Vincular tu proyecto (si aún no lo has hecho)
supabase link --project-ref xsfpmymssipfvjeaufqy

# Ejecutar la migración
supabase db push
```

#### Opción B: Usando el SQL Editor en Supabase Dashboard

1. Ve a tu proyecto en Supabase: https://supabase.com/dashboard/project/xsfpmymssipfvjeaufqy
2. En el menú lateral, haz clic en **SQL Editor**
3. Haz clic en **New query**
4. Copia y pega todo el contenido del archivo `supabase/migrations/create_purchase_upgrade_function.sql`
5. Haz clic en **Run** (o presiona Ctrl+Enter)
6. Verifica que aparezca el mensaje "Success. No rows returned"

### Paso 2: Verificar las tablas necesarias

Asegúrate de que existen las siguientes tablas en tu base de datos:

#### Tabla `profiles`
```sql
-- Verificar que existe
SELECT * FROM profiles LIMIT 1;
```

Si no existe, créala:
```sql
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  gems INT DEFAULT 0,
  username TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Política para que los usuarios vean solo su perfil
CREATE POLICY "Users can view own profile"
ON public.profiles FOR SELECT
USING (auth.uid() = id);

-- Política para que los usuarios actualicen su perfil
CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE
USING (auth.uid() = id);
```

#### Tabla `permanent_upgrades`
```sql
-- Verificar que existe
SELECT * FROM permanent_upgrades LIMIT 1;
```

Si no existe, créala:
```sql
CREATE TABLE IF NOT EXISTS public.permanent_upgrades (
  profile_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  damage_level INT DEFAULT 0,
  health_level INT DEFAULT 0,
  gold_level INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE public.permanent_upgrades ENABLE ROW LEVEL SECURITY;

-- Política para que los usuarios vean solo sus mejoras
CREATE POLICY "Users can view own upgrades"
ON public.permanent_upgrades FOR SELECT
USING (auth.uid() = profile_id);

-- Política para que los usuarios actualicen sus mejoras
CREATE POLICY "Users can update own upgrades"
ON public.permanent_upgrades FOR UPDATE
USING (auth.uid() = profile_id);
```

### Paso 3: Crear trigger para inicializar registros automáticamente

Este trigger crea automáticamente los registros en `profiles` y `permanent_upgrades` cuando un usuario se registra:

```sql
-- Función para crear perfil y mejoras iniciales
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Crear perfil
  INSERT INTO public.profiles (id, gems, username)
  VALUES (
    NEW.id,
    0,
    COALESCE(NEW.raw_user_meta_data->>'username', 'Player')
  )
  ON CONFLICT (id) DO NOTHING;

  -- Crear registro de mejoras permanentes
  INSERT INTO public.permanent_upgrades (profile_id, damage_level, health_level, gold_level)
  VALUES (NEW.id, 0, 0, 0)
  ON CONFLICT (profile_id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger que se ejecuta al crear un usuario
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### Paso 4: Probar la funcionalidad

1. Cierra la app completamente
2. Vuelve a abrirla
3. Ve a la **Tienda** → pestaña **Mejoras**
4. Intenta comprar una mejora (necesitas tener gemas suficientes)
5. Debería funcionar correctamente ahora

## 🔍 Cómo verificar que funcionó

Después de ejecutar la migración, puedes verificar que la función existe:

```sql
-- En el SQL Editor de Supabase
SELECT proname, prosrc 
FROM pg_proc 
WHERE proname = 'purchase_upgrade';
```

Deberías ver la función listada.

## 🐛 Solución de problemas

### Error: "función purchase_upgrade no existe"
- Verifica que ejecutaste correctamente el archivo SQL en Supabase
- Revisa que no haya errores en la consola del SQL Editor

### Error: "Gemas insuficientes"
- Verifica que tienes suficientes gemas en tu cuenta
- Ve a la pestaña "Comprar Gemas" para obtener más

### Error: "Perfil de usuario no encontrado"
- Cierra sesión y vuelve a iniciar sesión
- Si persiste, ejecuta el trigger `handle_new_user` manualmente:
```sql
SELECT public.handle_new_user_manual();
```

## 📊 Costos de las mejoras

Las mejoras tienen un costo exponencial:
- **Daño de Aliados**: Costo base 50 gemas (multiplicador 1.5x por nivel)
- **Vida de la Base**: Costo base 40 gemas (multiplicador 1.5x por nivel)
- **Oro Inicial**: Costo base 100 gemas (multiplicador 1.5x por nivel)

Ejemplo:
- Nivel 1: 50 gemas
- Nivel 2: 75 gemas
- Nivel 3: 112 gemas
- Nivel 4: 168 gemas

## 🎮 ¿Qué hace cada mejora?

- **⚔️ Daño de Aliados**: +2.0 de daño base por nivel
- **❤️ Vida de la Base**: +50 de vida máxima por nivel
- **💰 Oro Inicial**: +25 de oro al comenzar cada partida por nivel
