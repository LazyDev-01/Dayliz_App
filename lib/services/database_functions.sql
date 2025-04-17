-- Function to create subcategories table if it doesn't exist
CREATE OR REPLACE FUNCTION create_subcategories_table() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Check if subcategories table already exists
    IF NOT EXISTS (
        SELECT FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename = 'subcategories'
    ) THEN
        -- Create subcategories table
        CREATE TABLE public.subcategories (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            name TEXT NOT NULL,
            category_id UUID REFERENCES public.categories(id) ON DELETE CASCADE,
            image_url TEXT,
            icon_name TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            is_active BOOLEAN DEFAULT true,
            display_order INTEGER DEFAULT 0
        );

        -- Create trigger for updated_at timestamp
        CREATE TRIGGER update_subcategories_modtime
        BEFORE UPDATE ON public.subcategories
        FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

        -- Enable RLS
        ALTER TABLE public.subcategories ENABLE ROW LEVEL SECURITY;

        -- Add read policy for all
        CREATE POLICY subcategories_read_all ON public.subcategories 
            FOR SELECT USING (true);
        
        -- Add CRUD policy for admins
        CREATE POLICY subcategories_admin_crud ON public.subcategories 
            FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
    END IF;
END;
$$;

-- Function to add icon_name column to categories table if it doesn't exist
CREATE OR REPLACE FUNCTION add_icon_name_to_categories() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Check if icon_name column exists in categories table
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'categories'
        AND column_name = 'icon_name'
    ) THEN
        -- Add icon_name column
        ALTER TABLE public.categories
        ADD COLUMN icon_name TEXT;
        
        RAISE NOTICE 'Added icon_name column to categories table';
    ELSE
        RAISE NOTICE 'icon_name column already exists in categories table';
    END IF;
END;
$$;

-- Function to seed initial categories and subcategories data
CREATE OR REPLACE FUNCTION seed_categories_data() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    grocery_id UUID;
    snacks_id UUID;
    beauty_id UUID;
    household_id UUID;
BEGIN
    -- Insert main categories
    INSERT INTO public.categories (name, icon_name, theme_color, display_order)
    VALUES 
        ('Grocery & Kitchen', 'kitchen', '#4CAF50', 1)
    RETURNING id INTO grocery_id;
    
    INSERT INTO public.categories (name, icon_name, theme_color, display_order)
    VALUES 
        ('Snacks & Beverages', 'fastfood', '#FFC107', 2)
    RETURNING id INTO snacks_id;
    
    INSERT INTO public.categories (name, icon_name, theme_color, display_order)
    VALUES 
        ('Beauty & Hygiene', 'spa', '#E91E63', 3)
    RETURNING id INTO beauty_id;
    
    INSERT INTO public.categories (name, icon_name, theme_color, display_order)
    VALUES 
        ('Household & Essentials', 'home', '#9C27B0', 4)
    RETURNING id INTO household_id;
    
    -- Insert subcategories for Grocery & Kitchen
    INSERT INTO public.subcategories (name, category_id, image_url, display_order)
    VALUES 
        ('Dairy, Bread & Eggs', grocery_id, 'https://placehold.co/400x300/4CAF50/FFFFFF?text=Dairy', 1),
        ('Atta, Rice & Dal', grocery_id, 'https://placehold.co/400x300/4CAF50/FFFFFF?text=Rice', 2),
        ('Oil, Ghee & Masala', grocery_id, 'https://placehold.co/400x300/4CAF50/FFFFFF?text=Oil', 3),
        ('Vegetables & Fruits', grocery_id, 'https://placehold.co/400x300/4CAF50/FFFFFF?text=Veggies', 4);
    
    -- Insert subcategories for Snacks & Beverages
    INSERT INTO public.subcategories (name, category_id, image_url, display_order)
    VALUES 
        ('Cookies & Biscuits', snacks_id, 'https://placehold.co/400x300/FFC107/FFFFFF?text=Cookies', 1),
        ('Snacks & Chips', snacks_id, 'https://placehold.co/400x300/FFC107/FFFFFF?text=Snacks', 2),
        ('Cold Drinks & Juices', snacks_id, 'https://placehold.co/400x300/FFC107/FFFFFF?text=Drinks', 3);
    
    -- Insert subcategories for Beauty & Hygiene
    INSERT INTO public.subcategories (name, category_id, image_url, display_order)
    VALUES 
        ('Bath & Body', beauty_id, 'https://placehold.co/400x300/E91E63/FFFFFF?text=Bath', 1),
        ('Skin & Face Care', beauty_id, 'https://placehold.co/400x300/E91E63/FFFFFF?text=Skin', 2),
        ('Hair Care', beauty_id, 'https://placehold.co/400x300/E91E63/FFFFFF?text=Hair', 3);
    
    -- Insert subcategories for Household & Essentials
    INSERT INTO public.subcategories (name, category_id, image_url, display_order)
    VALUES 
        ('Cleaning Supplies', household_id, 'https://placehold.co/400x300/9C27B0/FFFFFF?text=Clean', 1),
        ('Detergent & Fabric Care', household_id, 'https://placehold.co/400x300/9C27B0/FFFFFF?text=Detergent', 2),
        ('Kitchen Accessories', household_id, 'https://placehold.co/400x300/9C27B0/FFFFFF?text=Kitchen', 3);
    
    RAISE NOTICE 'Successfully seeded categories and subcategories data';
END;
$$;

-- Function to add additional subcategories
CREATE OR REPLACE FUNCTION add_missing_subcategories() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    grocery_id UUID;
    snacks_id UUID;
    beauty_id UUID;
    household_id UUID;
BEGIN
    -- Get category IDs
    SELECT id INTO grocery_id FROM public.categories WHERE name = 'Grocery & Kitchen' LIMIT 1;
    SELECT id INTO snacks_id FROM public.categories WHERE name = 'Snacks & Beverages' LIMIT 1;
    SELECT id INTO beauty_id FROM public.categories WHERE name = 'Beauty & Hygiene' LIMIT 1;
    SELECT id INTO household_id FROM public.categories WHERE name = 'Household & Essentials' LIMIT 1;
    
    -- Add missing subcategories for Grocery & Kitchen
    INSERT INTO public.subcategories (name, category_id, image_url, display_order)
    VALUES 
        ('Frozen Food', grocery_id, 'https://placehold.co/400x300/4CAF50/FFFFFF?text=Frozen', 5),
        ('Sauces & Spreads', grocery_id, 'https://placehold.co/400x300/4CAF50/FFFFFF?text=Sauces', 6);
    
    -- Add missing subcategories for Snacks & Beverages
    INSERT INTO public.subcategories (name, category_id, image_url, display_order)
    VALUES 
        ('Tea & Coffee', snacks_id, 'https://placehold.co/400x300/FFC107/FFFFFF?text=Tea', 4),
        ('Ice Creams & more', snacks_id, 'https://placehold.co/400x300/FFC107/FFFFFF?text=IceCream', 5),
        ('Chocolates & Sweets', snacks_id, 'https://placehold.co/400x300/FFC107/FFFFFF?text=Chocolate', 6);
    
    -- Add missing subcategories for Beauty & Hygiene
    INSERT INTO public.subcategories (name, category_id, image_url, display_order)
    VALUES 
        ('Grooming & Fragrances', beauty_id, 'https://placehold.co/400x300/E91E63/FFFFFF?text=Groom', 4),
        ('Baby Care', beauty_id, 'https://placehold.co/400x300/E91E63/FFFFFF?text=Baby', 5),
        ('Beauty & Cosmetics', beauty_id, 'https://placehold.co/400x300/E91E63/FFFFFF?text=Beauty', 6);
    
    -- Add missing subcategories for Household & Essentials
    INSERT INTO public.subcategories (name, category_id, image_url, display_order)
    VALUES 
        ('Pet Care', household_id, 'https://placehold.co/400x300/9C27B0/FFFFFF?text=Pet', 4);
    
    RAISE NOTICE 'Successfully added missing subcategories';
END;
$$; 