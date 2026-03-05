-- ============================================================
-- ATLAS — Complete Phase 1 Schema (Bulletproof Edition)
-- ============================================================
-- ✅ SAFE TO RE-RUN. Never drops tables. Never loses data.
-- Uses IF NOT EXISTS for tables + ALTER ADD COLUMN for new fields.
-- Run this FIRST, then crowdtag-schema.sql, then seed-demo-data.sql
-- ============================================================


-- ═══════════════════════════════════════════════════════════
-- UTILITY FUNCTION: auto-update updated_at
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


-- ═══════════════════════════════════════════════════════════
-- TABLE 1: profiles
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS profiles (
  id               UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name        TEXT NOT NULL,
  email            TEXT NOT NULL,
  avatar_url       TEXT,
  role             TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  theme_preference TEXT NOT NULL DEFAULT 'dark' CHECK (theme_preference IN ('dark', 'light', 'system')),
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add columns that may be missing from older schema
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS currency TEXT NOT NULL DEFAULT 'INR';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS timezone TEXT NOT NULL DEFAULT 'Asia/Kolkata';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_sign_in_at TIMESTAMPTZ;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS theme_preference TEXT NOT NULL DEFAULT 'dark';

-- Make email unique if not already
DO $$ BEGIN
  ALTER TABLE profiles ADD CONSTRAINT profiles_email_unique UNIQUE (email);
EXCEPTION WHEN duplicate_table THEN NULL;
          WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role  ON profiles(role);

DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  CREATE POLICY "Users can read own profile"
    ON profiles FOR SELECT USING (auth.uid() = id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE USING (auth.uid() = id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can insert own profile"
    ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Admins can read all profiles"
    ON profiles FOR SELECT
    USING (EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Admins can update all profiles"
    ON profiles FOR UPDATE
    USING (EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;


-- ═══════════════════════════════════════════════════════════
-- TABLE 2: receipts
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS receipts (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  merchant_name       TEXT,
  receipt_date        DATE,
  total_amount        DECIMAL(12,2) NOT NULL DEFAULT 0,
  currency            TEXT NOT NULL DEFAULT 'INR',
  overall_confidence  DECIMAL(5,4),
  raw_text            TEXT,
  notes               TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add all advanced columns that may be missing
ALTER TABLE receipts ADD COLUMN IF NOT EXISTS merchant_city TEXT;
ALTER TABLE receipts ADD COLUMN IF NOT EXISTS subtotal DECIMAL(12,2);
ALTER TABLE receipts ADD COLUMN IF NOT EXISTS tax_amount DECIMAL(12,2);
ALTER TABLE receipts ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(12,2);
ALTER TABLE receipts ADD COLUMN IF NOT EXISTS model_used TEXT;
ALTER TABLE receipts ADD COLUMN IF NOT EXISTS gemini_confidence DECIMAL(5,4);
ALTER TABLE receipts ADD COLUMN IF NOT EXISTS ml_confidence DECIMAL(5,4);
ALTER TABLE receipts ADD COLUMN IF NOT EXISTS ml_server_available BOOLEAN DEFAULT FALSE;
ALTER TABLE receipts ADD COLUMN IF NOT EXISTS confidence_tier TEXT;
ALTER TABLE receipts ADD COLUMN IF NOT EXISTS processing_time_ms INTEGER;
ALTER TABLE receipts ADD COLUMN IF NOT EXISTS crowdtag_resolved BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE receipts ADD COLUMN IF NOT EXISTS is_torn_receipt BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE receipts ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_receipts_user_id   ON receipts(user_id);
CREATE INDEX IF NOT EXISTS idx_receipts_date      ON receipts(receipt_date DESC);
CREATE INDEX IF NOT EXISTS idx_receipts_merchant  ON receipts(merchant_name);
CREATE INDEX IF NOT EXISTS idx_receipts_created   ON receipts(created_at DESC);

DO $$ BEGIN
  CREATE INDEX idx_receipts_deleted ON receipts(deleted_at) WHERE deleted_at IS NULL;
EXCEPTION WHEN duplicate_table THEN NULL;
          WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE INDEX idx_receipts_user_date ON receipts(user_id, receipt_date DESC) WHERE deleted_at IS NULL;
EXCEPTION WHEN duplicate_table THEN NULL;
          WHEN duplicate_object THEN NULL;
END $$;

DROP TRIGGER IF EXISTS update_receipts_updated_at ON receipts;
CREATE TRIGGER update_receipts_updated_at
  BEFORE UPDATE ON receipts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  CREATE POLICY "Users can read own receipts"
    ON receipts FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can insert own receipts"
    ON receipts FOR INSERT WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can update own receipts"
    ON receipts FOR UPDATE USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can delete own receipts"
    ON receipts FOR DELETE USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Admins can read all receipts"
    ON receipts FOR SELECT
    USING (EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;


-- ═══════════════════════════════════════════════════════════
-- TABLE 3: line_items
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS line_items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  receipt_id  UUID NOT NULL REFERENCES receipts(id) ON DELETE CASCADE,
  item_name   TEXT NOT NULL,
  amount      DECIMAL(12,2),
  category    TEXT NOT NULL DEFAULT 'Other',
  confidence  DECIMAL(5,4),
  manually_corrected BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add advanced columns that may be missing
ALTER TABLE line_items ADD COLUMN IF NOT EXISTS user_id UUID;
ALTER TABLE line_items ADD COLUMN IF NOT EXISTS quantity DECIMAL(8,3) NOT NULL DEFAULT 1;
ALTER TABLE line_items ADD COLUMN IF NOT EXISTS unit_price DECIMAL(12,2) NOT NULL DEFAULT 0;
ALTER TABLE line_items ADD COLUMN IF NOT EXISTS total_price DECIMAL(12,2) NOT NULL DEFAULT 0;
ALTER TABLE line_items ADD COLUMN IF NOT EXISTS confidence_tier TEXT;
ALTER TABLE line_items ADD COLUMN IF NOT EXISTS original_category TEXT;
ALTER TABLE line_items ADD COLUMN IF NOT EXISTS corrected_at TIMESTAMPTZ;

-- Make old 'amount' column nullable (replaced by total_price)
DO $$ BEGIN
  ALTER TABLE line_items ALTER COLUMN amount DROP NOT NULL;
EXCEPTION WHEN undefined_column THEN NULL;
END $$;

-- Add FK for user_id if not already there
DO $$ BEGIN
  ALTER TABLE line_items
    ADD CONSTRAINT line_items_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_line_items_receipt  ON line_items(receipt_id);
CREATE INDEX IF NOT EXISTS idx_line_items_category ON line_items(category);

DO $$ BEGIN
  CREATE INDEX idx_line_items_user ON line_items(user_id);
EXCEPTION WHEN duplicate_table THEN NULL;
          WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE INDEX idx_line_items_user_cat ON line_items(user_id, category);
EXCEPTION WHEN duplicate_table THEN NULL;
          WHEN duplicate_object THEN NULL;
END $$;

DROP TRIGGER IF EXISTS update_line_items_updated_at ON line_items;
CREATE TRIGGER update_line_items_updated_at
  BEFORE UPDATE ON line_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE line_items ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  CREATE POLICY "Users can read own line items"
    ON line_items FOR SELECT
    USING (auth.uid() = (SELECT user_id FROM receipts WHERE id = receipt_id));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can insert own line items"
    ON line_items FOR INSERT
    WITH CHECK (auth.uid() = (SELECT user_id FROM receipts WHERE id = receipt_id));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can update own line items"
    ON line_items FOR UPDATE
    USING (auth.uid() = (SELECT user_id FROM receipts WHERE id = receipt_id));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can delete own line items"
    ON line_items FOR DELETE
    USING (auth.uid() = (SELECT user_id FROM receipts WHERE id = receipt_id));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Admins can read all line items"
    ON line_items FOR SELECT
    USING (EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;


-- ═══════════════════════════════════════════════════════════
-- TABLE 4: categories
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS categories (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT UNIQUE NOT NULL,
  icon        TEXT NOT NULL,
  color       TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE categories ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS sort_order INTEGER NOT NULL DEFAULT 0;

INSERT INTO categories (name, icon, color, description, sort_order) VALUES
  ('Food & Dining',      'utensils',      '#f97316', 'Restaurants, cafes, bars',                     1),
  ('Groceries',          'shopping-cart', '#22c55e', 'Supermarkets, grocery stores, fresh produce',  2),
  ('Health & Medicine',  'heart-pulse',   '#ef4444', 'Pharmacy, hospitals, medicine, doctors',       3),
  ('Personal Care',      'sparkles',      '#a855f7', 'Salon, beauty, skincare, hygiene',             4),
  ('Home & Household',   'home',          '#3b82f6', 'Cleaning, furniture, appliances, utilities',   5),
  ('Electronics',        'cpu',           '#06b6d4', 'Gadgets, devices, accessories, cables',        6),
  ('Clothing & Fashion', 'shirt',         '#ec4899', 'Clothes, shoes, bags, accessories',            7),
  ('Transport',          'car',           '#eab308', 'Fuel, taxi, auto, metro, parking',             8),
  ('Entertainment',      'film',          '#8b5cf6', 'Movies, events, games, streaming',             9),
  ('Education',          'book-open',     '#14b8a6', 'Books, courses, school supplies, tuition',    10),
  ('Takeout & Delivery', 'package',       '#f59e0b', 'Food delivery, Swiggy, Zomato, online orders',11),
  ('Other',              'circle-dot',    '#6b7280', 'Anything that does not fit above',            12)
ON CONFLICT (name) DO UPDATE SET
  description = EXCLUDED.description,
  sort_order  = EXCLUDED.sort_order;

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  CREATE POLICY "Anyone can read categories"
    ON categories FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;


-- ═══════════════════════════════════════════════════════════
-- TABLE 5: merchant_fingerprints
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS merchant_fingerprints (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_key           TEXT UNIQUE NOT NULL,
  category_votes         JSONB NOT NULL DEFAULT '{}',
  dominant_category      TEXT,
  confidence_score       DECIMAL(5,4) NOT NULL DEFAULT 0,
  total_votes            INTEGER NOT NULL DEFAULT 0,
  is_resolved            BOOLEAN NOT NULL DEFAULT FALSE,
  seeded_from_places_api BOOLEAN NOT NULL DEFAULT FALSE,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add Phase 2 columns
ALTER TABLE merchant_fingerprints ADD COLUMN IF NOT EXISTS display_name TEXT NOT NULL DEFAULT '';
ALTER TABLE merchant_fingerprints ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE merchant_fingerprints ADD COLUMN IF NOT EXISTS country TEXT NOT NULL DEFAULT 'IN';
ALTER TABLE merchant_fingerprints ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMPTZ;
ALTER TABLE merchant_fingerprints ADD COLUMN IF NOT EXISTS recent_votes JSONB NOT NULL DEFAULT '[]';
ALTER TABLE merchant_fingerprints ADD COLUMN IF NOT EXISTS drift_detected BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE merchant_fingerprints ADD COLUMN IF NOT EXISTS drift_detected_at TIMESTAMPTZ;
ALTER TABLE merchant_fingerprints ADD COLUMN IF NOT EXISTS last_drift_check TIMESTAMPTZ;
ALTER TABLE merchant_fingerprints ADD COLUMN IF NOT EXISTS category_distribution JSONB NOT NULL DEFAULT '{}';
ALTER TABLE merchant_fingerprints ADD COLUMN IF NOT EXISTS is_multi_category BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE merchant_fingerprints ADD COLUMN IF NOT EXISTS places_place_id TEXT;
ALTER TABLE merchant_fingerprints ADD COLUMN IF NOT EXISTS places_api_types TEXT[];

CREATE INDEX IF NOT EXISTS idx_mf_key       ON merchant_fingerprints(merchant_key);
CREATE INDEX IF NOT EXISTS idx_mf_resolved  ON merchant_fingerprints(is_resolved);
CREATE INDEX IF NOT EXISTS idx_mf_category  ON merchant_fingerprints(dominant_category);

DO $$ BEGIN CREATE INDEX idx_mf_city  ON merchant_fingerprints(city);
EXCEPTION WHEN duplicate_table THEN NULL; WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE INDEX idx_mf_votes ON merchant_fingerprints(total_votes DESC);
EXCEPTION WHEN duplicate_table THEN NULL; WHEN duplicate_object THEN NULL; END $$;

DROP TRIGGER IF EXISTS update_mf_updated_at ON merchant_fingerprints;
CREATE TRIGGER update_mf_updated_at
  BEFORE UPDATE ON merchant_fingerprints
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE merchant_fingerprints ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  CREATE POLICY "Anyone can view merchants"
    ON merchant_fingerprints FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Auth users can insert merchants"
    ON merchant_fingerprints FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Auth users can update merchants"
    ON merchant_fingerprints FOR UPDATE USING (auth.uid() IS NOT NULL);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;


-- ═══════════════════════════════════════════════════════════
-- AUTO-CREATE PROFILE ON SIGNUP
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO profiles (id, full_name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),
    NEW.email
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();


-- ═══════════════════════════════════════════════════════════
-- RPC: insert_receipt_with_items (atomic)
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION insert_receipt_with_items(
  p_user_id    UUID,
  p_receipt    JSONB,
  p_line_items JSONB
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_receipt_id UUID;
BEGIN
  INSERT INTO receipts (
    user_id, merchant_name, merchant_city, receipt_date,
    total_amount, currency, subtotal, tax_amount, discount_amount,
    overall_confidence, model_used, gemini_confidence, ml_confidence,
    ml_server_available, confidence_tier, processing_time_ms,
    crowdtag_resolved, is_torn_receipt, raw_text
  )
  VALUES (
    p_user_id,
    NULLIF(TRIM(p_receipt->>'merchant_name'), ''),
    NULLIF(TRIM(p_receipt->>'merchant_city'), ''),
    CASE WHEN p_receipt->>'receipt_date' IS NOT NULL AND p_receipt->>'receipt_date' <> 'null'
         THEN (p_receipt->>'receipt_date')::DATE ELSE NULL END,
    COALESCE((p_receipt->>'total_amount')::DECIMAL, 0),
    COALESCE(NULLIF(p_receipt->>'currency', ''), 'INR'),
    (p_receipt->>'subtotal')::DECIMAL,
    (p_receipt->>'tax_amount')::DECIMAL,
    (p_receipt->>'discount_amount')::DECIMAL,
    (p_receipt->>'overall_confidence')::DECIMAL,
    NULLIF(p_receipt->>'model_used', ''),
    (p_receipt->>'gemini_confidence')::DECIMAL,
    (p_receipt->>'ml_confidence')::DECIMAL,
    COALESCE((p_receipt->>'ml_server_available')::BOOLEAN, FALSE),
    NULLIF(p_receipt->>'confidence_tier', ''),
    (p_receipt->>'processing_time_ms')::INTEGER,
    COALESCE((p_receipt->>'crowdtag_resolved')::BOOLEAN, FALSE),
    COALESCE((p_receipt->>'is_torn_receipt')::BOOLEAN, FALSE),
    NULLIF(p_receipt->>'raw_text', '')
  )
  RETURNING id INTO v_receipt_id;

  INSERT INTO line_items (
    receipt_id, user_id, item_name, quantity,
    unit_price, total_price, category, confidence, confidence_tier
  )
  SELECT
    v_receipt_id, p_user_id,
    COALESCE(NULLIF(TRIM(item->>'item_name'), ''), 'Unknown Item'),
    COALESCE((item->>'quantity')::DECIMAL, 1),
    COALESCE((item->>'unit_price')::DECIMAL, 0),
    COALESCE((item->>'total_price')::DECIMAL, 0),
    COALESCE(NULLIF(item->>'category', ''), 'Other'),
    (item->>'confidence')::DECIMAL,
    CASE
      WHEN (item->>'confidence')::DECIMAL >= 0.85 THEN 'high'
      WHEN (item->>'confidence')::DECIMAL >= 0.60 THEN 'medium'
      ELSE 'low'
    END
  FROM jsonb_array_elements(p_line_items) AS item;

  RETURN v_receipt_id;
END;
$$;


-- ═══════════════════════════════════════════════════════════
-- VIEW: platform_stats (admin dashboard)
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW platform_stats AS
SELECT
  (SELECT COUNT(*) FROM profiles)                                    AS total_users,
  (SELECT COUNT(*) FROM profiles
   WHERE created_at > NOW() - INTERVAL '24 hours')                   AS new_users_today,
  (SELECT COUNT(*) FROM receipts WHERE deleted_at IS NULL)           AS total_receipts,
  (SELECT COUNT(*) FROM receipts
   WHERE created_at > NOW() - INTERVAL '24 hours')                   AS receipts_today,
  (SELECT ROUND(AVG(overall_confidence)::NUMERIC, 4)
   FROM receipts WHERE overall_confidence IS NOT NULL)                AS avg_confidence;


-- ═══════════════════════════════════════════════════════════
-- STORAGE POLICIES (safe — handles duplicates)
-- ═══════════════════════════════════════════════════════════

DO $$ BEGIN
  DROP POLICY IF EXISTS "Users can upload own receipt images" ON storage.objects;
  DROP POLICY IF EXISTS "Users can read own receipt images" ON storage.objects;
  DROP POLICY IF EXISTS "Users can delete own receipt images" ON storage.objects;
  DROP POLICY IF EXISTS "Avatars are publicly readable" ON storage.objects;
  DROP POLICY IF EXISTS "Users can upload own avatar" ON storage.objects;
  DROP POLICY IF EXISTS "Users can update own avatar" ON storage.objects;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can upload own receipt images"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'receipt-temp' AND auth.uid()::text = (storage.foldername(name))[1]);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can read own receipt images"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'receipt-temp' AND auth.uid()::text = (storage.foldername(name))[1]);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can delete own receipt images"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'receipt-temp' AND auth.uid()::text = (storage.foldername(name))[1]);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Avatars are publicly readable"
    ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can upload own avatar"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can update own avatar"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;


-- ═══════════════════════════════════════════════════════════
-- ✅ DONE! Verify with:
-- ═══════════════════════════════════════════════════════════
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY 1;
-- SELECT COUNT(*) FROM categories;  -- should be 12
-- SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'public';
