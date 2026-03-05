-- ============================================================
-- ATLAS — Phase 1 Complete Schema
-- Run this FIRST in Supabase SQL Editor before crowdtag-schema.sql
-- Fully idempotent — safe to re-run.
-- ============================================================

-- ═══════════════════════════════════════════════════════════
-- TABLE 1: profiles
-- One row per user, auto-created on auth.users insert
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS profiles (
  -- Identity
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name       TEXT NOT NULL,
  email           TEXT NOT NULL UNIQUE,
  avatar_url      TEXT,

  -- Role & Permissions
  role            TEXT NOT NULL DEFAULT 'user'
                  CHECK (role IN ('user', 'admin')),

  -- Preferences
  theme_preference TEXT NOT NULL DEFAULT 'dark'
                  CHECK (theme_preference IN ('dark', 'light', 'system')),
  currency        TEXT NOT NULL DEFAULT 'INR',
  timezone        TEXT NOT NULL DEFAULT 'Asia/Kolkata',

  -- Status
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,

  -- Metadata
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_sign_in_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role  ON profiles(role);

-- RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can read own profile' AND tablename = 'profiles') THEN
    CREATE POLICY "Users can read own profile"
      ON profiles FOR SELECT USING (auth.uid() = id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update own profile' AND tablename = 'profiles') THEN
    CREATE POLICY "Users can update own profile"
      ON profiles FOR UPDATE USING (auth.uid() = id)
      WITH CHECK (
        auth.uid() = id
        AND role = (SELECT role FROM profiles WHERE id = auth.uid())
      );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert own profile' AND tablename = 'profiles') THEN
    CREATE POLICY "Users can insert own profile"
      ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Admins can read all profiles' AND tablename = 'profiles') THEN
    CREATE POLICY "Admins can read all profiles"
      ON profiles FOR SELECT
      USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Admins can update all profiles' AND tablename = 'profiles') THEN
    CREATE POLICY "Admins can update all profiles"
      ON profiles FOR UPDATE
      USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');
  END IF;
END $$;


-- ═══════════════════════════════════════════════════════════
-- TABLE 2: receipts
-- One row per scanned receipt
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS receipts (
  -- Identity
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- Merchant Info
  merchant_name   TEXT,
  merchant_city   TEXT,
  receipt_date    DATE,

  -- Financial
  total_amount    DECIMAL(12,2) NOT NULL DEFAULT 0,
  currency        TEXT NOT NULL DEFAULT 'INR',
  subtotal        DECIMAL(12,2),
  tax_amount      DECIMAL(12,2),
  discount_amount DECIMAL(12,2),

  -- AI Processing Metadata
  overall_confidence  DECIMAL(5,4),
  model_used          TEXT CHECK (model_used IN ('gemini', 'custom_ml')),
  gemini_confidence   DECIMAL(5,4),
  ml_confidence       DECIMAL(5,4),
  ml_server_available BOOLEAN DEFAULT FALSE,
  confidence_tier     TEXT CHECK (confidence_tier IN ('high', 'medium', 'low')),
  processing_time_ms  INTEGER,

  -- CrowdTag
  crowdtag_resolved   BOOLEAN NOT NULL DEFAULT FALSE,

  -- Receipt Type
  is_torn_receipt     BOOLEAN NOT NULL DEFAULT FALSE,
  raw_text            TEXT,   -- OCR output, never returned in list endpoints

  -- User Notes
  notes               TEXT,

  -- Soft Delete
  deleted_at          TIMESTAMPTZ,

  -- Metadata
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_receipts_user_id   ON receipts(user_id);
CREATE INDEX IF NOT EXISTS idx_receipts_date      ON receipts(receipt_date DESC);
CREATE INDEX IF NOT EXISTS idx_receipts_merchant  ON receipts(merchant_name);
CREATE INDEX IF NOT EXISTS idx_receipts_created   ON receipts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_receipts_deleted   ON receipts(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_receipts_user_date ON receipts(user_id, receipt_date DESC) WHERE deleted_at IS NULL;

-- updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS update_receipts_updated_at ON receipts;
CREATE TRIGGER update_receipts_updated_at
  BEFORE UPDATE ON receipts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can read own receipts' AND tablename = 'receipts') THEN
    CREATE POLICY "Users can read own receipts"
      ON receipts FOR SELECT
      USING (auth.uid() = user_id AND deleted_at IS NULL);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert own receipts' AND tablename = 'receipts') THEN
    CREATE POLICY "Users can insert own receipts"
      ON receipts FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update own receipts' AND tablename = 'receipts') THEN
    CREATE POLICY "Users can update own receipts"
      ON receipts FOR UPDATE USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Admins can read all receipts' AND tablename = 'receipts') THEN
    CREATE POLICY "Admins can read all receipts"
      ON receipts FOR SELECT
      USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');
  END IF;
END $$;


-- ═══════════════════════════════════════════════════════════
-- TABLE 3: line_items
-- One row per item on a receipt
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS line_items (
  -- Identity
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  receipt_id  UUID NOT NULL REFERENCES receipts(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  -- user_id denormalized for faster RLS — avoids a join on every RLS check

  -- Item Data
  item_name   TEXT NOT NULL,
  quantity    DECIMAL(8,3) NOT NULL DEFAULT 1,
  unit_price  DECIMAL(12,2) NOT NULL DEFAULT 0,
  total_price DECIMAL(12,2) NOT NULL DEFAULT 0,

  -- Categorization
  category    TEXT NOT NULL DEFAULT 'Other',
  -- Valid values: 'Food & Dining' | 'Groceries' | 'Health & Medicine' |
  -- 'Personal Care' | 'Home & Household' | 'Electronics' | 'Clothing & Fashion' |
  -- 'Transport' | 'Entertainment' | 'Education' | 'Takeout & Delivery' | 'Other'

  -- AI Confidence
  confidence      DECIMAL(5,4),
  confidence_tier TEXT CHECK (confidence_tier IN ('high', 'medium', 'low')),

  -- User Correction Tracking
  manually_corrected  BOOLEAN NOT NULL DEFAULT FALSE,
  original_category   TEXT,       -- what AI said before user corrected it
  corrected_at        TIMESTAMPTZ,

  -- Metadata
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_line_items_receipt_id ON line_items(receipt_id);
CREATE INDEX IF NOT EXISTS idx_line_items_user_id    ON line_items(user_id);
CREATE INDEX IF NOT EXISTS idx_line_items_category   ON line_items(category);
CREATE INDEX IF NOT EXISTS idx_line_items_user_cat   ON line_items(user_id, category);

DROP TRIGGER IF EXISTS update_line_items_updated_at ON line_items;
CREATE TRIGGER update_line_items_updated_at
  BEFORE UPDATE ON line_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS
ALTER TABLE line_items ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can read own line items' AND tablename = 'line_items') THEN
    CREATE POLICY "Users can read own line items"
      ON line_items FOR SELECT USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert own line items' AND tablename = 'line_items') THEN
    CREATE POLICY "Users can insert own line items"
      ON line_items FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update own line items' AND tablename = 'line_items') THEN
    CREATE POLICY "Users can update own line items"
      ON line_items FOR UPDATE USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can delete own line items' AND tablename = 'line_items') THEN
    CREATE POLICY "Users can delete own line items"
      ON line_items FOR DELETE USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Admins can read all line items' AND tablename = 'line_items') THEN
    CREATE POLICY "Admins can read all line items"
      ON line_items FOR SELECT
      USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');
  END IF;
END $$;


-- ═══════════════════════════════════════════════════════════
-- TABLE 4: categories (lookup table)
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS categories (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT UNIQUE NOT NULL,
  icon        TEXT NOT NULL,
  color       TEXT NOT NULL,
  description TEXT,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

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
ON CONFLICT (name) DO NOTHING;

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Anyone can read categories' AND tablename = 'categories') THEN
    CREATE POLICY "Anyone can read categories"
      ON categories FOR SELECT USING (true);
  END IF;
END $$;


-- ═══════════════════════════════════════════════════════════
-- MERCHANT FINGERPRINTS — Phase 2 base table
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS merchant_fingerprints (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_key           TEXT UNIQUE NOT NULL,
  display_name           TEXT NOT NULL DEFAULT '',
  city                   TEXT,
  country                TEXT NOT NULL DEFAULT 'IN',
  category_votes         JSONB NOT NULL DEFAULT '{}',
  dominant_category      TEXT,
  confidence_score       DECIMAL(5,4) NOT NULL DEFAULT 0,
  total_votes            INTEGER NOT NULL DEFAULT 0,
  is_resolved            BOOLEAN NOT NULL DEFAULT FALSE,
  resolved_at            TIMESTAMPTZ,
  recent_votes           JSONB NOT NULL DEFAULT '[]',
  drift_detected         BOOLEAN NOT NULL DEFAULT FALSE,
  drift_detected_at      TIMESTAMPTZ,
  last_drift_check       TIMESTAMPTZ,
  category_distribution  JSONB NOT NULL DEFAULT '{}',
  is_multi_category      BOOLEAN NOT NULL DEFAULT FALSE,
  seeded_from_places_api BOOLEAN NOT NULL DEFAULT FALSE,
  places_place_id        TEXT,
  places_api_types       TEXT[],
  created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mf_key       ON merchant_fingerprints(merchant_key);
CREATE INDEX IF NOT EXISTS idx_mf_resolved  ON merchant_fingerprints(is_resolved);
CREATE INDEX IF NOT EXISTS idx_mf_category  ON merchant_fingerprints(dominant_category);
CREATE INDEX IF NOT EXISTS idx_mf_city      ON merchant_fingerprints(city);
CREATE INDEX IF NOT EXISTS idx_mf_votes     ON merchant_fingerprints(total_votes DESC);

DROP TRIGGER IF EXISTS update_merchant_fingerprints_updated_at ON merchant_fingerprints;
CREATE TRIGGER update_merchant_fingerprints_updated_at
  BEFORE UPDATE ON merchant_fingerprints
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE merchant_fingerprints ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Authenticated users can read merchants' AND tablename = 'merchant_fingerprints') THEN
    CREATE POLICY "Authenticated users can read merchants"
      ON merchant_fingerprints FOR SELECT USING (auth.role() = 'authenticated');
  END IF;
END $$;
-- NO direct insert/update — all writes go through RPCs (SECURITY DEFINER)


-- ═══════════════════════════════════════════════════════════
-- AUTO-CREATE PROFILE TRIGGER
-- Fires on every new auth.users row (signup)
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
-- RPC: insert_receipt_with_items
-- Atomic insert — receipt + all line items in one transaction.
-- Either both succeed, or neither does. No orphan receipt rows.
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION insert_receipt_with_items(
  p_user_id    UUID,
  p_receipt    JSONB,
  p_line_items JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_receipt_id UUID;
BEGIN
  -- Validate caller is authenticated as the specified user
  IF auth.uid() IS NULL OR auth.uid() <> p_user_id THEN
    RAISE EXCEPTION 'Unauthorized: caller must match p_user_id';
  END IF;

  -- Insert receipt row
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
    CASE
      WHEN p_receipt->>'receipt_date' IS NOT NULL
        AND p_receipt->>'receipt_date' <> 'null'
        THEN (p_receipt->>'receipt_date')::DATE
      ELSE NULL
    END,
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

  -- Insert all line items
  INSERT INTO line_items (
    receipt_id, user_id, item_name, quantity,
    unit_price, total_price, category, confidence, confidence_tier
  )
  SELECT
    v_receipt_id,
    p_user_id,
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
-- VIEW: platform_stats
-- Used by admin dashboard — overall platform health metrics
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW platform_stats AS
SELECT
  (SELECT COUNT(*) FROM profiles)                                   AS total_users,
  (SELECT COUNT(*) FROM profiles
   WHERE created_at > NOW() - INTERVAL '24 hours')                  AS new_users_today,
  (SELECT COUNT(*) FROM profiles
   WHERE created_at > NOW() - INTERVAL '7 days')                    AS new_users_week,
  (SELECT COUNT(*) FROM receipts WHERE deleted_at IS NULL)          AS total_receipts,
  (SELECT COUNT(*) FROM receipts
   WHERE created_at > NOW() - INTERVAL '24 hours')                  AS receipts_today,
  (SELECT ROUND(AVG(overall_confidence)::NUMERIC, 4)
   FROM receipts WHERE overall_confidence IS NOT NULL)               AS avg_confidence,
  (SELECT
     ROUND(COUNT(*) FILTER (WHERE model_used = 'gemini')::DECIMAL
     / NULLIF(COUNT(*), 0) * 100, 1)
   FROM receipts WHERE model_used IS NOT NULL)                       AS gemini_usage_pct,
  (SELECT
     ROUND(COUNT(*) FILTER (WHERE overall_confidence < 0.6)::DECIMAL
     / NULLIF(COUNT(*), 0) * 100, 1)
   FROM receipts WHERE overall_confidence IS NOT NULL)               AS low_confidence_pct;


-- ═══════════════════════════════════════════════════════════
-- STORAGE BUCKET RLS POLICIES
-- Create these two buckets in Supabase Dashboard first:
--   1. "receipt-temp" — private, 10MB limit, image/jpeg png webp heic
--   2. "avatars"      — public,  2MB limit,  image/jpeg png webp
-- Then run these policies:
-- ═══════════════════════════════════════════════════════════

-- receipt-temp
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'Users can upload own receipt images' AND tablename = 'objects'
  ) THEN
    CREATE POLICY "Users can upload own receipt images"
      ON storage.objects FOR INSERT
      WITH CHECK (
        bucket_id = 'receipt-temp'
        AND auth.uid()::text = (storage.foldername(name))[1]
      );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'Users can read own receipt images' AND tablename = 'objects'
  ) THEN
    CREATE POLICY "Users can read own receipt images"
      ON storage.objects FOR SELECT
      USING (
        bucket_id = 'receipt-temp'
        AND auth.uid()::text = (storage.foldername(name))[1]
      );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'Users can delete own receipt images' AND tablename = 'objects'
  ) THEN
    CREATE POLICY "Users can delete own receipt images"
      ON storage.objects FOR DELETE
      USING (
        bucket_id = 'receipt-temp'
        AND auth.uid()::text = (storage.foldername(name))[1]
      );
  END IF;
END $$;

-- avatars
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'Avatars are publicly readable' AND tablename = 'objects'
  ) THEN
    CREATE POLICY "Avatars are publicly readable"
      ON storage.objects FOR SELECT
      USING (bucket_id = 'avatars');
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'Users can upload own avatar' AND tablename = 'objects'
  ) THEN
    CREATE POLICY "Users can upload own avatar"
      ON storage.objects FOR INSERT
      WITH CHECK (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name))[1]
      );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'Users can update own avatar' AND tablename = 'objects'
  ) THEN
    CREATE POLICY "Users can update own avatar"
      ON storage.objects FOR UPDATE
      USING (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name))[1]
      );
  END IF;
END $$;


-- ═══════════════════════════════════════════════════════════
-- VERIFICATION QUERIES — run these after to confirm success
-- ═══════════════════════════════════════════════════════════
-- SELECT COUNT(*) FROM categories;             -- must be 12
-- SELECT COUNT(*) FROM profiles;               -- 0 if fresh
-- SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';
-- SELECT routine_name FROM information_schema.routines WHERE routine_name = 'insert_receipt_with_items';
-- SELECT table_name FROM information_schema.views WHERE table_schema = 'public';
