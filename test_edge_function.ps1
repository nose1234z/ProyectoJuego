# Probar la Edge Function de Supabase directamente
# Esto simulara lo que hace la app Flutter

Write-Host "Probando Edge Function de Supabase..." -ForegroundColor Cyan
Write-Host ""

# Datos de prueba (simula lo que envia la app)
$body = @{
    packageId = "gems_100"
    title = "100 Gemas"
    quantity = 1
    unit_price = 20.0
    gems = 100
    userId = "test-user-id-123"
} | ConvertTo-Json

Write-Host "Datos a enviar:" -ForegroundColor Yellow
Write-Host $body
Write-Host ""

# Tu anon key de Supabase
$SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhzZnBteW1zc2lwZnZqZWF1ZnF5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA5MzE0NzQsImV4cCI6MjA0NjUwNzQ3NH0.F8hIQJeYk2D-4Xtqle__oqnNlbkz18mCH4aJbXhqh3Y"

Write-Host "Llamando a Edge Function..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "https://xsfpmymssipfvjeaufqy.supabase.co/functions/v1/create-mercadopago-preference" -Method POST -Headers @{"Authorization" = "Bearer $SUPABASE_ANON_KEY"; "Content-Type" = "application/json"; "apikey" = $SUPABASE_ANON_KEY} -Body $body

    Write-Host ""
    Write-Host "SUCCESS! Edge Function respondio correctamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "Preference ID: $($response.preference_id)" -ForegroundColor White
    Write-Host "Init Point: $($response.init_point)" -ForegroundColor White
    Write-Host ""
    Write-Host "Abre esta URL en tu navegador para probar:" -ForegroundColor Cyan
    Write-Host $response.init_point -ForegroundColor White
    Write-Host ""
    Write-Host "Si ves 'Algo salio mal' en Mercado Pago, el problema NO es el token." -ForegroundColor Yellow
    Write-Host "El problema podria ser:" -ForegroundColor Yellow
    Write-Host "  1. La configuracion de tu cuenta de Mercado Pago" -ForegroundColor White
    Write-Host "  2. El webhook URL no esta configurado en Mercado Pago" -ForegroundColor White
    Write-Host "  3. Tu cuenta necesita activarse (terminar los pasos en el dashboard)" -ForegroundColor White

} catch {
    Write-Host ""
    Write-Host "ERROR en Edge Function" -ForegroundColor Red
    Write-Host ""
    
    if ($_.Exception.Response) {
        Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $errorBody = $reader.ReadToEnd()
        $reader.Close()
        Write-Host "Error detallado:" -ForegroundColor Yellow
        Write-Host $errorBody -ForegroundColor White
        Write-Host ""
        Write-Host "Posibles causas:" -ForegroundColor Yellow
        Write-Host "  1. El secreto MERCADO_PAGO_ACCESS_TOKEN no esta actualizado en Supabase" -ForegroundColor White
        Write-Host "  2. La Edge Function no se redesployo despues de actualizar el secreto" -ForegroundColor White
    } else {
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

Write-Host ""
