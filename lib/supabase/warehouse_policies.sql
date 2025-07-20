-- Enable RLS on warehouse tables
ALTER TABLE public.warehouse_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.warehouse_reservations ENABLE ROW LEVEL SECURITY;

-- Warehouse products table policies
CREATE POLICY "Users can view own products" ON public.warehouse_products FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own products" ON public.warehouse_products FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own products" ON public.warehouse_products FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own products" ON public.warehouse_products FOR DELETE USING (auth.uid() = user_id);

-- Warehouse reservations table policies
CREATE POLICY "Users can view own reservations" ON public.warehouse_reservations FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own reservations" ON public.warehouse_reservations FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own reservations" ON public.warehouse_reservations FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own reservations" ON public.warehouse_reservations FOR DELETE USING (auth.uid() = user_id);