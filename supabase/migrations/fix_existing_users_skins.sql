-- Script para dar las skins por defecto a todos los usuarios existentes

-- Insertar skins por defecto para todos los perfiles existentes
INSERT INTO public.player_skins (profile_id, skin_id)
SELECT p.id, s.id 
FROM public.profiles p
CROSS JOIN public.skins s
WHERE s.is_default = true
ON CONFLICT (profile_id, skin_id) DO NOTHING;

-- Mensaje de confirmación
DO $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(DISTINCT profile_id) INTO v_count
  FROM public.player_skins;
  
  RAISE NOTICE 'Skins por defecto otorgadas. Total de usuarios con skins: %', v_count;
END $$;
