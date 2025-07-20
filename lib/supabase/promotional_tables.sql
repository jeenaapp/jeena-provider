-- Service Offers table
CREATE TABLE IF NOT EXISTS public.service_offers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    provider_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    service_id UUID REFERENCES public.services(id) ON DELETE CASCADE NOT NULL,
    discount_percentage INTEGER CHECK (discount_percentage >= 1 AND discount_percentage <= 99),
    discounted_price DECIMAL(10,2) NOT NULL,
    original_price DECIMAL(10,2) NOT NULL,
    offer_start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    offer_end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'expired')),
    admin_notes TEXT,
    admin_reviewed_by UUID REFERENCES public.users(id),
    admin_reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Paid Promotion Requests table
CREATE TABLE IF NOT EXISTS public.paid_promotion_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    provider_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    service_id UUID REFERENCES public.services(id) ON DELETE CASCADE NOT NULL,
    promotion_type TEXT DEFAULT 'header_banner' CHECK (promotion_type IN ('header_banner', 'featured_section')),
    requested_duration_days INTEGER NOT NULL CHECK (requested_duration_days >= 1 AND requested_duration_days <= 365),
    requested_start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    requested_end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    promotion_cost DECIMAL(10,2) NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'active', 'expired')),
    admin_notes TEXT,
    admin_reviewed_by UUID REFERENCES public.users(id),
    admin_reviewed_at TIMESTAMP WITH TIME ZONE,
    approved_start_date TIMESTAMP WITH TIME ZONE,
    approved_end_date TIMESTAMP WITH TIME ZONE,
    approved_position INTEGER, -- For featured section ordering
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Active Promotions table (for easier querying of currently active promotions)
CREATE TABLE IF NOT EXISTS public.active_promotions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    promotion_request_id UUID REFERENCES public.paid_promotion_requests(id) ON DELETE CASCADE NOT NULL,
    provider_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    service_id UUID REFERENCES public.services(id) ON DELETE CASCADE NOT NULL,
    promotion_type TEXT NOT NULL,
    position INTEGER, -- For featured section ordering
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Promotion Audit Log table
CREATE TABLE IF NOT EXISTS public.promotion_audit_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    promotion_id UUID NOT NULL, -- Can reference either offers or paid_promotion_requests
    promotion_type TEXT NOT NULL CHECK (promotion_type IN ('offer', 'paid_promotion')),
    action TEXT NOT NULL CHECK (action IN ('created', 'approved', 'rejected', 'expired', 'activated', 'deactivated')),
    admin_id UUID REFERENCES public.users(id),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Promotion Analytics table
CREATE TABLE IF NOT EXISTS public.promotion_analytics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    promotion_id UUID NOT NULL,
    promotion_type TEXT NOT NULL CHECK (promotion_type IN ('offer', 'paid_promotion')),
    service_id UUID REFERENCES public.services(id) ON DELETE CASCADE NOT NULL,
    provider_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    views_count INTEGER DEFAULT 0,
    clicks_count INTEGER DEFAULT 0,
    conversion_count INTEGER DEFAULT 0,
    date_recorded DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_service_offers_provider_id ON public.service_offers(provider_id);
CREATE INDEX IF NOT EXISTS idx_service_offers_service_id ON public.service_offers(service_id);
CREATE INDEX IF NOT EXISTS idx_service_offers_status ON public.service_offers(status);
CREATE INDEX IF NOT EXISTS idx_service_offers_dates ON public.service_offers(offer_start_date, offer_end_date);

CREATE INDEX IF NOT EXISTS idx_paid_promotion_requests_provider_id ON public.paid_promotion_requests(provider_id);
CREATE INDEX IF NOT EXISTS idx_paid_promotion_requests_service_id ON public.paid_promotion_requests(service_id);
CREATE INDEX IF NOT EXISTS idx_paid_promotion_requests_status ON public.paid_promotion_requests(status);
CREATE INDEX IF NOT EXISTS idx_paid_promotion_requests_type ON public.paid_promotion_requests(promotion_type);

CREATE INDEX IF NOT EXISTS idx_active_promotions_provider_id ON public.active_promotions(provider_id);
CREATE INDEX IF NOT EXISTS idx_active_promotions_service_id ON public.active_promotions(service_id);
CREATE INDEX IF NOT EXISTS idx_active_promotions_type ON public.active_promotions(promotion_type);
CREATE INDEX IF NOT EXISTS idx_active_promotions_dates ON public.active_promotions(start_date, end_date);

CREATE INDEX IF NOT EXISTS idx_promotion_audit_log_promotion_id ON public.promotion_audit_log(promotion_id);
CREATE INDEX IF NOT EXISTS idx_promotion_audit_log_type ON public.promotion_audit_log(promotion_type);

CREATE INDEX IF NOT EXISTS idx_promotion_analytics_promotion_id ON public.promotion_analytics(promotion_id);
CREATE INDEX IF NOT EXISTS idx_promotion_analytics_service_id ON public.promotion_analytics(service_id);
CREATE INDEX IF NOT EXISTS idx_promotion_analytics_provider_id ON public.promotion_analytics(provider_id);
CREATE INDEX IF NOT EXISTS idx_promotion_analytics_date ON public.promotion_analytics(date_recorded);

-- Function to calculate promotion costs
CREATE OR REPLACE FUNCTION calculate_promotion_cost(
    promotion_type TEXT,
    duration_days INTEGER,
    position INTEGER DEFAULT NULL
) RETURNS DECIMAL(10,2) AS $$
BEGIN
    CASE promotion_type
        WHEN 'header_banner' THEN
            RETURN duration_days * 50.0; -- 50 SAR per day for header banner
        WHEN 'featured_section' THEN
            -- Featured section cost depends on position
            IF position <= 3 THEN
                RETURN duration_days * 30.0; -- 30 SAR per day for top 3 positions
            ELSE
                RETURN duration_days * 20.0; -- 20 SAR per day for other positions
            END IF;
        ELSE
            RETURN 0.0;
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- Function to activate approved promotions
CREATE OR REPLACE FUNCTION activate_approved_promotions() RETURNS VOID AS $$
BEGIN
    -- Insert approved promotions that should be active now
    INSERT INTO public.active_promotions (
        promotion_request_id, 
        provider_id, 
        service_id, 
        promotion_type, 
        position, 
        start_date, 
        end_date
    )
    SELECT 
        id,
        provider_id,
        service_id,
        promotion_type,
        approved_position,
        approved_start_date,
        approved_end_date
    FROM public.paid_promotion_requests
    WHERE status = 'approved'
    AND approved_start_date <= NOW()
    AND approved_end_date >= NOW()
    AND id NOT IN (SELECT promotion_request_id FROM public.active_promotions);
    
    -- Update status to active
    UPDATE public.paid_promotion_requests
    SET status = 'active'
    WHERE status = 'approved'
    AND approved_start_date <= NOW()
    AND approved_end_date >= NOW();
END;
$$ LANGUAGE plpgsql;

-- Function to deactivate expired promotions
CREATE OR REPLACE FUNCTION deactivate_expired_promotions() RETURNS VOID AS $$
BEGIN
    -- Remove expired promotions from active_promotions
    DELETE FROM public.active_promotions
    WHERE end_date < NOW();
    
    -- Update promotion requests status to expired
    UPDATE public.paid_promotion_requests
    SET status = 'expired'
    WHERE status = 'active'
    AND approved_end_date < NOW();
    
    -- Update service offers status to expired
    UPDATE public.service_offers
    SET status = 'expired'
    WHERE status = 'approved'
    AND offer_end_date < NOW();
END;
$$ LANGUAGE plpgsql;

-- Function to log promotion actions
CREATE OR REPLACE FUNCTION log_promotion_action(
    p_promotion_id UUID,
    p_promotion_type TEXT,
    p_action TEXT,
    p_admin_id UUID DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    INSERT INTO public.promotion_audit_log (
        promotion_id,
        promotion_type,
        action,
        admin_id,
        notes
    ) VALUES (
        p_promotion_id,
        p_promotion_type,
        p_action,
        p_admin_id,
        p_notes
    );
END;
$$ LANGUAGE plpgsql;

-- Trigger to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to tables
CREATE TRIGGER update_service_offers_updated_at
    BEFORE UPDATE ON public.service_offers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_paid_promotion_requests_updated_at
    BEFORE UPDATE ON public.paid_promotion_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();