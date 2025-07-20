-- Users table (extends auth.users)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT NOT NULL,
    full_name TEXT,
    specialty TEXT,
    city TEXT,
    phone TEXT,
    logo_url TEXT,
    jics_code TEXT UNIQUE,
    iban TEXT,
    bank_name TEXT,
    tax_number TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Services table
CREATE TABLE IF NOT EXISTS public.services (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    branch_id UUID REFERENCES public.branches(id) ON DELETE SET NULL,
    warehouse_id UUID,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2),
    duration_minutes INTEGER,
    service_type TEXT,
    city TEXT,
    quantity INTEGER DEFAULT 1,
    notes TEXT,
    image_url TEXT,
    image_urls JSONB,
    video_url TEXT,
    internal_code TEXT,
    admin_status TEXT DEFAULT 'pending',
    admin_notes TEXT,
    admin_reviewed_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Branches table
CREATE TABLE IF NOT EXISTS public.branches (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    provider_id UUID REFERENCES public.service_providers(id) ON DELETE CASCADE NOT NULL,
    branch_name TEXT NOT NULL,
    branch_code TEXT UNIQUE,
    city TEXT NOT NULL,
    exact_location TEXT NOT NULL,
    contact_number TEXT NOT NULL,
    branch_manager_name TEXT NOT NULL,
    branch_manager_email TEXT NOT NULL,
    logo_url TEXT,
    is_active BOOLEAN DEFAULT true,
    is_archived BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Orders table
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    provider_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    service_id UUID REFERENCES public.services(id) ON DELETE CASCADE NOT NULL,
    customer_name TEXT NOT NULL,
    customer_email TEXT,
    customer_phone TEXT,
    status TEXT DEFAULT 'new' CHECK (status IN ('new', 'accepted', 'in_progress', 'completed', 'cancelled')),
    total_amount DECIMAL(10,2),
    scheduled_date TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Invoices table
CREATE TABLE IF NOT EXISTS public.invoices (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    provider_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    invoice_number TEXT UNIQUE NOT NULL,
    customer_name TEXT NOT NULL,
    service_type TEXT,
    total_amount DECIMAL(10,2) NOT NULL,
    paid_amount DECIMAL(10,2) DEFAULT 0,
    status TEXT DEFAULT 'unpaid' CHECK (status IN ('unpaid', 'partial', 'paid')),
    due_date TIMESTAMP WITH TIME ZONE,
    paid_date TIMESTAMP WITH TIME ZONE,
    transfer_status TEXT DEFAULT 'pending' CHECK (transfer_status IN ('pending', 'processing', 'completed', 'rejected')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Inventory table
CREATE TABLE IF NOT EXISTS public.inventory (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    service_id UUID REFERENCES public.services(id) ON DELETE CASCADE,
    product_name TEXT NOT NULL,
    quantity INTEGER DEFAULT 0,
    unit TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Reviews table
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    provider_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
    customer_name TEXT NOT NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    provider_response TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'info' CHECK (type IN ('info', 'success', 'warning', 'error')),
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Support tickets table
CREATE TABLE IF NOT EXISTS public.support_tickets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    attachment_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Verification codes table for email confirmations
CREATE TABLE IF NOT EXISTS public.verification_codes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT NOT NULL,
    code TEXT NOT NULL,
    purpose TEXT NOT NULL, -- 'branch_deletion', 'email_verification', etc.
    entity_id UUID, -- Reference to the branch or entity being verified
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_used BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Balance table
CREATE TABLE IF NOT EXISTS public.balance (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    current_balance DECIMAL(10,2) DEFAULT 0,
    total_earned DECIMAL(10,2) DEFAULT 0,
    total_withdrawn DECIMAL(10,2) DEFAULT 0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Function to generate JICS codes
CREATE OR REPLACE FUNCTION generate_jics_code()
RETURNS TEXT AS $$
BEGIN
    RETURN 'JICS' || LPAD(FLOOR(RANDOM() * 100000)::TEXT, 5, '0');
END;
$$ LANGUAGE plpgsql;

-- Function to generate branch JICS codes
CREATE OR REPLACE FUNCTION generate_branch_jics_code(provider_id UUID)
RETURNS TEXT AS $$
DECLARE
    provider_code TEXT;
    branch_count INTEGER;
BEGIN
    -- Get the provider's code
    SELECT sp.provider_code INTO provider_code
    FROM public.service_providers sp
    WHERE sp.id = provider_id;
    
    -- Get the current branch count for this provider
    SELECT COUNT(*) INTO branch_count
    FROM public.branches b
    WHERE b.provider_id = provider_id;
    
    -- Generate branch code in format: JEENA-YYYY-XXXX-BR-01
    RETURN provider_code || '-BR-' || LPAD((branch_count + 1)::TEXT, 2, '0');
END;
$$ LANGUAGE plpgsql;

-- Function to generate invoice numbers
CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS TEXT AS $$
BEGIN
    RETURN 'INV' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- Warehouse table for service validation
CREATE TABLE IF NOT EXISTS public.warehouse (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    service_name TEXT NOT NULL,
    service_type TEXT NOT NULL,
    internal_code TEXT UNIQUE,
    quantity INTEGER DEFAULT 0,
    approval_status TEXT DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    description TEXT,
    category TEXT,
    provider_category TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert sample official Jeena services catalog
INSERT INTO public.warehouse (service_name, service_type, internal_code, quantity, approval_status, description, category, provider_category) VALUES
-- Beauty and grooming services
('قص وتصفيف الشعر للرجال', 'grooming', 'JEENA-GR-001', 100, 'approved', 'خدمة قص وتصفيف الشعر للرجال بأحدث الأساليب', 'Beauty', 'grooming'),
('قص وتصفيف الشعر للنساء', 'grooming', 'JEENA-GR-002', 100, 'approved', 'خدمة قص وتصفيف الشعر للنساء بأحدث الأساليب', 'Beauty', 'grooming'),
('تسريحات الزفاف', 'grooming', 'JEENA-GR-003', 50, 'approved', 'تسريحات زفاف فاخرة ومميزة', 'Beauty', 'grooming'),
('ماكياج مناسبات', 'grooming', 'JEENA-GR-004', 80, 'approved', 'خدمة ماكياج احترافي للمناسبات', 'Beauty', 'grooming'),
('جلسات تدليك وراحة', 'grooming', 'JEENA-GR-005', 30, 'approved', 'جلسات تدليك واسترخاء للجسم', 'Beauty', 'grooming'),

-- Event services
('تنظيم حفلات الزفاف', 'events', 'JEENA-EV-001', 20, 'approved', 'تنظيم حفلات زفاف راقية ومميزة', 'Events', 'events'),
('تنظيم حفلات الأطفال', 'events', 'JEENA-EV-002', 50, 'approved', 'تنظيم حفلات أطفال مميزة وممتعة', 'Events', 'events'),
('تنظيم المؤتمرات والندوات', 'events', 'JEENA-EV-003', 15, 'approved', 'تنظيم مؤتمرات وندوات احترافية', 'Events', 'events'),
('التصوير الفوتوغرافي', 'events', 'JEENA-EV-004', 100, 'approved', 'خدمات تصوير فوتوغرافي احترافي', 'Events', 'events'),
('تصوير الفيديو', 'events', 'JEENA-EV-005', 80, 'approved', 'خدمات تصوير فيديو عالي الجودة', 'Events', 'events'),

-- Technology services
('تطوير المواقع الإلكترونية', 'technology', 'JEENA-TEC-001', 25, 'approved', 'تطوير مواقع إلكترونية احترافية', 'Technology', 'technology'),
('تطوير تطبيقات الجوال', 'technology', 'JEENA-TEC-002', 20, 'approved', 'تطوير تطبيقات جوال متطورة', 'Technology', 'technology'),
('صيانة الحاسب الآلي', 'technology', 'JEENA-TEC-003', 100, 'approved', 'صيانة وإصلاح أجهزة الحاسب الآلي', 'Technology', 'technology'),
('إعداد الشبكات', 'technology', 'JEENA-TEC-004', 50, 'approved', 'إعداد وصيانة شبكات الحاسب الآلي', 'Technology', 'technology'),
('التسويق الرقمي', 'technology', 'JEENA-TEC-005', 80, 'approved', 'خدمات تسويق رقمي شاملة', 'Technology', 'technology'),

-- Education services
('دروس خصوصية - رياضيات', 'education', 'JEENA-EDU-001', 200, 'approved', 'دروس خصوصية في مادة الرياضيات', 'Education', 'education'),
('دروس خصوصية - إنجليزي', 'education', 'JEENA-EDU-002', 200, 'approved', 'دروس خصوصية في اللغة الإنجليزية', 'Education', 'education'),
('دروس خصوصية - فيزياء', 'education', 'JEENA-EDU-003', 150, 'approved', 'دروس خصوصية في مادة الفيزياء', 'Education', 'education'),
('دروس تعليم قيادة السيارات', 'education', 'JEENA-EDU-004', 30, 'approved', 'تعليم قيادة السيارات للمبتدئين', 'Education', 'education'),
('دورات تدريبية في الحاسب الآلي', 'education', 'JEENA-EDU-005', 40, 'approved', 'دورات تدريبية شاملة في الحاسب الآلي', 'Education', 'education'),

-- Health services
('استشارات طبية عامة', 'health', 'JEENA-HEA-001', 50, 'approved', 'استشارات طبية عامة مع أطباء مختصين', 'Health', 'health'),
('جلسات العلاج الطبيعي', 'health', 'JEENA-HEA-002', 100, 'approved', 'جلسات علاج طبيعي متخصصة', 'Health', 'health'),
('فحوصات طبية منزلية', 'health', 'JEENA-HEA-003', 30, 'approved', 'فحوصات طبية شاملة في المنزل', 'Health', 'health'),
('رعاية المسنين', 'health', 'JEENA-HEA-004', 20, 'approved', 'خدمات رعاية المسنين المتخصصة', 'Health', 'health'),
('تمارين رياضية منزلية', 'health', 'JEENA-HEA-005', 80, 'approved', 'تمارين رياضية مخصصة للمنزل', 'Health', 'health'),

-- Home services
('تنظيف المنازل', 'home_services', 'JEENA-HOME-001', 500, 'approved', 'خدمات تنظيف المنازل الشاملة', 'Home', 'home_services'),
('صيانة السباكة', 'home_services', 'JEENA-HOME-002', 100, 'approved', 'صيانة وإصلاح السباكة المنزلية', 'Home', 'home_services'),
('صيانة الكهرباء', 'home_services', 'JEENA-HOME-003', 80, 'approved', 'صيانة وإصلاح الكهرباء المنزلية', 'Home', 'home_services'),
('صيانة التكييف', 'home_services', 'JEENA-HOME-004', 120, 'approved', 'صيانة وإصلاح أجهزة التكييف', 'Home', 'home_services'),
('نقل الأثاث', 'home_services', 'JEENA-HOME-005', 25, 'approved', 'خدمات نقل الأثاث الآمنة', 'Home', 'home_services'),

-- Business services
('استشارات قانونية', 'business', 'JEENA-BUS-001', 30, 'approved', 'استشارات قانونية متخصصة', 'Business', 'business'),
('استشارات محاسبية', 'business', 'JEENA-BUS-002', 50, 'approved', 'استشارات محاسبية ومالية', 'Business', 'business'),
('خدمات الترجمة', 'business', 'JEENA-BUS-003', 100, 'approved', 'خدمات ترجمة احترافية', 'Business', 'business'),
('إعداد خطط العمل', 'business', 'JEENA-BUS-004', 20, 'approved', 'إعداد خطط عمل مهنية', 'Business', 'business'),
('خدمات التوظيف', 'business', 'JEENA-BUS-005', 40, 'approved', 'خدمات توظيف متخصصة', 'Business', 'business'),

-- Transportation services
('توصيل الطلبات', 'transportation', 'JEENA-TRA-001', 200, 'approved', 'خدمات توصيل الطلبات السريعة', 'Transportation', 'transportation'),
('نقل الركاب', 'transportation', 'JEENA-TRA-002', 150, 'approved', 'خدمات نقل الركاب الآمنة', 'Transportation', 'transportation'),
('تأجير السيارات', 'transportation', 'JEENA-TRA-003', 50, 'approved', 'تأجير سيارات بأسعار مناسبة', 'Transportation', 'transportation'),
('خدمات الشحن', 'transportation', 'JEENA-TRA-004', 80, 'approved', 'خدمات شحن البضائع', 'Transportation', 'transportation'),
('توصيل الوقود', 'transportation', 'JEENA-TRA-005', 30, 'approved', 'توصيل الوقود للمركبات', 'Transportation', 'transportation'),

-- Food services
('إعداد الوجبات المنزلية', 'food', 'JEENA-FOOD-001', 300, 'approved', 'إعداد وجبات منزلية شهية', 'Food', 'food'),
('خدمات الطبخ للمناسبات', 'food', 'JEENA-FOOD-002', 50, 'approved', 'طبخ مناسبات وحفلات', 'Food', 'food'),
('توصيل الوجبات الجاهزة', 'food', 'JEENA-FOOD-003', 500, 'approved', 'توصيل وجبات جاهزة عالية الجودة', 'Food', 'food'),
('خدمات المطابخ الجاهزة', 'food', 'JEENA-FOOD-004', 20, 'approved', 'مطابخ جاهزة للمناسبات', 'Food', 'food'),
('استشارات غذائية', 'food', 'JEENA-FOOD-005', 40, 'approved', 'استشارات غذائية متخصصة', 'Food', 'food')
ON CONFLICT (internal_code) DO NOTHING;

-- Service providers table
CREATE TABLE IF NOT EXISTS public.service_providers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    commercial_name TEXT NOT NULL,
    registered_name TEXT NOT NULL,
    authorized_person_name TEXT NOT NULL,
    id_number TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT NOT NULL,
    city TEXT NOT NULL,
    street_address TEXT NOT NULL,
    service_type TEXT NOT NULL,
    description TEXT NOT NULL,
    logo_url TEXT,
    provider_code TEXT UNIQUE,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    branches JSONB,
    tax_number TEXT,
    bank_account TEXT,
    iban TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Pending profile changes table for approval workflow
CREATE TABLE IF NOT EXISTS public.pending_profile_changes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    provider_id UUID REFERENCES public.service_providers(id) ON DELETE CASCADE NOT NULL,
    field_name TEXT NOT NULL,
    old_value TEXT,
    new_value TEXT,
    change_type TEXT DEFAULT 'update' CHECK (change_type IN ('update', 'delete')),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    admin_notes TEXT,
    requested_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    admin_reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_services_user_id ON public.services(user_id);
CREATE INDEX IF NOT EXISTS idx_services_branch_id ON public.services(branch_id);
CREATE INDEX IF NOT EXISTS idx_orders_provider_id ON public.orders(provider_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_invoices_provider_id ON public.invoices(provider_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON public.invoices(status);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_reviews_provider_id ON public.reviews(provider_id);
CREATE INDEX IF NOT EXISTS idx_inventory_user_id ON public.inventory(user_id);
CREATE INDEX IF NOT EXISTS idx_service_providers_user_id ON public.service_providers(user_id);
CREATE INDEX IF NOT EXISTS idx_service_providers_status ON public.service_providers(status);
CREATE INDEX IF NOT EXISTS idx_branches_provider_id ON public.branches(provider_id);
CREATE INDEX IF NOT EXISTS idx_branches_is_active ON public.branches(is_active);
CREATE INDEX IF NOT EXISTS idx_branches_is_archived ON public.branches(is_archived);
CREATE INDEX IF NOT EXISTS idx_verification_codes_email ON public.verification_codes(email);
CREATE INDEX IF NOT EXISTS idx_verification_codes_code ON public.verification_codes(code);
CREATE INDEX IF NOT EXISTS idx_verification_codes_entity_id ON public.verification_codes(entity_id);
CREATE INDEX IF NOT EXISTS idx_pending_profile_changes_provider_id ON public.pending_profile_changes(provider_id);
CREATE INDEX IF NOT EXISTS idx_pending_profile_changes_status ON public.pending_profile_changes(status);