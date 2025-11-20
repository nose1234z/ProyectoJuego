# Script para aplicar la migración de mejoras permanentes
# Este script ejecuta la configuración completa de la base de datos

Write-Host "🔧 Aplicando migración de mejoras permanentes..." -ForegroundColor Cyan
Write-Host ""

# Verificar si supabase CLI está instalado
$supabaseInstalled = Get-Command supabase -ErrorAction SilentlyContinue

if (-not $supabaseInstalled) {
    Write-Host "❌ Supabase CLI no está instalado" -ForegroundColor Red
    Write-Host ""
    Write-Host "Para instalar Supabase CLI:" -ForegroundColor Yellow
    Write-Host "  npm install -g supabase" -ForegroundColor White
    Write-Host ""
    Write-Host "Alternativamente, puedes ejecutar la migración manualmente:" -ForegroundColor Yellow
    Write-Host "  1. Ve a https://supabase.com/dashboard/project/xsfpmymssipfvjeaufqy" -ForegroundColor White
    Write-Host "  2. Abre el SQL Editor" -ForegroundColor White
    Write-Host "  3. Copia y pega el contenido de:" -ForegroundColor White
    Write-Host "     supabase\migrations\complete_database_setup.sql" -ForegroundColor White
    Write-Host "  4. Ejecuta el script" -ForegroundColor White
    exit 1
}

Write-Host "✅ Supabase CLI encontrado" -ForegroundColor Green

# Verificar si el proyecto está vinculado
$linkedProject = supabase status 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "⚠️  Proyecto no vinculado" -ForegroundColor Yellow
    Write-Host "Vinculando proyecto..." -ForegroundColor Cyan
    
    $projectRef = "xsfpmymssipfvjeaufqy"
    supabase link --project-ref $projectRef
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error al vincular el proyecto" -ForegroundColor Red
        Write-Host "Intenta manualmente:" -ForegroundColor Yellow
        Write-Host "  supabase link --project-ref $projectRef" -ForegroundColor White
        exit 1
    }
}

Write-Host "✅ Proyecto vinculado" -ForegroundColor Green
Write-Host ""

# Ejecutar la migración
Write-Host "📤 Ejecutando migración..." -ForegroundColor Cyan
supabase db push

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ ¡Migración aplicada exitosamente!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎮 Ahora puedes:" -ForegroundColor Cyan
    Write-Host "  1. Reiniciar la aplicación" -ForegroundColor White
    Write-Host "  2. Ir a la Tienda → Mejoras" -ForegroundColor White
    Write-Host "  3. Comprar mejoras con tus gemas" -ForegroundColor White
    Write-Host ""
    Write-Host "💎 Las mejoras permanentes ahora funcionan correctamente" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "❌ Error al aplicar la migración" -ForegroundColor Red
    Write-Host ""
    Write-Host "Intenta aplicarla manualmente:" -ForegroundColor Yellow
    Write-Host "  1. Ve a https://supabase.com/dashboard/project/xsfpmymssipfvjeaufqy" -ForegroundColor White
    Write-Host "  2. Abre el SQL Editor" -ForegroundColor White
    Write-Host "  3. Ejecuta el contenido de: supabase\migrations\complete_database_setup.sql" -ForegroundColor White
    exit 1
}
