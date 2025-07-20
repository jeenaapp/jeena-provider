-- Warehouse products table
CREATE TABLE IF NOT EXISTS public.warehouse_products (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    product_code TEXT,
    model TEXT,
    category TEXT,
    image_url TEXT,
    unit_price DECIMAL(10,2),
    current_stock INTEGER DEFAULT 0,
    min_stock_level INTEGER DEFAULT 0,
    approval_status TEXT DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    approved_by TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Warehouse reservations table for date-based availability
CREATE TABLE IF NOT EXISTS public.warehouse_reservations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    product_id UUID REFERENCES public.warehouse_products(id) ON DELETE CASCADE NOT NULL,
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    customer_name TEXT,
    reserved_quantity INTEGER NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT DEFAULT 'reserved' CHECK (status IN ('reserved', 'confirmed', 'completed', 'cancelled')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Function to generate product codes based on category
CREATE OR REPLACE FUNCTION generate_product_code(category TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN CASE 
        WHEN category = 'furniture' THEN 'FUR-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0')
        WHEN category = 'decoration' THEN 'DEC-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0')
        WHEN category = 'flowers' THEN 'FLW-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0')
        WHEN category = 'cakes' THEN 'CAK-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0')
        WHEN category = 'equipment' THEN 'EQP-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0')
        WHEN category = 'lighting' THEN 'LGT-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0')
        WHEN category = 'sound' THEN 'SND-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0')
        WHEN category = 'table_setup' THEN 'TBL-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0')
        ELSE 'PRD-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0')
    END;
END;
$$ LANGUAGE plpgsql;

-- Function to check product availability for a date range
CREATE OR REPLACE FUNCTION check_product_availability(
    product_id UUID,
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    required_quantity INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    total_stock INTEGER;
    reserved_quantity INTEGER;
    available_quantity INTEGER;
BEGIN
    -- Get current stock
    SELECT current_stock INTO total_stock
    FROM public.warehouse_products
    WHERE id = product_id;
    
    -- Get reserved quantity for the date range
    SELECT COALESCE(SUM(reserved_quantity), 0) INTO reserved_quantity
    FROM public.warehouse_reservations
    WHERE product_id = check_product_availability.product_id
      AND status IN ('reserved', 'confirmed')
      AND (
          (start_date <= check_product_availability.start_date AND end_date >= check_product_availability.start_date)
          OR
          (start_date <= check_product_availability.end_date AND end_date >= check_product_availability.end_date)
          OR
          (start_date >= check_product_availability.start_date AND end_date <= check_product_availability.end_date)
      );
    
    available_quantity := total_stock - reserved_quantity;
    
    RETURN available_quantity >= required_quantity;
END;
$$ LANGUAGE plpgsql;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_warehouse_products_user_id ON public.warehouse_products(user_id);
CREATE INDEX IF NOT EXISTS idx_warehouse_products_approval_status ON public.warehouse_products(approval_status);
CREATE INDEX IF NOT EXISTS idx_warehouse_reservations_product_id ON public.warehouse_reservations(product_id);
CREATE INDEX IF NOT EXISTS idx_warehouse_reservations_dates ON public.warehouse_reservations(start_date, end_date);