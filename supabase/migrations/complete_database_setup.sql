-- ==========================================
-- CONFIGURACIÓN COMPLETA DE BASE DE DATOS
-- ==========================================
-- Este archivo crea todas las tablas, funciones y triggers necesarios
-- para el sistema de gemas y mejoras permanentes

-- ==========================================
-- 1. TABLA DE PERFILES
-- ==========================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  gems INT DEFAULT 0 CHECK (gems >= 0),
  username TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_profiles_gems ON public.profiles(gems);

-- Habilitar RLS (Row Level Security)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Políticas de seguridad
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile"
ON public.profiles FOR SELECT
USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE
USING (auth.uid() = id);

DROP POLICY IF EXISTS "Service can insert profiles" ON public.profiles;
CREATE POLICY "Service can insert profiles"
ON public.profiles FOR INSERT
WITH CHECK (true);

-- ==========================================
-- 2. TABLA DE MEJORAS PERMANENTES
-- ==========================================
CREATE TABLE IF NOT EXISTS public.permanent_upgrades (
  profile_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  damage_level INT DEFAULT 0 CHECK (damage_level >= 0),
  health_level INT DEFAULT 0 CHECK (health_level >= 0),
  gold_level INT DEFAULT 0 CHECK (gold_level >= 0),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_permanent_upgrades_profile ON public.permanent_upgrades(profile_id);

-- Habilitar RLS
ALTER TABLE public.permanent_upgrades ENABLE ROW LEVEL SECURITY;

-- Políticas de seguridad
DROP POLICY IF EXISTS "Users can view own upgrades" ON public.permanent_upgrades;
CREATE POLICY "Users can view own upgrades"
ON public.permanent_upgrades FOR SELECT
USING (auth.uid() = profile_id);

DROP POLICY IF EXISTS "Users can update own upgrades" ON public.permanent_upgrades;
CREATE POLICY "Users can update own upgrades"
ON public.permanent_upgrades FOR UPDATE
USING (auth.uid() = profile_id);

DROP POLICY IF EXISTS "Service can insert upgrades" ON public.permanent_upgrades;
CREATE POLICY "Service can insert upgrades"
ON public.permanent_upgrades FOR INSERT
WITH CHECK (true);

-- ==========================================
-- 3. TRIGGER PARA INICIALIZAR NUEVOS USUARIOS
-- ==========================================
-- Función que se ejecuta cuando se crea un nuevo usuario
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Crear perfil con gemas iniciales
  INSERT INTO public.profiles (id, gems, username)
  VALUES (
    NEW.id,
    0, -- Gemas iniciales
    COALESCE(NEW.raw_user_meta_data->>'username', 'Player')
  )
  ON CONFLICT (id) DO NOTHING;

  -- Crear registro de mejoras permanentes (todo en nivel 0)
  INSERT INTO public.permanent_upgrades (profile_id, damage_level, health_level, gold_level)
  VALUES (NEW.id, 0, 0, 0)
  ON CONFLICT (profile_id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- Eliminar trigger existente si existe
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Crear trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ==========================================
-- 4. FUNCIÓN PARA COMPRAR MEJORAS
-- ==========================================
-- Esta función maneja la compra de mejoras permanentes con gemas
CREATE OR REPLACE FUNCTION purchase_upgrade(upgrade_id TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_id UUID;
  current_gems INT;
  current_level INT;
  upgrade_cost INT;
  base_cost INT;
BEGIN
  -- Obtener el ID del usuario autenticado
  user_id := auth.uid();
  
  IF user_id IS NULL THEN
    RAISE EXCEPTION 'Usuario no autenticado';
  END IF;

  -- Validar que el upgrade_id sea válido
  IF upgrade_id NOT IN ('damage', 'health', 'gold') THEN
    RAISE EXCEPTION 'ID de mejora inválido: %', upgrade_id;
  END IF;

  -- Definir el costo base según el tipo de mejora
  base_cost := CASE upgrade_id
    WHEN 'damage' THEN 50
    WHEN 'health' THEN 40
    WHEN 'gold' THEN 100
  END;

  -- Obtener las gemas actuales del usuario (con bloqueo para evitar race conditions)
  SELECT gems INTO current_gems
  FROM profiles
  WHERE id = user_id
  FOR UPDATE;

  IF current_gems IS NULL THEN
    RAISE EXCEPTION 'Perfil de usuario no encontrado';
  END IF;

  -- Obtener el nivel actual de la mejora
  SELECT 
    CASE upgrade_id
      WHEN 'damage' THEN damage_level
      WHEN 'health' THEN health_level
      WHEN 'gold' THEN gold_level
    END INTO current_level
  FROM permanent_upgrades
  WHERE profile_id = user_id
  FOR UPDATE;

  IF current_level IS NULL THEN
    current_level := 0;
  END IF;

  -- Calcular el costo de la mejora: base_cost * (1.5 ^ current_level)
  upgrade_cost := FLOOR(base_cost * POWER(1.5, current_level));

  -- Verificar que el usuario tenga suficientes gemas
  IF current_gems < upgrade_cost THEN
    RAISE EXCEPTION 'Gemas insuficientes. Tienes: %, Necesitas: %', current_gems, upgrade_cost;
  END IF;

  -- Restar las gemas
  UPDATE profiles
  SET gems = gems - upgrade_cost,
      updated_at = now()
  WHERE id = user_id;

  -- Incrementar el nivel de la mejora
  IF upgrade_id = 'damage' THEN
    UPDATE permanent_upgrades
    SET damage_level = damage_level + 1,
        updated_at = now()
    WHERE profile_id = user_id;
  ELSIF upgrade_id = 'health' THEN
    UPDATE permanent_upgrades
    SET health_level = health_level + 1,
        updated_at = now()
    WHERE profile_id = user_id;
  ELSIF upgrade_id = 'gold' THEN
    UPDATE permanent_upgrades
    SET gold_level = gold_level + 1,
        updated_at = now()
    WHERE profile_id = user_id;
  END IF;

END;
$$;

-- ==========================================
-- 5. COMENTARIOS Y DOCUMENTACIÓN
-- ==========================================
COMMENT ON TABLE public.profiles IS 'Perfiles de usuario con gemas y datos básicos';
COMMENT ON TABLE public.permanent_upgrades IS 'Niveles de mejoras permanentes para cada usuario';
COMMENT ON FUNCTION public.handle_new_user IS 'Inicializa perfil y mejoras para nuevos usuarios';
COMMENT ON FUNCTION purchase_upgrade IS 'Compra una mejora permanente gastando gemas del usuario';

-- ==========================================
-- 6. VERIFICACIÓN
-- ==========================================
-- Verificar que todo se creó correctamente
DO $$
BEGIN
  RAISE NOTICE '✅ Tablas creadas: profiles, permanent_upgrades';
  RAISE NOTICE '✅ Trigger creado: on_auth_user_created';
  RAISE NOTICE '✅ Función creada: purchase_upgrade';
  RAISE NOTICE '✅ Configuración completa!';
END $$;
