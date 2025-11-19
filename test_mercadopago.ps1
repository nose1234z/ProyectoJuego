# Script para probar directamente la API de Mercado Pago
$ACCESS_TOKEN = "TEST-8985352967866290-111815-915e4df504a4f63360625be47d91c582-1167364146"

Write-Host "Probando conexion con Mercado Pago..." -ForegroundColor Cyan
Write-Host ""

# Crear una preferencia de prueba
$body = @{
    items = @(
        @{
            title = "Test Gems Package"
            quantity = 1
            unit_price = 20.0
            currency_id = "MXN"
        }
    )
    back_urls = @{
        success = "iadefender://payment/success"
        failure = "iadefender://payment/failure"
        pending = "iadefender://payment/pending"
    }
    auto_return = "approved"
    external_reference = "test-123|gems_100|100"
    notification_url = "https://xsfpmymssipfvjeaufqy.supabase.co/functions/v1/mercadopago-webhook"
    statement_descriptor = "IA DEFENDER"
} | ConvertTo-Json -Depth 10

Write-Host "Enviando peticion a Mercado Pago API..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "https://api.mercadopago.com/checkout/preferences" -Method POST -Headers @{"Authorization" = "Bearer $ACCESS_TOKEN"; "Content-Type" = "application/json"} -Body $body

    Write-Host ""
    Write-Host "SUCCESS! La preferencia se creo correctamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "Preference ID: $($response.id)" -ForegroundColor White
    Write-Host "Init Point: $($response.init_point)" -ForegroundColor White
    Write-Host ""
    Write-Host "El token de Mercado Pago esta funcionando correctamente." -ForegroundColor Green
    Write-Host "URL de prueba (abrela en tu navegador):" -ForegroundColor Cyan
    Write-Host $response.init_point -ForegroundColor White

} catch {
    Write-Host ""
    Write-Host "ERROR al crear la preferencia" -ForegroundColor Red
    Write-Host ""
    
    if ($_.Exception.Response) {
        Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $errorBody = $reader.ReadToEnd()
        $reader.Close()
        Write-Host "Error detallado:" -ForegroundColor Yellow
        Write-Host $errorBody -ForegroundColor White
    } else {
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

Write-Host ""
