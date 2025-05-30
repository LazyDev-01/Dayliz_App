-- Create product attributes table
CREATE TABLE IF NOT EXISTS product_attributes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    value TEXT NOT NULL,
    price_adjustment NUMERIC(10, 2) DEFAULT 0.0,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(product_id, name, value)
);

-- Create product colors table
CREATE TABLE IF NOT EXISTS product_colors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    hex_code TEXT NOT NULL,
    is_available BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(product_id, name)
);

-- Create product sizes table
CREATE TABLE IF NOT EXISTS product_sizes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    value TEXT NOT NULL,
    price_adjustment NUMERIC(10, 2) DEFAULT 0.0,
    is_available BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(product_id, name, value)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_product_attributes_product_id ON product_attributes(product_id);
CREATE INDEX IF NOT EXISTS idx_product_colors_product_id ON product_colors(product_id);
CREATE INDEX IF NOT EXISTS idx_product_sizes_product_id ON product_sizes(product_id);

-- Add RLS policies for secure access
ALTER TABLE product_attributes ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_colors ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_sizes ENABLE ROW LEVEL SECURITY;

-- Create policies for product attributes
CREATE POLICY "Allow public read access to product_attributes" 
ON product_attributes FOR SELECT USING (true);

-- Create policies for product colors
CREATE POLICY "Allow public read access to product_colors" 
ON product_colors FOR SELECT USING (true);

-- Create policies for product sizes
CREATE POLICY "Allow public read access to product_sizes" 
ON product_sizes FOR SELECT USING (true);

-- Sample data for testing
INSERT INTO product_attributes (product_id, name, value, price_adjustment, is_default)
VALUES 
    ((SELECT id FROM products LIMIT 1), 'Material', 'Cotton', 0.0, true),
    ((SELECT id FROM products LIMIT 1), 'Material', 'Polyester', 5.0, false),
    ((SELECT id FROM products LIMIT 1), 'Style', 'Casual', 0.0, true),
    ((SELECT id FROM products LIMIT 1), 'Style', 'Formal', 10.0, false)
ON CONFLICT DO NOTHING;

INSERT INTO product_colors (product_id, name, hex_code, is_available, display_order)
VALUES 
    ((SELECT id FROM products LIMIT 1), 'Red', '#FF0000', true, 1),
    ((SELECT id FROM products LIMIT 1), 'Blue', '#0000FF', true, 2),
    ((SELECT id FROM products LIMIT 1), 'Green', '#00FF00', true, 3),
    ((SELECT id FROM products LIMIT 1), 'Black', '#000000', true, 4)
ON CONFLICT DO NOTHING;

INSERT INTO product_sizes (product_id, name, value, price_adjustment, is_available, display_order)
VALUES 
    ((SELECT id FROM products LIMIT 1), 'Size', 'S', 0.0, true, 1),
    ((SELECT id FROM products LIMIT 1), 'Size', 'M', 0.0, true, 2),
    ((SELECT id FROM products LIMIT 1), 'Size', 'L', 5.0, true, 3),
    ((SELECT id FROM products LIMIT 1), 'Size', 'XL', 10.0, true, 4)
ON CONFLICT DO NOTHING; 