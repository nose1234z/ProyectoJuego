import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const MERCADOPAGO_ACCESS_TOKEN = Deno.env.get('MERCADO_PAGO_ACCESS_TOKEN')!

serve(async (req) => {
  // Permitir CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    })
  }

  try {
    const { packageId, title, quantity, unit_price, gems, userId } = await req.json()

    // Validar datos
    if (!packageId || !title || !quantity || !unit_price || !gems || !userId) {
      throw new Error('Faltan datos requeridos')
    }

    // Log del token (primeros caracteres para debugging)
    console.log('Token length:', MERCADOPAGO_ACCESS_TOKEN?.length)
    console.log('Token prefix:', MERCADOPAGO_ACCESS_TOKEN?.substring(0, 10))
    
    // Crear preferencia en Mercado Pago
    const response = await fetch('https://api.mercadopago.com/checkout/preferences', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${MERCADOPAGO_ACCESS_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        items: [
          {
            title,
            quantity,
            unit_price,
            currency_id: 'MXN', // Pesos Mexicanos
          },
        ],
        back_urls: {
          success: 'iadefender://payment/success',
          failure: 'iadefender://payment/failure',
          pending: 'iadefender://payment/pending',
        },
        auto_return: 'approved',
        external_reference: `${userId}|${packageId}|${gems}`, // Datos para identificar después
        notification_url: `${Deno.env.get('SUPABASE_URL')}/functions/v1/mercadopago-webhook`,
        statement_descriptor: 'IA DEFENDER',
      }),
    })

    console.log('Mercado Pago response status:', response.status)

    if (!response.ok) {
      const error = await response.json()
      console.error('Mercado Pago error response:', error)
      throw new Error(`Error de Mercado Pago: ${JSON.stringify(error)}`)
    }

    const preference = await response.json()
    console.log('Preference created successfully:', preference.id)

    return new Response(
      JSON.stringify({ 
        init_point: preference.init_point,
        preference_id: preference.id,
      }),
      { 
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        } 
      }
    )
  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 400,
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    )
  }
})
