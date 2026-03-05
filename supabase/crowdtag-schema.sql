-- ============================================================
-- ATLAS Phase 2 — CrowdTag Mesh Intelligence Schema
-- Run this in Supabase SQL Editor AFTER schema.sql
-- Fully idempotent — safe to re-run multiple times.
-- ============================================================

-- ─── ALTER merchant_fingerprints (Phase 1 → Phase 2) ────────
-- Add all new Phase 2 columns to the existing table
DO $$
BEGIN
  -- display_name
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='merchant_fingerprints' AND column_name='display_name') THEN
    ALTER TABLE merchant_fingerprints ADD COLUMN display_name TEXT;
  END IF;
  -- city
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='merchant_fingerprints' AND column_name='city') THEN
    ALTER TABLE merchant_fingerprints ADD COLUMN city TEXT;
  END IF;
  -- country
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='merchant_fingerprints' AND column_name='country') THEN
    ALTER TABLE merchant_fingerprints ADD COLUMN country TEXT DEFAULT 'IN';
  END IF;
  -- resolved_at
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='merchant_fingerprints' AND column_name='resolved_at') THEN
    ALTER TABLE merchant_fingerprints ADD COLUMN resolved_at TIMESTAMPTZ;
  END IF;
  -- recent_votes
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='merchant_fingerprints' AND column_name='recent_votes') THEN
    ALTER TABLE merchant_fingerprints ADD COLUMN recent_votes JSONB DEFAULT '[]'::jsonb;
  END IF;
  -- drift_detected
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='merchant_fingerprints' AND column_name='drift_detected') THEN
    ALTER TABLE merchant_fingerprints ADD COLUMN drift_detected BOOLEAN DEFAULT FALSE;
  END IF;
  -- drift_detected_at
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='merchant_fingerprints' AND column_name='drift_detected_at') THEN
    ALTER TABLE merchant_fingerprints ADD COLUMN drift_detected_at TIMESTAMPTZ;
  END IF;
  -- last_drift_check
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='merchant_fingerprints' AND column_name='last_drift_check') THEN
    ALTER TABLE merchant_fingerprints ADD COLUMN last_drift_check TIMESTAMPTZ;
  END IF;
  -- places_api_types
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='merchant_fingerprints' AND column_name='places_api_types') THEN
    ALTER TABLE merchant_fingerprints ADD COLUMN places_api_types TEXT[];
  END IF;
  -- places_place_id
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='merchant_fingerprints' AND column_name='places_place_id') THEN
    ALTER TABLE merchant_fingerprints ADD COLUMN places_place_id TEXT;
  END IF;
  -- category_distribution
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='merchant_fingerprints' AND column_name='category_distribution') THEN
    ALTER TABLE merchant_fingerprints ADD COLUMN category_distribution JSONB DEFAULT '{}'::jsonb;
  END IF;
  -- is_multi_category
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='merchant_fingerprints' AND column_name='is_multi_category') THEN
    ALTER TABLE merchant_fingerprints ADD COLUMN is_multi_category BOOLEAN DEFAULT FALSE;
  END IF;
END $$;


-- ─── CrowdTag Votes ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS crowdtag_votes (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  merchant_key TEXT NOT NULL,
  user_id      UUID NOT NULL,
  category     TEXT NOT NULL,
  confidence   DECIMAL(5,4) DEFAULT 0,
  trust_weight DECIMAL(4,3) DEFAULT 0.5,
  weighted_vote DECIMAL(6,4) GENERATED ALWAYS AS (confidence * trust_weight) STORED,
  is_manual    BOOLEAN DEFAULT FALSE,
  receipt_id   UUID,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ─── User Trust Scores ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_trust_scores (
  user_id          UUID PRIMARY KEY,
  trust_score      DECIMAL(4,3) DEFAULT 0.500,
  total_scans      INTEGER DEFAULT 0,
  correct_votes    INTEGER DEFAULT 0,
  incorrect_votes  INTEGER DEFAULT 0,
  accuracy_rate    DECIMAL(5,4) DEFAULT 0,
  tier             TEXT DEFAULT 'new' CHECK (tier IN ('new', 'experienced', 'validated', 'expert')),
  last_updated     TIMESTAMPTZ DEFAULT NOW()
);

-- ─── CrowdTag Events (append-only log) ─────────────────────
CREATE TABLE IF NOT EXISTS crowdtag_events (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event_type   TEXT NOT NULL CHECK (event_type IN ('merchant_resolved', 'drift_detected', 'merchant_seeded', 'vote_logged')),
  merchant_key TEXT,
  payload      JSONB DEFAULT '{}'::jsonb,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);


-- ─── Enable RLS on new tables ──────────────────────────────
ALTER TABLE crowdtag_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_trust_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE crowdtag_events ENABLE ROW LEVEL SECURITY;


-- ─── RLS Policies ──────────────────────────────────────────

-- crowdtag_votes: users can view all, insert own
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Anyone can view crowdtag votes' AND tablename = 'crowdtag_votes') THEN
    CREATE POLICY "Anyone can view crowdtag votes"
      ON crowdtag_votes FOR SELECT USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Authenticated can insert crowdtag votes' AND tablename = 'crowdtag_votes') THEN
    CREATE POLICY "Authenticated can insert crowdtag votes"
      ON crowdtag_votes FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
  END IF;
END $$;

-- user_trust_scores: users see own, system updates
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can view own trust score' AND tablename = 'user_trust_scores') THEN
    CREATE POLICY "Users can view own trust score"
      ON user_trust_scores FOR SELECT USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Admins can view all trust scores' AND tablename = 'user_trust_scores') THEN
    CREATE POLICY "Admins can view all trust scores"
      ON user_trust_scores FOR SELECT USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
      );
  END IF;
END $$;

-- crowdtag_events: public read
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Anyone can view crowdtag events' AND tablename = 'crowdtag_events') THEN
    CREATE POLICY "Anyone can view crowdtag events"
      ON crowdtag_events FOR SELECT USING (true);
  END IF;
END $$;


-- ─── Indexes ───────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_crowdtag_votes_merchant_key ON crowdtag_votes(merchant_key);
CREATE INDEX IF NOT EXISTS idx_crowdtag_votes_user_id ON crowdtag_votes(user_id);
CREATE INDEX IF NOT EXISTS idx_crowdtag_votes_created_at ON crowdtag_votes(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_crowdtag_events_type ON crowdtag_events(event_type);
CREATE INDEX IF NOT EXISTS idx_crowdtag_events_created_at ON crowdtag_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_merchant_fingerprints_city ON merchant_fingerprints(city);
CREATE INDEX IF NOT EXISTS idx_merchant_fingerprints_resolved ON merchant_fingerprints(is_resolved);


-- ═══════════════════════════════════════════════════════════
-- POSTGRES FUNCTIONS (called via Supabase RPC)
-- ═══════════════════════════════════════════════════════════

-- ─── 1. normalize_merchant_key ─────────────────────────────
CREATE OR REPLACE FUNCTION normalize_merchant_key(p_name TEXT, p_city TEXT DEFAULT '')
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_key TEXT;
BEGIN
  -- Lowercase, strip non-alphanumeric (keep spaces), collapse spaces to underscore
  v_key := LOWER(COALESCE(p_name, ''));
  v_key := regexp_replace(v_key, '[^a-z0-9 ]', '', 'g');
  v_key := regexp_replace(v_key, '\s+', '_', 'g');
  v_key := trim(both '_' from v_key);

  IF COALESCE(p_city, '') <> '' THEN
    v_key := v_key || '_' || regexp_replace(
      trim(both '_' from regexp_replace(
        regexp_replace(LOWER(p_city), '[^a-z0-9 ]', '', 'g'),
        '\s+', '_', 'g'
      )),
      '_+', '_', 'g'
    );
  END IF;

  RETURN v_key;
END;
$$;


-- ─── 2. upsert_merchant_vote ──────────────────────────────
CREATE OR REPLACE FUNCTION upsert_merchant_vote(
  p_merchant_name TEXT,
  p_city          TEXT DEFAULT '',
  p_category      TEXT DEFAULT 'Other',
  p_user_id       UUID DEFAULT NULL,
  p_confidence    DECIMAL DEFAULT 0.5,
  p_receipt_id    UUID DEFAULT NULL,
  p_is_manual     BOOLEAN DEFAULT FALSE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_key            TEXT;
  v_trust_weight   DECIMAL(4,3) := 0.500;
  v_category_votes JSONB;
  v_current_weight DECIMAL;
  v_total_weight   DECIMAL := 0;
  v_max_weight     DECIMAL := 0;
  v_max_category   TEXT := 'Other';
  v_total_votes    INTEGER;
  v_confidence     DECIMAL;
  v_is_resolved    BOOLEAN;
  v_recent         JSONB;
  v_cat_key        TEXT;
  v_cat_val        DECIMAL;
  v_dist           JSONB := '{}'::jsonb;
  v_multi          BOOLEAN := FALSE;
BEGIN
  v_key := normalize_merchant_key(p_merchant_name, p_city);

  -- Get user trust weight
  IF p_user_id IS NOT NULL THEN
    SELECT trust_score INTO v_trust_weight
    FROM user_trust_scores
    WHERE user_id = p_user_id;

    IF v_trust_weight IS NULL THEN
      v_trust_weight := 0.500;
      INSERT INTO user_trust_scores (user_id, trust_score, tier)
      VALUES (p_user_id, 0.500, 'new')
      ON CONFLICT (user_id) DO NOTHING;
    END IF;
  END IF;

  -- Upsert merchant_fingerprints
  INSERT INTO merchant_fingerprints (merchant_key, display_name, city, category_votes, dominant_category, total_votes, confidence_score)
  VALUES (v_key, p_merchant_name, p_city, '{}'::jsonb, p_category, 0, 0)
  ON CONFLICT (merchant_key) DO NOTHING;

  -- Insert vote (skip if duplicate receipt_id for same merchant)
  IF p_receipt_id IS NOT NULL THEN
    IF EXISTS (SELECT 1 FROM crowdtag_votes WHERE merchant_key = v_key AND receipt_id = p_receipt_id) THEN
      -- Already voted for this receipt on this merchant
      SELECT jsonb_build_object(
        'merchant_key', v_key,
        'dominant_category', dominant_category,
        'confidence', confidence_score,
        'is_resolved', is_resolved,
        'total_votes', total_votes,
        'duplicate', true
      ) INTO v_dist
      FROM merchant_fingerprints WHERE merchant_key = v_key;
      RETURN v_dist;
    END IF;
  END IF;

  INSERT INTO crowdtag_votes (merchant_key, user_id, category, confidence, trust_weight, is_manual, receipt_id)
  VALUES (v_key, COALESCE(p_user_id, '00000000-0000-0000-0000-000000000000'::uuid), p_category, p_confidence, v_trust_weight, p_is_manual, p_receipt_id);

  -- Update category_votes JSONB
  SELECT category_votes, total_votes, recent_votes
  INTO v_category_votes, v_total_votes, v_recent
  FROM merchant_fingerprints
  WHERE merchant_key = v_key
  FOR UPDATE;

  v_total_votes := COALESCE(v_total_votes, 0) + 1;
  v_category_votes := COALESCE(v_category_votes, '{}'::jsonb);
  v_recent := COALESCE(v_recent, '[]'::jsonb);

  -- Add weighted vote to category
  v_current_weight := COALESCE((v_category_votes ->> p_category)::DECIMAL, 0);
  v_current_weight := v_current_weight + (p_confidence * v_trust_weight);
  v_category_votes := jsonb_set(v_category_votes, ARRAY[p_category], to_jsonb(ROUND(v_current_weight, 4)));

  -- Calculate dominant category and confidence
  FOR v_cat_key, v_cat_val IN
    SELECT key, value::TEXT::DECIMAL FROM jsonb_each_text(v_category_votes)
  LOOP
    v_total_weight := v_total_weight + v_cat_val;
    IF v_cat_val > v_max_weight THEN
      v_max_weight := v_cat_val;
      v_max_category := v_cat_key;
    END IF;
  END LOOP;

  IF v_total_weight > 0 THEN
    v_confidence := ROUND(v_max_weight / v_total_weight, 4);
  ELSE
    v_confidence := 0;
  END IF;

  -- Calculate category_distribution (percentage) + multi-category check
  v_dist := '{}'::jsonb;
  v_multi := FALSE;
  IF v_total_weight > 0 THEN
    FOR v_cat_key, v_cat_val IN
      SELECT key, value::TEXT::DECIMAL FROM jsonb_each_text(v_category_votes)
    LOOP
      v_dist := jsonb_set(v_dist, ARRAY[v_cat_key], to_jsonb(ROUND(v_cat_val / v_total_weight * 100, 1)));
      IF v_cat_key <> v_max_category AND (v_cat_val / v_total_weight * 100) >= 15 THEN
        v_multi := TRUE;
      END IF;
    END LOOP;
  END IF;

  -- Auto-resolve check
  v_is_resolved := (v_total_votes >= 30 AND v_confidence >= 0.75);

  -- Append to recent_votes (keep last 50)
  v_recent := v_recent || jsonb_build_array(jsonb_build_object(
    'category', p_category,
    'confidence', p_confidence,
    'user_id', p_user_id,
    'at', NOW()
  ));
  IF jsonb_array_length(v_recent) > 50 THEN
    v_recent := (SELECT jsonb_agg(elem) FROM (SELECT elem FROM jsonb_array_elements(v_recent) AS elem OFFSET (jsonb_array_length(v_recent) - 50)) sub);
  END IF;

  -- Write back
  UPDATE merchant_fingerprints SET
    category_votes         = v_category_votes,
    dominant_category      = v_max_category,
    confidence_score       = v_confidence,
    total_votes            = v_total_votes,
    is_resolved            = v_is_resolved,
    resolved_at            = CASE WHEN v_is_resolved AND resolved_at IS NULL THEN NOW() ELSE resolved_at END,
    recent_votes           = v_recent,
    display_name           = COALESCE(display_name, p_merchant_name),
    city                   = COALESCE(merchant_fingerprints.city, p_city),
    category_distribution  = v_dist,
    is_multi_category      = v_multi,
    updated_at             = NOW()
  WHERE merchant_key = v_key;

  -- Log resolution event
  IF v_is_resolved THEN
    INSERT INTO crowdtag_events (event_type, merchant_key, payload)
    SELECT 'merchant_resolved', v_key, jsonb_build_object(
      'category', v_max_category,
      'confidence', v_confidence,
      'total_votes', v_total_votes
    )
    WHERE NOT EXISTS (
      SELECT 1 FROM crowdtag_events
      WHERE event_type = 'merchant_resolved' AND merchant_key = v_key
      AND created_at > NOW() - INTERVAL '1 hour'
    );
  END IF;

  -- Log vote event
  INSERT INTO crowdtag_events (event_type, merchant_key, payload)
  VALUES ('vote_logged', v_key, jsonb_build_object(
    'category', p_category,
    'confidence', p_confidence,
    'user_id', p_user_id,
    'is_manual', p_is_manual
  ));

  -- Every 10th vote on a resolved merchant → check drift
  IF v_is_resolved AND v_total_votes % 10 = 0 THEN
    PERFORM check_merchant_drift(v_key);
  END IF;

  -- Update user trust score
  IF p_user_id IS NOT NULL THEN
    PERFORM update_user_trust_score(p_user_id);
  END IF;

  RETURN jsonb_build_object(
    'merchant_key',      v_key,
    'dominant_category', v_max_category,
    'confidence',        v_confidence,
    'is_resolved',       v_is_resolved,
    'total_votes',       v_total_votes
  );
END;
$$;


-- ─── 3. check_merchant_drift ──────────────────────────────
CREATE OR REPLACE FUNCTION check_merchant_drift(p_merchant_key TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_recent         JSONB;
  v_dominant       TEXT;
  v_contra_count   INTEGER := 0;
  v_total_recent   INTEGER := 0;
  v_elem           JSONB;
  v_drift          BOOLEAN := FALSE;
BEGIN
  SELECT recent_votes, dominant_category
  INTO v_recent, v_dominant
  FROM merchant_fingerprints
  WHERE merchant_key = p_merchant_key;

  IF v_recent IS NULL OR jsonb_array_length(v_recent) < 20 THEN
    UPDATE merchant_fingerprints SET last_drift_check = NOW() WHERE merchant_key = p_merchant_key;
    RETURN jsonb_build_object('drift_detected', false, 'merchant_key', p_merchant_key, 'reason', 'insufficient_votes');
  END IF;

  -- Check last 20 votes
  FOR v_elem IN
    SELECT elem FROM jsonb_array_elements(v_recent) AS elem
    ORDER BY (elem ->> 'at')::TIMESTAMPTZ DESC
    LIMIT 20
  LOOP
    v_total_recent := v_total_recent + 1;
    IF (v_elem ->> 'category') <> v_dominant THEN
      v_contra_count := v_contra_count + 1;
    END IF;
  END LOOP;

  -- If ALL 20 recent votes contradict → drift detected
  IF v_contra_count = v_total_recent AND v_total_recent >= 20 THEN
    v_drift := TRUE;
    UPDATE merchant_fingerprints SET
      is_resolved      = FALSE,
      confidence_score  = confidence_score * 0.5,
      drift_detected    = TRUE,
      drift_detected_at = NOW(),
      last_drift_check  = NOW()
    WHERE merchant_key = p_merchant_key;

    INSERT INTO crowdtag_events (event_type, merchant_key, payload)
    VALUES ('drift_detected', p_merchant_key, jsonb_build_object(
      'contra_votes', v_contra_count,
      'dominant_category', v_dominant
    ));
  ELSE
    UPDATE merchant_fingerprints SET last_drift_check = NOW() WHERE merchant_key = p_merchant_key;
  END IF;

  RETURN jsonb_build_object(
    'drift_detected',    v_drift,
    'contra_votes',      v_contra_count,
    'dominant_category', v_dominant,
    'merchant_key',      p_merchant_key
  );
END;
$$;


-- ─── 4. resolve_merchant_for_user ─────────────────────────
CREATE OR REPLACE FUNCTION resolve_merchant_for_user(p_merchant_name TEXT, p_city TEXT DEFAULT '')
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_key    TEXT;
  v_result RECORD;
BEGIN
  v_key := normalize_merchant_key(p_merchant_name, p_city);

  SELECT
    merchant_key,
    is_resolved,
    dominant_category,
    confidence_score,
    total_votes,
    is_multi_category,
    category_distribution,
    seeded_from_places_api
  INTO v_result
  FROM merchant_fingerprints
  WHERE merchant_key = v_key;

  IF v_result IS NULL THEN
    RETURN jsonb_build_object('found', false);
  END IF;

  RETURN jsonb_build_object(
    'found',                 true,
    'merchant_key',          v_result.merchant_key,
    'is_resolved',           v_result.is_resolved,
    'dominant_category',     v_result.dominant_category,
    'confidence',            v_result.confidence_score,
    'total_votes',           v_result.total_votes,
    'is_multi_category',     v_result.is_multi_category,
    'category_distribution', v_result.category_distribution,
    'seeded',                v_result.seeded_from_places_api
  );
END;
$$;


-- ─── 5. update_user_trust_score ───────────────────────────
CREATE OR REPLACE FUNCTION update_user_trust_score(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total    INTEGER;
  v_correct  INTEGER := 0;
  v_incorrect INTEGER := 0;
  v_accuracy DECIMAL := 0;
  v_tier     TEXT := 'new';
  v_score    DECIMAL(4,3) := 0.500;
BEGIN
  -- Count total scans (votes)
  SELECT COUNT(*) INTO v_total FROM crowdtag_votes WHERE user_id = p_user_id;

  -- Count correct votes (voted for the eventual dominant category of resolved merchants)
  SELECT COUNT(*) INTO v_correct
  FROM crowdtag_votes cv
  JOIN merchant_fingerprints mf ON cv.merchant_key = mf.merchant_key
  WHERE cv.user_id = p_user_id
    AND mf.is_resolved = TRUE
    AND cv.category = mf.dominant_category;

  -- Incorrect = total votes on resolved merchants minus correct
  SELECT COUNT(*) - v_correct INTO v_incorrect
  FROM crowdtag_votes cv
  JOIN merchant_fingerprints mf ON cv.merchant_key = mf.merchant_key
  WHERE cv.user_id = p_user_id
    AND mf.is_resolved = TRUE;

  IF v_incorrect < 0 THEN v_incorrect := 0; END IF;

  -- Accuracy
  IF v_total > 0 THEN
    v_accuracy := ROUND(v_correct::DECIMAL / v_total, 4);
  END IF;

  -- Determine tier
  IF v_total >= 500 AND v_accuracy >= 0.92 THEN
    v_tier := 'expert';
    v_score := 2.500;
  ELSIF v_total >= 100 AND v_accuracy >= 0.85 THEN
    v_tier := 'validated';
    v_score := 2.000;
  ELSIF v_total >= 10 THEN
    v_tier := 'experienced';
    -- Linear interpolation: 1.0 at 10 scans → 1.5 at 99 scans
    v_score := ROUND(1.0 + (LEAST(v_total, 99) - 10)::DECIMAL / 89 * 0.5, 3);
  ELSE
    v_tier := 'new';
    v_score := 0.500;
  END IF;

  -- Upsert
  INSERT INTO user_trust_scores (user_id, trust_score, total_scans, correct_votes, incorrect_votes, accuracy_rate, tier, last_updated)
  VALUES (p_user_id, v_score, v_total, v_correct, v_incorrect, v_accuracy, v_tier, NOW())
  ON CONFLICT (user_id) DO UPDATE SET
    trust_score     = EXCLUDED.trust_score,
    total_scans     = EXCLUDED.total_scans,
    correct_votes   = EXCLUDED.correct_votes,
    incorrect_votes = EXCLUDED.incorrect_votes,
    accuracy_rate   = EXCLUDED.accuracy_rate,
    tier            = EXCLUDED.tier,
    last_updated    = NOW();

  RETURN jsonb_build_object(
    'updated',     true,
    'trust_score', v_score,
    'tier',        v_tier,
    'accuracy',    v_accuracy,
    'total_scans', v_total
  );
END;
$$;


-- ─── 6. seed_merchant_from_places ─────────────────────────
CREATE OR REPLACE FUNCTION seed_merchant_from_places(
  p_name     TEXT,
  p_city     TEXT,
  p_country  TEXT DEFAULT 'IN',
  p_category TEXT DEFAULT 'Other',
  p_place_id TEXT DEFAULT NULL,
  p_types    TEXT[] DEFAULT '{}'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_key    TEXT;
  v_result JSONB;
BEGIN
  v_key := normalize_merchant_key(p_name, p_city);

  INSERT INTO merchant_fingerprints (
    merchant_key, display_name, city, country,
    category_votes, dominant_category, confidence_score, total_votes,
    is_resolved, seeded_from_places_api, places_place_id, places_api_types,
    recent_votes, category_distribution
  )
  VALUES (
    v_key, p_name, p_city, p_country,
    jsonb_build_object(p_category, 3.5),  -- 5 virtual votes × 0.70 conf
    p_category, 0.7000, 5,
    TRUE, TRUE, p_place_id, p_types,
    '[]'::jsonb, jsonb_build_object(p_category, 100.0)
  )
  ON CONFLICT (merchant_key) DO NOTHING;

  -- Log seeded event
  INSERT INTO crowdtag_events (event_type, merchant_key, payload)
  SELECT 'merchant_seeded', v_key, jsonb_build_object(
    'name', p_name, 'city', p_city, 'category', p_category, 'place_id', p_place_id
  )
  WHERE NOT EXISTS (
    SELECT 1 FROM crowdtag_events WHERE event_type = 'merchant_seeded' AND merchant_key = v_key
  );

  v_result := jsonb_build_object('seeded', TRUE, 'merchant_key', v_key, 'category', p_category);
  RETURN v_result;
END;
$$;


-- ═══════════════════════════════════════════════════════════
-- VIEWS (for admin panel)
-- ═══════════════════════════════════════════════════════════

-- ─── Admin Summary ─────────────────────────────────────────
CREATE OR REPLACE VIEW crowdtag_admin_summary AS
SELECT
  COUNT(*)                                                     AS total_merchants,
  COUNT(*) FILTER (WHERE is_resolved = TRUE)                   AS resolved_merchants,
  COUNT(*) FILTER (WHERE seeded_from_places_api = TRUE)        AS seeded_merchants,
  COUNT(*) FILTER (WHERE drift_detected = TRUE)                AS drift_merchants,
  COUNT(*) FILTER (WHERE is_multi_category = TRUE)             AS multi_category_merchants,
  ROUND(AVG(confidence_score), 4)                              AS avg_confidence,
  ROUND(AVG(total_votes), 1)                                   AS avg_votes_per_merchant,
  COALESCE(SUM(total_votes), 0)                                AS total_votes_cast
FROM merchant_fingerprints;


-- ─── Category Distribution ────────────────────────────────
CREATE OR REPLACE VIEW crowdtag_category_distribution AS
SELECT
  dominant_category,
  COUNT(*)                                            AS merchant_count,
  COUNT(*) FILTER (WHERE is_resolved = TRUE)          AS resolved_count,
  SUM(total_votes)                                    AS total_votes,
  ROUND(AVG(confidence_score), 4)                     AS avg_confidence
FROM merchant_fingerprints
WHERE dominant_category IS NOT NULL
GROUP BY dominant_category
ORDER BY merchant_count DESC;


-- ─── Top Merchants ────────────────────────────────────────
CREATE OR REPLACE VIEW crowdtag_top_merchants AS
SELECT
  merchant_key,
  display_name,
  city,
  dominant_category,
  confidence_score,
  total_votes,
  is_resolved,
  is_multi_category,
  category_distribution,
  seeded_from_places_api
FROM merchant_fingerprints
ORDER BY total_votes DESC
LIMIT 100;


-- ─── Trust Leaderboard ───────────────────────────────────
CREATE OR REPLACE VIEW crowdtag_trust_leaderboard AS
SELECT
  uts.user_id,
  p.full_name,
  p.email,
  uts.trust_score,
  uts.tier,
  uts.accuracy_rate,
  uts.total_scans,
  uts.correct_votes,
  uts.incorrect_votes
FROM user_trust_scores uts
LEFT JOIN profiles p ON p.id = uts.user_id
ORDER BY uts.trust_score DESC
LIMIT 50;


-- ═══════════════════════════════════════════════════════════
-- HARDENING (Phase 2 robustness improvements)
-- ═══════════════════════════════════════════════════════════

-- ─── FK Constraints (add if missing) ──────────────────────
DO $$
BEGIN
  -- crowdtag_votes.merchant_key → merchant_fingerprints.merchant_key
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'fk_votes_merchant_key' AND table_name = 'crowdtag_votes'
  ) THEN
    ALTER TABLE crowdtag_votes
      ADD CONSTRAINT fk_votes_merchant_key
      FOREIGN KEY (merchant_key) REFERENCES merchant_fingerprints(merchant_key)
      ON DELETE CASCADE;
  END IF;

  -- crowdtag_votes.user_id → profiles.id
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'fk_votes_user_id' AND table_name = 'crowdtag_votes'
  ) THEN
    ALTER TABLE crowdtag_votes
      ADD CONSTRAINT fk_votes_user_id
      FOREIGN KEY (user_id) REFERENCES profiles(id)
      ON DELETE CASCADE;
  END IF;

  -- crowdtag_votes.receipt_id → receipts.id
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'fk_votes_receipt_id' AND table_name = 'crowdtag_votes'
  ) THEN
    ALTER TABLE crowdtag_votes
      ADD CONSTRAINT fk_votes_receipt_id
      FOREIGN KEY (receipt_id) REFERENCES receipts(id)
      ON DELETE SET NULL;
  END IF;

  -- user_trust_scores.user_id → profiles.id
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'fk_trust_user_id' AND table_name = 'user_trust_scores'
  ) THEN
    ALTER TABLE user_trust_scores
      ADD CONSTRAINT fk_trust_user_id
      FOREIGN KEY (user_id) REFERENCES profiles(id)
      ON DELETE CASCADE;
  END IF;
END $$;


-- ─── Unique Receipt Index (DB-level double-vote prevention) 
CREATE UNIQUE INDEX IF NOT EXISTS idx_votes_unique_receipt
  ON crowdtag_votes(merchant_key, receipt_id)
  WHERE receipt_id IS NOT NULL;


-- ─── Auto-update trigger for updated_at ───────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS merchant_fingerprints_updated_at ON merchant_fingerprints;
CREATE TRIGGER merchant_fingerprints_updated_at
  BEFORE UPDATE ON merchant_fingerprints
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();


-- ─── Additional Performance Indexes ───────────────────────
CREATE INDEX IF NOT EXISTS idx_votes_category ON crowdtag_votes(category);
CREATE INDEX IF NOT EXISTS idx_merchant_dominant ON merchant_fingerprints(dominant_category);
CREATE INDEX IF NOT EXISTS idx_merchant_country ON merchant_fingerprints(country);
CREATE INDEX IF NOT EXISTS idx_merchant_drift ON merchant_fingerprints(drift_detected) WHERE drift_detected = TRUE;
CREATE INDEX IF NOT EXISTS idx_merchant_seeded ON merchant_fingerprints(seeded_from_places_api) WHERE seeded_from_places_api = TRUE;
CREATE INDEX IF NOT EXISTS idx_trust_tier ON user_trust_scores(tier);


-- ═══════════════════════════════════════════════════════════
-- SEED DEFAULT CATEGORIES (12 ATLAS categories)
-- ═══════════════════════════════════════════════════════════

INSERT INTO categories (name, icon, color) VALUES
  ('Food & Dining',       'utensils',      '#f97316'),
  ('Groceries',           'shopping-cart', '#22c55e'),
  ('Health & Medicine',   'heart-pulse',   '#ef4444'),
  ('Personal Care',       'sparkles',      '#a855f7'),
  ('Home & Household',    'home',          '#3b82f6'),
  ('Electronics',         'cpu',           '#06b6d4'),
  ('Clothing & Fashion',  'shirt',         '#ec4899'),
  ('Transport',           'car',           '#eab308'),
  ('Entertainment',       'film',          '#8b5cf6'),
  ('Education',           'book-open',     '#14b8a6'),
  ('Takeout & Delivery',  'package',       '#f59e0b'),
  ('Other',               'circle-dot',    '#6b7280')
ON CONFLICT (name) DO NOTHING;

