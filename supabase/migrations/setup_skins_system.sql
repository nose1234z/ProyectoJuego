-- Eliminar tablas existentes si hay conflictos (opcional, comentar si quieres mantener datos)
DROP TABLE IF EXISTS public.player_skins CASCADE;
DROP TABLE IF EXISTS public.skins CASCADE;

-- Crear tabla de skins disponibles en el juego
CREATE TABLE public.skins (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL, -- 'tower', 'ally', 'projectile', etc.
  sprite_path TEXT NOT NULL,
  gem_cost INTEGER NOT NULL DEFAULT 0,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Insertar skins por defecto ANTES de crear las foreign keys
INSERT INTO public.skins (id, name, category, sprite_path, gem_cost, is_default) VALUES
  ('tower_default', 'Torre Clásica', 'tower', 'base/torres/torre.png', 0, true),
  ('ally_default', 'IA Defensor', 'ally', 'base/aliados/AI.png', 0, true),
  ('projectile_default', 'Proyectil Básico', 'projectile', 'projectiles/projectile1.png', 0, true),
  ('projectile_fire', 'Proyectil de Fuego', 'projectile', 'projectiles/projectile2.png', 150, false)
ON CONFLICT (id) DO NOTHING;

-- Crear tabla de skins que posee cada jugador
CREATE TABLE public.player_skins (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  profile_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  skin_id TEXT REFERENCES public.skins(id) ON DELETE CASCADE NOT NULL,
  purchased_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(profile_id, skin_id)
);

-- Agregar columnas a profiles para skins equipadas (DESPUÉS de insertar las skins)
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS equipped_tower_skin_id TEXT REFERENCES public.skins(id) DEFAULT 'tower_default',
ADD COLUMN IF NOT EXISTS equipped_ally_skin_id TEXT REFERENCES public.skins(id) DEFAULT 'ally_default',
ADD COLUMN IF NOT EXISTS equipped_projectile_skin_id TEXT REFERENCES public.skins(id) DEFAULT 'projectile_default';

-- Función para dar las skins por defecto a un usuario nuevo
CREATE OR REPLACE FUNCTION give_default_skins()
RETURNS TRIGGER AS $$
BEGIN
  -- Insertar las skins por defecto en player_skins
  INSERT INTO public.player_skins (profile_id, skin_id)
  SELECT NEW.id, id FROM public.skins WHERE is_default = true
  ON CONFLICT (profile_id, skin_id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para dar skins por defecto cuando se crea un perfil
DROP TRIGGER IF EXISTS on_profile_created_give_skins ON public.profiles;
CREATE TRIGGER on_profile_created_give_skins
  AFTER INSERT ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION give_default_skins();

-- Función RPC para comprar una skin
CREATE OR REPLACE FUNCTION purchase_skin(p_skin_id TEXT)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID;
  v_skin_cost INTEGER;
  v_current_gems INTEGER;
BEGIN
  -- Obtener el ID del usuario actual
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Usuario no autenticado';
  END IF;
  
  -- Verificar que la skin existe y obtener su costo
  SELECT gem_cost INTO v_skin_cost
  FROM public.skins
  WHERE id = p_skin_id;
  
  IF v_skin_cost IS NULL THEN
    RAISE EXCEPTION 'Skin no encontrada';
  END IF;
  
  -- Verificar si ya posee la skin
  IF EXISTS (
    SELECT 1 FROM public.player_skins 
    WHERE profile_id = v_user_id AND skin_id = p_skin_id
  ) THEN
    RAISE EXCEPTION 'Ya posees esta skin';
  END IF;
  
  -- Obtener gemas actuales
  SELECT gems INTO v_current_gems
  FROM public.profiles
  WHERE id = v_user_id
  FOR UPDATE;
  
  -- Verificar que tiene suficientes gemas
  IF v_current_gems < v_skin_cost THEN
    RAISE EXCEPTION 'Gemas insuficientes';
  END IF;
  
  -- Deducir gemas
  UPDATE public.profiles
  SET gems = gems - v_skin_cost
  WHERE id = v_user_id;
  
  -- Agregar skin al inventario
  INSERT INTO public.player_skins (profile_id, skin_id)
  VALUES (v_user_id, p_skin_id);
  
  RETURN json_build_object(
    'success', true,
    'remaining_gems', v_current_gems - v_skin_cost
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función RPC para equipar una skin
CREATE OR REPLACE FUNCTION equip_skin(p_skin_id TEXT, p_category TEXT)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID;
  v_sprite_path TEXT;
BEGIN
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Usuario no autenticado';
  END IF;
  
  -- Verificar que el usuario posee la skin
  IF NOT EXISTS (
    SELECT 1 FROM public.player_skins 
    WHERE profile_id = v_user_id AND skin_id = p_skin_id
  ) THEN
    RAISE EXCEPTION 'No posees esta skin';
  END IF;
  
  -- Verificar que la skin es de la categoría correcta
  SELECT sprite_path INTO v_sprite_path
  FROM public.skins
  WHERE id = p_skin_id AND category = p_category;
  
  IF v_sprite_path IS NULL THEN
    RAISE EXCEPTION 'Skin no encontrada o categoría incorrecta';
  END IF;
  
  -- Equipar la skin según la categoría
  CASE p_category
    WHEN 'tower' THEN
      UPDATE public.profiles SET equipped_tower_skin_id = p_skin_id WHERE id = v_user_id;
    WHEN 'ally' THEN
      UPDATE public.profiles SET equipped_ally_skin_id = p_skin_id WHERE id = v_user_id;
    WHEN 'projectile' THEN
      UPDATE public.profiles SET equipped_projectile_skin_id = p_skin_id WHERE id = v_user_id;
    ELSE
      RAISE EXCEPTION 'Categoría inválida';
  END CASE;
  
  RETURN json_build_object('success', true, 'sprite_path', v_sprite_path);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Habilitar RLS (Row Level Security)
ALTER TABLE public.skins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.player_skins ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si las hay
DROP POLICY IF EXISTS "Skins son públicas" ON public.skins;
DROP POLICY IF EXISTS "Usuarios ven sus propias skins" ON public.player_skins;
DROP POLICY IF EXISTS "Sistema puede insertar skins" ON public.player_skins;

-- Políticas de seguridad para skins (todos pueden leer)
CREATE POLICY "Skins son públicas" ON public.skins FOR SELECT USING (true);

-- Políticas para player_skins (solo el dueño puede ver sus skins)
CREATE POLICY "Usuarios ven sus propias skins" ON public.player_skins 
  FOR SELECT USING (auth.uid() = profile_id);

CREATE POLICY "Sistema puede insertar skins" ON public.player_skins 
  FOR INSERT WITH CHECK (auth.uid() = profile_id);
