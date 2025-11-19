-- Tabla para registrar transacciones de compra de gemas con Mercado Pago
CREATE TABLE IF NOT EXISTS public.transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  package_id TEXT NOT NULL,
  gems INTEGER NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  currency TEXT DEFAULT 'MXN',
  mercadopago_payment_id TEXT UNIQUE,
  status TEXT DEFAULT 'pending', -- 'pending', 'completed', 'failed'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON public.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON public.transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON public.transactions(created_at);

-- Habilitar RLS (Row Level Security)
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- Política para que los usuarios vean solo sus propias transacciones
CREATE POLICY "Users can view their own transactions"
ON public.transactions FOR SELECT
USING (auth.uid() = user_id);

-- Política para que el servicio pueda insertar transacciones
CREATE POLICY "Service can insert transactions"
ON public.transactions FOR INSERT
WITH CHECK (true);

-- Política para que el servicio pueda actualizar transacciones
CREATE POLICY "Service can update transactions"
ON public.transactions FOR UPDATE
USING (true);

-- Comentarios para documentación
COMMENT ON TABLE public.transactions IS 'Registro de todas las transacciones de compra de gemas';
COMMENT ON COLUMN public.transactions.user_id IS 'ID del usuario que realizó la compra';
COMMENT ON COLUMN public.transactions.package_id IS 'ID del paquete de gemas comprado';
COMMENT ON COLUMN public.transactions.gems IS 'Cantidad de gemas compradas';
COMMENT ON COLUMN public.transactions.amount IS 'Monto pagado';
COMMENT ON COLUMN public.transactions.currency IS 'Moneda utilizada (MXN, USD, etc.)';
COMMENT ON COLUMN public.transactions.mercadopago_payment_id IS 'ID del pago en Mercado Pago';
COMMENT ON COLUMN public.transactions.status IS 'Estado de la transacción';
