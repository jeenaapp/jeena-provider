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


-- Insert additional sample orders with service_type and city
INSERT INTO public.orders (
    provider_id, 
    service_id, 
    customer_name, 
    customer_email, 
    customer_phone, 
    status, 
    service_type, 
    city, 
    total_amount, 
    scheduled_date, 
    notes
) VALUES 
(
    (SELECT id FROM public.users WHERE email = 'ahmed.salon@example.com'),
    (SELECT id FROM public.services WHERE name = 'حلاقة وتسريح'),
    'خالد محمد',
    'khalid.mohammed@example.com',
    '+966501234567',
    'pending',
    'خدمات التجميل والعناية',
    'الرياض',
    75.00,
    NOW() + INTERVAL '2 days',
    'حلاقة وتسريح للمناسبة'
),
(
    (SELECT id FROM public.users WHERE email = 'fatima.events@example.com'),
    (SELECT id FROM public.services WHERE name = 'تنظيم حفلات الزفاف'),
    'نورا أحمد',
    'nora.ahmed@example.com',
    '+966509876543',
    'approved',
    'تنظيم المناسبات',
    'جدة',
    8000.00,
    NOW() + INTERVAL '1 month',
    'حفل خطوبة في قاعة الورد'
),
(
    (SELECT id FROM public.users WHERE email = 'omar.tech@example.com'),
    (SELECT id FROM public.services WHERE name = 'تطوير المواقع الإلكترونية'),
    'سلمان العلي',
    'salman.ali@example.com',
    '+966507654321',
    'rejected',
    'الخدمات التقنية',
    'الدمام',
    2500.00,
    NOW() + INTERVAL '2 weeks',
    'تطوير موقع تجاري'
),
(
    (SELECT id FROM public.users WHERE email = 'ahmed.salon@example.com'),
    (SELECT id FROM public.services WHERE name = 'حلاقة وتسريح'),
    'فهد الشهري',
    'fahd.alshahri@example.com',
    '+966503456789',
    'pending',
    'خدمات التجميل والعناية',
    'الرياض',
    60.00,
    NOW() + INTERVAL '3 days',
    'حلاقة عادية'
),
(
    (SELECT id FROM public.users WHERE email = 'fatima.events@example.com'),
    (SELECT id FROM public.services WHERE name = 'تنظيم حفلات الزفاف'),
    'ريم المطيري',
    'reem.almutairi@example.com',
    '+966504567890',
    'approved',
    'تنظيم المناسبات',
    'جدة',
    12000.00,
    NOW() + INTERVAL '6 weeks',
    'حفل زفاف في منتجع البحر الأحمر'
);