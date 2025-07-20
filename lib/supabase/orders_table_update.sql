-- Add missing fields to orders table
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS service_type TEXT,
ADD COLUMN IF NOT EXISTS city TEXT;

-- Update existing orders with service_type and city
UPDATE public.orders 
SET service_type = CASE 
    WHEN EXISTS (SELECT 1 FROM public.services WHERE id = public.orders.service_id AND service_type = 'grooming') THEN 'خدمات التجميل والعناية'
    WHEN EXISTS (SELECT 1 FROM public.services WHERE id = public.orders.service_id AND service_type = 'events') THEN 'تنظيم المناسبات'
    WHEN EXISTS (SELECT 1 FROM public.services WHERE id = public.orders.service_id AND service_type = 'technology') THEN 'الخدمات التقنية'
    ELSE 'خدمات أخرى'
END;

-- Update city from user profile
UPDATE public.orders 
SET city = (SELECT city FROM public.users WHERE id = public.orders.provider_id)
WHERE city IS NULL;

-- Update status values to match requirements
UPDATE public.orders 
SET status = CASE 
    WHEN status = 'new' THEN 'pending'
    WHEN status = 'accepted' THEN 'approved'
    WHEN status = 'cancelled' THEN 'rejected'
    ELSE status
END;