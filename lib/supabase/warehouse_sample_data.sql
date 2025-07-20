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


-- Insert sample warehouse products
DO $$
DECLARE
    user1_id uuid := (SELECT id FROM public.users WHERE email = 'fatima.events@example.com');
    user2_id uuid := (SELECT id FROM public.users WHERE email = 'ahmed.salon@example.com');
    product1_id uuid;
    product2_id uuid;
    product3_id uuid;
    product4_id uuid;
    product5_id uuid;
    product6_id uuid;
BEGIN
    -- Insert sample products for event planner
    product1_id := gen_random_uuid();
    product2_id := gen_random_uuid();
    product3_id := gen_random_uuid();
    product4_id := gen_random_uuid();
    
    INSERT INTO public.warehouse_products (id, user_id, name, description, product_code, model, category, current_stock, min_stock_level, approval_status, approved_by, approved_at) VALUES
    (product1_id, user1_id, 'كراسي شيافاري ذهبية', 'كراسي شيافاري فاخرة باللون الذهبي مناسبة للمناسبات الراقية', generate_product_code('furniture'), 'CHV-GOLD-001', 'furniture', 100, 10, 'approved', 'إدارة الرقابة والجودة', NOW() - INTERVAL '2 days'),
    (product2_id, user1_id, 'طاولات مستديرة كريستال', 'طاولات مستديرة بسطح كريستالي تتسع لـ 8 أشخاص', generate_product_code('furniture'), 'TBL-CRYSTAL-150', 'furniture', 25, 5, 'approved', 'إدارة الرقابة والجودة', NOW() - INTERVAL '1 day'),
    (product3_id, user1_id, 'أضواء LED ملونة', 'أضواء LED قابلة للبرمجة بألوان متعددة', generate_product_code('lighting'), 'LED-RGB-500', 'lighting', 50, 5, 'pending', NULL, NULL),
    (product4_id, user1_id, 'مكبرات صوت احترافية', 'مكبرات صوت احترافية قوة 1000 واط', generate_product_code('sound'), 'SPK-PRO-1000', 'sound', 8, 2, 'approved', 'فريق المبيعات', NOW() - INTERVAL '3 days');
    
    -- Insert sample products for salon
    product5_id := gen_random_uuid();
    product6_id := gen_random_uuid();
    
    INSERT INTO public.warehouse_products (id, user_id, name, description, product_code, model, category, current_stock, min_stock_level, approval_status, approved_by, approved_at) VALUES
    (product5_id, user2_id, 'كراسي حلاقة هيدروليكية', 'كراسي حلاقة هيدروليكية مريحة وعملية', generate_product_code('equipment'), 'CHR-HYDRO-001', 'equipment', 5, 1, 'approved', 'إدارة الرقابة والجودة', NOW() - INTERVAL '1 day'),
    (product6_id, user2_id, 'مرايا إضاءة LED', 'مرايا بإضاءة LED محيطية للحلاقة', generate_product_code('equipment'), 'MIR-LED-001', 'equipment', 10, 2, 'pending', NULL, NULL);
    
    -- Insert sample reservations
    INSERT INTO public.warehouse_reservations (user_id, product_id, customer_name, reserved_quantity, start_date, end_date, status, notes) VALUES
    (user1_id, product1_id, 'سارة أحمد', 50, NOW() + INTERVAL '1 week', NOW() + INTERVAL '1 week + 1 day', 'confirmed', 'حفل زفاف في قاعة الماسة'),
    (user1_id, product2_id, 'سارة أحمد', 10, NOW() + INTERVAL '1 week', NOW() + INTERVAL '1 week + 1 day', 'confirmed', 'حفل زفاف في قاعة الماسة'),
    (user1_id, product1_id, 'أحمد محمد', 30, NOW() + INTERVAL '2 weeks', NOW() + INTERVAL '2 weeks + 1 day', 'reserved', 'حفل تخرج');
    
END
$$;