-- Function to insert user to auth
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

-- Insert sample users
DO $$
DECLARE
    user1_id uuid;
    user2_id uuid;
    user3_id uuid;
    service1_id uuid;
    service2_id uuid;
    service3_id uuid;
    order1_id uuid;
    order2_id uuid;
BEGIN
    -- Insert users to auth.users first
    user1_id := insert_user_to_auth('ahmed.salon@example.com', 'password123');
    user2_id := insert_user_to_auth('fatima.events@example.com', 'password123');
    user3_id := insert_user_to_auth('omar.tech@example.com', 'password123');

    -- Insert users to public.users
    INSERT INTO public.users (id, email, full_name, specialty, city, phone, jics_code, iban, bank_name, tax_number) VALUES
    (user1_id, 'ahmed.salon@example.com', 'أحمد محمد', 'صالون رجالي', 'الرياض', '+966501234567', generate_jics_code(), 'SA1234567890123456789012', 'البنك الأهلي السعودي', '1234567890'),
    (user2_id, 'fatima.events@example.com', 'فاطمة أحمد', 'تنظيم المناسبات', 'جدة', '+966509876543', generate_jics_code(), 'SA2345678901234567890123', 'بنك الرياض', '2345678901'),
    (user3_id, 'omar.tech@example.com', 'عمر سالم', 'خدمات تقنية', 'الدمام', '+966507654321', generate_jics_code(), 'SA3456789012345678901234', 'بنك ساب', '3456789012');

    -- Insert services
    service1_id := gen_random_uuid();
    service2_id := gen_random_uuid();
    service3_id := gen_random_uuid();

    INSERT INTO public.services (id, user_id, name, description, price, duration_minutes, service_type, is_active) VALUES
    (service1_id, user1_id, 'حلاقة وتسريح', 'خدمة حلاقة وتسريح احترافية للرجال', 50.00, 45, 'grooming', true),
    (service2_id, user2_id, 'تنظيم حفلات الزفاف', 'تنظيم حفلات زفاف كاملة مع الديكور والتنسيق', 5000.00, 480, 'events', true),
    (service3_id, user3_id, 'تطوير المواقع الإلكترونية', 'تطوير مواقع إلكترونية احترافية ومتجاوبة', 3000.00, 2880, 'technology', true);

    -- Insert branches
    INSERT INTO public.branches (user_id, name, address, phone, jics_branch_code, is_active) VALUES
    (user1_id, 'صالون أحمد - الفرع الرئيسي', 'حي الملز، الرياض', '+966501234567', (SELECT generate_branch_jics_code(jics_code) FROM public.users WHERE id = user1_id), true),
    (user2_id, 'فاطمة للمناسبات - الفرع الرئيسي', 'حي الزهراء، جدة', '+966509876543', (SELECT generate_branch_jics_code(jics_code) FROM public.users WHERE id = user2_id), true);

    -- Insert orders
    order1_id := gen_random_uuid();
    order2_id := gen_random_uuid();

    INSERT INTO public.orders (id, provider_id, service_id, customer_name, customer_email, customer_phone, status, total_amount, scheduled_date, notes) VALUES
    (order1_id, user1_id, service1_id, 'محمد العلي', 'mohammed.ali@example.com', '+966501111111', 'completed', 50.00, NOW() - INTERVAL '2 days', 'حلاقة عادية'),
    (order2_id, user2_id, service2_id, 'سارة أحمد', 'sara.ahmed@example.com', '+966502222222', 'in_progress', 5000.00, NOW() + INTERVAL '1 week', 'حفل زفاف في قاعة الماسة');

    -- Insert invoices
    INSERT INTO public.invoices (provider_id, order_id, invoice_number, customer_name, service_type, total_amount, paid_amount, status, due_date, transfer_status) VALUES
    (user1_id, order1_id, generate_invoice_number(), 'محمد العلي', 'حلاقة وتسريح', 50.00, 50.00, 'paid', NOW() - INTERVAL '1 day', 'completed'),
    (user2_id, order2_id, generate_invoice_number(), 'سارة أحمد', 'تنظيم حفلات الزفاف', 5000.00, 2500.00, 'partial', NOW() + INTERVAL '3 days', 'pending');

    -- Insert inventory
    INSERT INTO public.inventory (user_id, service_id, product_name, quantity, unit, notes) VALUES
    (user1_id, service1_id, 'شامبو للشعر', 50, 'زجاجة', 'شامبو احترافي للشعر الجاف'),
    (user1_id, service1_id, 'مقص حلاقة', 5, 'قطعة', 'مقص حلاقة احترافي'),
    (user2_id, service2_id, 'زينة الطاولات', 100, 'قطعة', 'زينة ذهبية للطاولات');

    -- Insert reviews
    INSERT INTO public.reviews (provider_id, order_id, customer_name, rating, comment) VALUES
    (user1_id, order1_id, 'محمد العلي', 5, 'خدمة ممتازة وسريعة، أنصح بها بشدة'),
    (user2_id, order2_id, 'سارة أحمد', 4, 'تنظيم جيد جداً، لكن أتمنى المزيد من الخيارات في الديكور');

    -- Insert notifications
    INSERT INTO public.notifications (user_id, title, message, type, is_read) VALUES
    (user1_id, 'طلب جديد', 'لديك طلب جديد من العميل أحمد سالم', 'info', false),
    (user2_id, 'فاتورة مستحقة', 'فاتورة رقم INV20240101001 مستحقة الدفع', 'warning', false),
    (user3_id, 'مرحباً بك', 'مرحباً بك في منصة جينا للخدمات', 'success', true);

    -- Insert support tickets
    INSERT INTO public.support_tickets (user_id, title, description, status, priority) VALUES
    (user1_id, 'مشكلة في رفع الصور', 'لا أستطيع رفع صور الخدمات الجديدة', 'open', 'medium'),
    (user2_id, 'استفسار عن الفواتير', 'أريد معرفة كيفية تحميل الفواتير بصيغة PDF', 'resolved', 'low');

    -- Insert balance
    INSERT INTO public.balance (user_id, current_balance, total_earned, total_withdrawn) VALUES
    (user1_id, 450.00, 500.00, 50.00),
    (user2_id, 2300.00, 2500.00, 200.00),
    (user3_id, 0.00, 0.00, 0.00);

    -- Insert service providers
    INSERT INTO public.service_providers (user_id, name, city, service_type, description, status) VALUES
    (user1_id, 'أحمد محمد', 'الرياض', 'grooming', 'خدمات حلاقة وتجميل رجالي احترافية مع خبرة تزيد عن 10 سنوات', 'approved'),
    (user2_id, 'فاطمة أحمد', 'جدة', 'events', 'تنظيم مناسبات وحفلات زفاف وخطوبة مع تقديم أفضل الخدمات', 'approved'),
    (user3_id, 'عمر سالم', 'الدمام', 'technology', 'خدمات تقنية شاملة تشمل تطوير المواقع والتطبيقات', 'pending');
END
$$;