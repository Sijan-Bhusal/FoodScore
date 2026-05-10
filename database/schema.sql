-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Products table
CREATE TABLE IF NOT EXISTS products (
    product_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    brand VARCHAR(100),
    category VARCHAR(50),
    barcode VARCHAR(50) UNIQUE NOT NULL,
    ingredients_raw TEXT,
    additives JSONB DEFAULT '[]'::jsonb,
    nutriments JSONB DEFAULT '{}'::jsonb,
    nova_group INTEGER CHECK (nova_group >= 1 AND nova_group <= 4),
    nutri_score CHAR(1) CHECK (nutri_score IN ('A', 'B', 'C', 'D', 'E')),
    health_score INTEGER DEFAULT NULL CHECK (health_score >= 0 AND health_score <= 100),
    is_harmful BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes separately
CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode);
CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);
CREATE INDEX IF NOT EXISTS idx_products_brand ON products(brand);
CREATE INDEX IF NOT EXISTS idx_products_health_score ON products(health_score);
CREATE INDEX IF NOT EXISTS idx_products_additives ON products USING GIN (additives);

-- Additive reference table
CREATE TABLE IF NOT EXISTS additive_reference (
    e_number VARCHAR(10) PRIMARY KEY,
    common_name VARCHAR(200),
    risk_tier VARCHAR(20) CHECK (risk_tier IN ('harmful', 'high', 'medium', 'low')),
    risk_description TEXT,
    is_banned BOOLEAN DEFAULT FALSE
);

-- Flagged ingredients table
CREATE TABLE IF NOT EXISTS flagged_ingredients (
    id SERIAL PRIMARY KEY,
    product_id UUID REFERENCES products(product_id) ON DELETE CASCADE,
    ingredient_name VARCHAR(200),
    e_number VARCHAR(10) REFERENCES additive_reference(e_number) ON DELETE SET NULL,
    risk_tier VARCHAR(20),
    penalty INTEGER
);

-- Suggestions table
CREATE TABLE IF NOT EXISTS suggestions (
    suggestion_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID REFERENCES products(product_id) ON DELETE CASCADE,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    flagged_items JSONB,
    suggestion_text TEXT,
    alternatives JSONB
);

-- Users table
CREATE TABLE IF NOT EXISTS users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(200) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Scan history table
CREATE TABLE IF NOT EXISTS scan_history (
    scan_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(product_id),
    barcode VARCHAR(50),
    scanned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    score_at_scan INTEGER,
    CHECK ((product_id IS NOT NULL AND barcode IS NULL) OR (product_id IS NULL AND barcode IS NOT NULL))
);

-- Auto-update timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_products_updated_at ON products;
CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Seed initial additive data
INSERT INTO additive_reference (e_number, common_name, risk_tier, is_banned) VALUES
('E102', 'Tartrazine', 'high', false),
('E104', 'Quinoline Yellow', 'high', false),
('E110', 'Sunset Yellow', 'high', false),
('E124', 'Ponceau 4R', 'high', false),
('E127', 'Erythrosine', 'medium', false),
('E129', 'Allura Red', 'high', false),
('E211', 'Sodium Benzoate', 'medium', false),
('E220', 'Sulfur Dioxide', 'high', false),
('E249', 'Potassium Nitrite', 'harmful', true),
('E250', 'Sodium Nitrite', 'harmful', true),
('E251', 'Sodium Nitrate', 'harmful', true),
('E252', 'Potassium Nitrate', 'harmful', true),
('E621', 'Monosodium Glutamate', 'medium', false),
('E950', 'Acesulfame K', 'medium', false),
('E951', 'Aspartame', 'medium', false),
('E952', 'Cyclamic Acid', 'medium', false),
('E954', 'Saccharin', 'medium', false),
('E955', 'Sucralose', 'low', false)
ON CONFLICT (e_number) DO NOTHING;