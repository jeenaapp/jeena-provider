-- Add city field to services table
ALTER TABLE public.services 
ADD COLUMN IF NOT EXISTS city TEXT;

-- Update existing services with city from user profile
UPDATE public.services 
SET city = (SELECT city FROM public.users WHERE id = public.services.user_id)
WHERE city IS NULL;