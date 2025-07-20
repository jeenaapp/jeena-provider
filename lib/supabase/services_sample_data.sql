CREATE OR REPLACE FUNCTION insert_user_to_auth(
    email text,
    password text
) RETURNS UUID AS $$
DECLARE
  user_id uuid;
  encrypted_pw text;
BEGIN
  user_id := gen_random_uuid();
  encrypted_pw := crypt(password, gen_salt('bf'));
  
  INSERT INTO auth.users
    (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES
    (gen_random_uuid(), user_id, 'authenticated', 'authenticated', email, encrypted_pw, '2023-05-03 19:41:43.585805+00', '2023-04-22 13:10:03.275387+00', '2023-04-22 13:10:31.458239+00', '{"provider":"email","providers":["email"]}', '{}', '2023-05-03 19:41:43.580424+00', '2023-05-03 19:41:43.585948+00', '', '', '', '');
  
  INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES
    (gen_random_uuid(), user_id, format('{"sub":"%s","email":"%s"}', user_id::text, email)::jsonb, 'email', '2023-05-03 19:41:43.582456+00', '2023-05-03 19:41:43.582497+00', '2023-05-03 19:41:43.582497+00');
  
  RETURN user_id;
END;
$$ LANGUAGE plpgsql;

-- Insert sample services for testing
INSERT INTO public.services (
    user_id, 
    name, 
    description, 
    price, 
    duration_minutes, 
    service_type, 
    city, 
    is_active
) VALUES 
(
    (SELECT id FROM public.users WHERE email = 'ahmed.salon@example.com'),
    'حلاقة وتسريح شعر',
    'خدمة حلاقة احترافية مع تسريح الشعر وتنسيقه حسب الطلب',
    50.00,
    45,
    'grooming',
    'الرياض',
    true
),
(
    (SELECT id FROM public.users WHERE email = 'ahmed.salon@example.com'),
    'قص وتسريح لحية',
    'خدمة قص وتسريح اللحية بأحدث الأساليب',
    30.00,
    30,
    'grooming',
    'الرياض',
    true
),
(
    (SELECT id FROM public.users WHERE email = 'fatima.events@example.com'),
    'تنظيم حفلات الزفاف',
    'تنظيم حفلات زفاف كاملة مع الديكور والتنسيق وتقديم الطعام',
    5000.00,
    480,
    'events',
    'جدة',
    true
),
(
    (SELECT id FROM public.users WHERE email = 'fatima.events@example.com'),
    'تنظيم حفلات الخطوبة',
    'تنظيم حفلات خطوبة مميزة مع الديكور والتنسيق',
    2500.00,
    300,
    'events',
    'جدة',
    true
),
(
    (SELECT id FROM public.users WHERE email = 'omar.tech@example.com'),
    'تطوير المواقع الإلكترونية',
    'تطوير مواقع إلكترونية احترافية ومتجاوبة مع جميع الأجهزة',
    3000.00,
    2880,
    'technology',
    'الدمام',
    true
),
(
    (SELECT id FROM public.users WHERE email = 'omar.tech@example.com'),
    'تطوير التطبيقات المحمولة',
    'تطوير تطبيقات محمولة لأنظمة iOS و Android',
    5000.00,
    4320,
    'technology',
    'الدمام',
    true
);