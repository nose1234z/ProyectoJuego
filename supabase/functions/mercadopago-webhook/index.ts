import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const MERCADOPAGO_ACCESS_TOKEN = Deno.env.get('MERCADO_PAGO_ACCESS_TOKEN')!
const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

serve(async (req) => {
  try {
    const body = await req.json()
    console.log('Webhook recibido:', JSON.stringify(body))

    // Mercado Pago envía notificaciones de tipo 'payment'
    if (body.type === 'payment') {
      const paymentId = body.data?.id
      
      if (!paymentId) {
        console.error('No se encontró ID de pago')
        return new Response(JSON.stringify({ ok: false }), { status: 400 })
      }

      // Obtener información del pago
      const paymentResponse = await fetch(
        `https://api.mercadopago.com/v1/payments/${paymentId}`,
        {
          headers: {
            'Authorization': `Bearer ${MERCADOPAGO_ACCESS_TOKEN}`,
          },
        }
      )

      if (!paymentResponse.ok) {
        throw new Error('Error al obtener información del pago')
      }

      const payment = await paymentResponse.json()
      console.log('Estado del pago:', payment.status)

      // Solo procesar pagos aprobados
      if (payment.status === 'approved') {
        // Extraer información del external_reference
        const externalRef = payment.external_reference
        if (!externalRef) {
          console.error('No se encontró external_reference')
          return new Response(JSON.stringify({ ok: false }), { status: 400 })
        }

        const [userId, packageId, gemsStr] = externalRef.split('|')
        const gems = parseInt(gemsStr)

        console.log(`Procesando pago para usuario ${userId}, ${gems} gemas`)

        const supabase = createClient(supabaseUrl, supabaseKey)

        // Verificar si ya procesamos este pago
        const { data: existingTransaction } = await supabase
          .from('transactions')
          .select('id')
          .eq('mercadopago_payment_id', paymentId.toString())
          .single()

        if (existingTransaction) {
          console.log('Pago ya procesado')
          return new Response(JSON.stringify({ ok: true, message: 'Ya procesado' }))
        }

        // Obtener gemas actuales
        const { data: profile } = await supabase
          .from('profiles')
          .select('gems')
          .eq('id', userId)
          .single()

        const currentGems = profile?.gems || 0
        const newTotal = currentGems + gems

        console.log(`Gemas actuales: ${currentGems}, nuevas: ${gems}, total: ${newTotal}`)

        // Actualizar gemas
        const { error: updateError } = await supabase
          .from('profiles')
          .update({ gems: newTotal })
          .eq('id', userId)

        if (updateError) {
          throw new Error(`Error al actualizar gemas: ${updateError.message}`)
        }

        // Registrar transacción
        const { error: insertError } = await supabase.from('transactions').insert({
          user_id: userId,
          package_id: packageId,
          gems: gems,
          amount: payment.transaction_amount,
          currency: payment.currency_id,
          mercadopago_payment_id: paymentId.toString(),
          status: 'completed',
        })

        if (insertError) {
          throw new Error(`Error al registrar transacción: ${insertError.message}`)
        }

        console.log('Pago procesado exitosamente')
      }
    }

    return new Response(JSON.stringify({ ok: true }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('Error en webhook:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    )
  }
})
