-- Función para comprar mejoras permanentes con gemas
-- Esta función asegura que las compras se realicen de forma atómica y segura

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

  -- Obtener las gemas actuales del usuario
  SELECT gems INTO current_gems
  FROM profiles
  WHERE id = user_id;

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
  WHERE profile_id = user_id;

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
  SET gems = gems - upgrade_cost
  WHERE id = user_id;

  -- Incrementar el nivel de la mejora
  IF upgrade_id = 'damage' THEN
    UPDATE permanent_upgrades
    SET damage_level = damage_level + 1
    WHERE profile_id = user_id;
  ELSIF upgrade_id = 'health' THEN
    UPDATE permanent_upgrades
    SET health_level = health_level + 1
    WHERE profile_id = user_id;
  ELSIF upgrade_id = 'gold' THEN
    UPDATE permanent_upgrades
    SET gold_level = gold_level + 1
    WHERE profile_id = user_id;
  END IF;

  -- Log de la compra (opcional, puedes crear una tabla de logs si quieres)
  -- INSERT INTO upgrade_purchases (user_id, upgrade_id, cost, level_after) 
  -- VALUES (user_id, upgrade_id, upgrade_cost, current_level + 1);

END;
$$;

-- Comentario para documentación
COMMENT ON FUNCTION purchase_upgrade IS 'Compra una mejora permanente gastando gemas del usuario';
