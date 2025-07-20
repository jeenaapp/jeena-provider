-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.balance ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "Users can view own profile" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.users FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can delete own profile" ON public.users FOR DELETE USING (auth.uid() = id);

-- Services table policies
CREATE POLICY "Users can view own services" ON public.services FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own services" ON public.services FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own services" ON public.services FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own services" ON public.services FOR DELETE USING (auth.uid() = user_id);

-- Branches table policies
CREATE POLICY "Users can view own branches" ON public.branches FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own branches" ON public.branches FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own branches" ON public.branches FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own branches" ON public.branches FOR DELETE USING (auth.uid() = user_id);

-- Orders table policies
CREATE POLICY "Providers can view own orders" ON public.orders FOR SELECT USING (auth.uid() = provider_id);
CREATE POLICY "Providers can insert orders" ON public.orders FOR INSERT WITH CHECK (auth.uid() = provider_id);
CREATE POLICY "Providers can update own orders" ON public.orders FOR UPDATE USING (auth.uid() = provider_id);
CREATE POLICY "Providers can delete own orders" ON public.orders FOR DELETE USING (auth.uid() = provider_id);

-- Invoices table policies
CREATE POLICY "Providers can view own invoices" ON public.invoices FOR SELECT USING (auth.uid() = provider_id);
CREATE POLICY "Providers can insert invoices" ON public.invoices FOR INSERT WITH CHECK (auth.uid() = provider_id);
CREATE POLICY "Providers can update own invoices" ON public.invoices FOR UPDATE USING (auth.uid() = provider_id);
CREATE POLICY "Providers can delete own invoices" ON public.invoices FOR DELETE USING (auth.uid() = provider_id);

-- Inventory table policies
CREATE POLICY "Users can view own inventory" ON public.inventory FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own inventory" ON public.inventory FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own inventory" ON public.inventory FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own inventory" ON public.inventory FOR DELETE USING (auth.uid() = user_id);

-- Reviews table policies
CREATE POLICY "Providers can view own reviews" ON public.reviews FOR SELECT USING (auth.uid() = provider_id);
CREATE POLICY "Providers can insert reviews" ON public.reviews FOR INSERT WITH CHECK (auth.uid() = provider_id);
CREATE POLICY "Providers can update own reviews" ON public.reviews FOR UPDATE USING (auth.uid() = provider_id);
CREATE POLICY "Providers can delete own reviews" ON public.reviews FOR DELETE USING (auth.uid() = provider_id);

-- Notifications table policies
CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert notifications" ON public.notifications FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own notifications" ON public.notifications FOR DELETE USING (auth.uid() = user_id);

-- Support tickets table policies
CREATE POLICY "Users can view own support tickets" ON public.support_tickets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own support tickets" ON public.support_tickets FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own support tickets" ON public.support_tickets FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own support tickets" ON public.support_tickets FOR DELETE USING (auth.uid() = user_id);

-- Balance table policies
CREATE POLICY "Users can view own balance" ON public.balance FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own balance" ON public.balance FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own balance" ON public.balance FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own balance" ON public.balance FOR DELETE USING (auth.uid() = user_id);

-- Service providers table policies
ALTER TABLE public.service_providers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own service provider data" ON public.service_providers FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own service provider data" ON public.service_providers FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own service provider data" ON public.service_providers FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own service provider data" ON public.service_providers FOR DELETE USING (auth.uid() = user_id);