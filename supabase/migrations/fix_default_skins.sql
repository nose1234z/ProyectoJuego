-- Script para dar skins predeterminadas a usuarios existentes
-- Ejecutar esto si ya tenías usuarios antes de configurar el sistema de skins

-- Insertar skins predeterminadas para todos los usuarios existentes que no las tengan
INSERT INTO public.player_skins (profile_id, skin_id)
SELECT p.id, s.id 
FROM public.profiles p
CROSS JOIN public.skins s
WHERE s.is_default = true
  AND NOT EXISTS (
    SELECT 1 FROM public.player_skins ps
    WHERE ps.profile_id = p.id AND ps.skin_id = s.id
  )
ON CONFLICT (profile_id, skin_id) DO NOTHING;

-- Verificar que todos los usuarios tengan skins equipadas por defecto
UPDATE public.profiles
SET 
  equipped_tower_skin_id = COALESCE(equipped_tower_skin_id, 'tower_default'),
  equipped_ally_skin_id = COALESCE(equipped_ally_skin_id, 'ally_default'),
  equipped_projectile_skin_id = COALESCE(equipped_projectile_skin_id, 'projectile_default')
WHERE 
  equipped_tower_skin_id IS NULL 
  OR equipped_ally_skin_id IS NULL 
  OR equipped_projectile_skin_id IS NULL;
