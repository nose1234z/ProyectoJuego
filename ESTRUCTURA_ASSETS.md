# Estructura de Assets - IA Defender

## 📁 Organización de Carpetas

```
assets/images/
├── base/
│   ├── torres/
│   │   ├── torre.png          (Torre normal - 100% a 71% de vida)
│   │   ├── torreDañada.png    (Torre dañada - 70% a 41% de vida)
│   │   └── torreDestruida.png (Torre destruida - 40% o menos de vida)
│   └── aliados/
│       └── AI.png
├── projectiles/
│   ├── projectile1.png
│   └── projectile2.png
├── enemies/
│   ├── malware.png
│   └── gusano.png
├── boss/
│   └── ADWARE.png
└── escenario/
    ├── inicio.png
    ├── nivel.jpeg
    ├── mapa1.png
    ├── mapa2.png
    ├── mapa3.png
    └── mapa4.png
```

## 🏰 Sistema de Daño Visual de la Torre

La torre cambia automáticamente su apariencia según el porcentaje de vida:

### Estados de la Torre

| Estado | Porcentaje de Vida | Imagen | Descripción |
|--------|-------------------|--------|-------------|
| **Normal** | > 70% | `torre.png` | Torre en perfecto estado |
| **Dañada** | 40% - 70% | `torreDañada.png` | Torre con daño visible |
| **Destruida** | < 40% | `torreDestruida.png` | Torre severamente dañada |

### Implementación Técnica

El cambio de sprite se maneja automáticamente en el componente `Base`:

```dart
// En base.dart - método update()
final healthPercentage = health / maxHealth;

if (healthPercentage <= 0.4) {
  spriteComponent.sprite = destroyedSprite;  // < 40%
} else if (healthPercentage <= 0.7) {
  spriteComponent.sprite = damagedSprite;    // 40-70%
} else {
  spriteComponent.sprite = normalSprite;     // > 70%
}
```

## 🎨 Requisitos de las Imágenes

Para que el sistema funcione correctamente, las imágenes deben:

1. **Tener el mismo tamaño** (100x200 píxeles recomendado)
2. **Mantener el mismo punto de anclaje**
3. **Usar fondo transparente** (formato PNG)
4. **Estar en las rutas correctas** según la estructura de carpetas

## 🔄 Actualización de la Base de Datos

Si ya tenías datos en Supabase, ejecuta este SQL para actualizar las rutas:

```sql
-- Actualizar rutas de skins existentes (ejecutar si ya tienes datos)
UPDATE public.skins 
SET sprite_path = 'base/torres/torre.png' 
WHERE id = 'tower_default';

UPDATE public.skins 
SET sprite_path = 'base/aliados/AI.png' 
WHERE id = 'ally_default';
```

## 📝 Notas Importantes

- El sistema carga automáticamente `torreDañada.png` y `torreDestruida.png` desde la carpeta `torres/`
- Los sprites de daño no son skins seleccionables, son automáticos
- Si una skin personalizada no tiene versiones dañadas, usa las predeterminadas
- El cambio de sprite es instantáneo y ocurre en cada frame
