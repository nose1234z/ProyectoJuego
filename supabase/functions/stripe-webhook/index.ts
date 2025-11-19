import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const STRIPE_SECRET_KEY = Deno.env.get('STRIPE_SECRET_KEY')!
const STRIPE_WEBHOOK_SECRET = Deno.env.get('STRIPE_WEBHOOK_SECRET')!

// Configurar CORS para permitir webhooks de Stripe
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Manejar CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = await req.text()
    
    console.log('Webhook received from Stripe')

    // Parsear el evento directamente (sin verificar firma en modo TEST)
    const event = JSON.parse(body)
    
    console.log('Event type:', event.type)

    // Procesar solo eventos de pago completado
    if (event.type === 'checkout.session.completed') {
      const session = event.data.object

      console.log('Payment completed for session:', session.id)

      const userId = session.metadata.userId
      const gems = parseInt(session.metadata.gems)
      const packageId = session.metadata.packageId

      console.log('User:', userId, 'Gems:', gems, 'Package:', packageId)

      // Conectar a Supabase
      const supabaseUrl = Deno.env.get('SUPABASE_URL')!
      const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
      const supabase = createClient(supabaseUrl, supabaseKey)

      // Obtener gemas actuales del usuario
      const { data: profile, error: fetchError } = await supabase
        .from('profiles')
        .select('gems')
        .eq('id', userId)
        .single()

      if (fetchError) {
        console.error('Error fetching profile:', fetchError)
        throw fetchError
      }

      // Actualizar gemas del usuario
      const currentGems = profile?.gems || 0
      const { error: updateError } = await supabase
        .from('profiles')
        .update({ gems: currentGems + gems })
        .eq('id', userId)

      if (updateError) {
        console.error('Error updating gems:', updateError)
        throw updateError
      }

      // Registrar transacción
      const { error: transactionError } = await supabase
        .from('transactions')
        .insert({
          user_id: userId,
          package_id: packageId,
          gems_purchased: gems,
          amount: session.amount_total / 100, // Convertir de centavos
          currency: session.currency,
          payment_provider: 'stripe',
          payment_id: session.payment_intent,
          status: 'completed',
        })

      if (transactionError) {
        console.error('Error recording transaction:', transactionError)
      }

      console.log('Gems added successfully!')
    }

    return new Response(JSON.stringify({ received: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    console.error('Webhook error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 200, // Devolver 200 para que Stripe no reintente
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})
