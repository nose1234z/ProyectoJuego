import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const STRIPE_SECRET_KEY = Deno.env.get('STRIPE_SECRET_KEY')!

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
    const { packageId, amount, gems, userId } = await req.json()

    console.log('Creating Stripe checkout session...')
    console.log('Package:', packageId, 'Amount:', amount, 'Gems:', gems)

    // Crear sesión de checkout en Stripe
    const response = await fetch('https://api.stripe.com/v1/checkout/sessions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${STRIPE_SECRET_KEY}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        'mode': 'payment',
        'line_items[0][price_data][currency]': 'mxn',
        'line_items[0][price_data][product_data][name]': `${gems} Gemas - IA Defender`,
        'line_items[0][price_data][unit_amount]': Math.round(amount * 100).toString(), // Convertir a centavos
        'line_items[0][quantity]': '1',
        'success_url': 'iadefender://payment/success?session_id={CHECKOUT_SESSION_ID}',
        'cancel_url': 'iadefender://payment/cancel',
        'metadata[userId]': userId,
        'metadata[packageId]': packageId,
        'metadata[gems]': gems.toString(),
      }).toString(),
    })

    if (!response.ok) {
      const error = await response.text()
      console.error('Stripe error:', error)
      throw new Error(`Stripe API error: ${error}`)
    }

    const session = await response.json()
    console.log('Checkout session created:', session.id)

    return new Response(
      JSON.stringify({ 
        sessionId: session.id,
        url: session.url,
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
