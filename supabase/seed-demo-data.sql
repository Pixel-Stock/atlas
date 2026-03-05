-- ============================================================
-- ATLAS — Demo Seed Data (25 entries per table)
-- ============================================================
-- Run AFTER: schema.sql → crowdtag-schema.sql
-- Creates 25 fake users, receipts, line items, etc.
-- Uses Supabase auth.users direct insert (SQL Editor runs as superuser)
-- ============================================================


-- ─── Step 1: Create 25 demo users in auth.users ──────────
-- These will auto-create profiles via the handle_new_user trigger

INSERT INTO auth.users (
  id, instance_id, email, encrypted_password,
  email_confirmed_at, raw_user_meta_data, role, aud,
  created_at, updated_at
)
VALUES
  ('a1000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000', 'aarav.sharma@gmail.com',     '$2a$12$dummyhashvalue000000000000000001', NOW(), '{"full_name":"Aarav Sharma"}'::jsonb,    'authenticated', 'authenticated', NOW() - INTERVAL '30 days', NOW()),
  ('a1000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000000', 'priya.patel@gmail.com',      '$2a$12$dummyhashvalue000000000000000002', NOW(), '{"full_name":"Priya Patel"}'::jsonb,     'authenticated', 'authenticated', NOW() - INTERVAL '28 days', NOW()),
  ('a1000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000000', 'rohan.deshmukh@gmail.com',   '$2a$12$dummyhashvalue000000000000000003', NOW(), '{"full_name":"Rohan Deshmukh"}'::jsonb,  'authenticated', 'authenticated', NOW() - INTERVAL '25 days', NOW()),
  ('a1000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000000', 'sneha.kulkarni@gmail.com',   '$2a$12$dummyhashvalue000000000000000004', NOW(), '{"full_name":"Sneha Kulkarni"}'::jsonb,  'authenticated', 'authenticated', NOW() - INTERVAL '22 days', NOW()),
  ('a1000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000000', 'vikram.joshi@gmail.com',     '$2a$12$dummyhashvalue000000000000000005', NOW(), '{"full_name":"Vikram Joshi"}'::jsonb,    'authenticated', 'authenticated', NOW() - INTERVAL '20 days', NOW()),
  ('a1000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000000', 'anita.mehta@gmail.com',      '$2a$12$dummyhashvalue000000000000000006', NOW(), '{"full_name":"Anita Mehta"}'::jsonb,     'authenticated', 'authenticated', NOW() - INTERVAL '18 days', NOW()),
  ('a1000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000000', 'karan.singh@gmail.com',      '$2a$12$dummyhashvalue000000000000000007', NOW(), '{"full_name":"Karan Singh"}'::jsonb,     'authenticated', 'authenticated', NOW() - INTERVAL '17 days', NOW()),
  ('a1000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000000', 'neha.gupta@gmail.com',       '$2a$12$dummyhashvalue000000000000000008', NOW(), '{"full_name":"Neha Gupta"}'::jsonb,      'authenticated', 'authenticated', NOW() - INTERVAL '15 days', NOW()),
  ('a1000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000000', 'rahul.verma@gmail.com',      '$2a$12$dummyhashvalue000000000000000009', NOW(), '{"full_name":"Rahul Verma"}'::jsonb,     'authenticated', 'authenticated', NOW() - INTERVAL '14 days', NOW()),
  ('a1000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000000', 'pooja.reddy@gmail.com',      '$2a$12$dummyhashvalue000000000000000010', NOW(), '{"full_name":"Pooja Reddy"}'::jsonb,     'authenticated', 'authenticated', NOW() - INTERVAL '12 days', NOW()),
  ('a1000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000000', 'amit.bhatt@gmail.com',       '$2a$12$dummyhashvalue000000000000000011', NOW(), '{"full_name":"Amit Bhatt"}'::jsonb,      'authenticated', 'authenticated', NOW() - INTERVAL '11 days', NOW()),
  ('a1000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000000', 'rashmi.nair@gmail.com',      '$2a$12$dummyhashvalue000000000000000012', NOW(), '{"full_name":"Rashmi Nair"}'::jsonb,     'authenticated', 'authenticated', NOW() - INTERVAL '10 days', NOW()),
  ('a1000000-0000-0000-0000-000000000013', '00000000-0000-0000-0000-000000000000', 'deepak.chavan@gmail.com',    '$2a$12$dummyhashvalue000000000000000013', NOW(), '{"full_name":"Deepak Chavan"}'::jsonb,   'authenticated', 'authenticated', NOW() - INTERVAL '9 days', NOW()),
  ('a1000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000000', 'kavita.iyer@gmail.com',      '$2a$12$dummyhashvalue000000000000000014', NOW(), '{"full_name":"Kavita Iyer"}'::jsonb,     'authenticated', 'authenticated', NOW() - INTERVAL '8 days', NOW()),
  ('a1000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000000', 'manish.tiwari@gmail.com',    '$2a$12$dummyhashvalue000000000000000015', NOW(), '{"full_name":"Manish Tiwari"}'::jsonb,   'authenticated', 'authenticated', NOW() - INTERVAL '7 days', NOW()),
  ('a1000000-0000-0000-0000-000000000016', '00000000-0000-0000-0000-000000000000', 'sunita.das@gmail.com',       '$2a$12$dummyhashvalue000000000000000016', NOW(), '{"full_name":"Sunita Das"}'::jsonb,      'authenticated', 'authenticated', NOW() - INTERVAL '6 days', NOW()),
  ('a1000000-0000-0000-0000-000000000017', '00000000-0000-0000-0000-000000000000', 'arun.patil@gmail.com',       '$2a$12$dummyhashvalue000000000000000017', NOW(), '{"full_name":"Arun Patil"}'::jsonb,      'authenticated', 'authenticated', NOW() - INTERVAL '5 days', NOW()),
  ('a1000000-0000-0000-0000-000000000018', '00000000-0000-0000-0000-000000000000', 'meera.kapoor@gmail.com',     '$2a$12$dummyhashvalue000000000000000018', NOW(), '{"full_name":"Meera Kapoor"}'::jsonb,    'authenticated', 'authenticated', NOW() - INTERVAL '4 days', NOW()),
  ('a1000000-0000-0000-0000-000000000019', '00000000-0000-0000-0000-000000000000', 'sanjay.more@gmail.com',      '$2a$12$dummyhashvalue000000000000000019', NOW(), '{"full_name":"Sanjay More"}'::jsonb,     'authenticated', 'authenticated', NOW() - INTERVAL '3 days', NOW()),
  ('a1000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000000', 'divya.shah@gmail.com',       '$2a$12$dummyhashvalue000000000000000020', NOW(), '{"full_name":"Divya Shah"}'::jsonb,      'authenticated', 'authenticated', NOW() - INTERVAL '2 days', NOW()),
  ('a1000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000000', 'ravi.kumar@gmail.com',       '$2a$12$dummyhashvalue000000000000000021', NOW(), '{"full_name":"Ravi Kumar"}'::jsonb,      'authenticated', 'authenticated', NOW() - INTERVAL '2 days', NOW()),
  ('a1000000-0000-0000-0000-000000000022', '00000000-0000-0000-0000-000000000000', 'lakshmi.rao@gmail.com',      '$2a$12$dummyhashvalue000000000000000022', NOW(), '{"full_name":"Lakshmi Rao"}'::jsonb,     'authenticated', 'authenticated', NOW() - INTERVAL '1 day', NOW()),
  ('a1000000-0000-0000-0000-000000000023', '00000000-0000-0000-0000-000000000000', 'harsh.pandey@gmail.com',     '$2a$12$dummyhashvalue000000000000000023', NOW(), '{"full_name":"Harsh Pandey"}'::jsonb,    'authenticated', 'authenticated', NOW() - INTERVAL '1 day', NOW()),
  ('a1000000-0000-0000-0000-000000000024', '00000000-0000-0000-0000-000000000000', 'ankita.jain@gmail.com',      '$2a$12$dummyhashvalue000000000000000024', NOW(), '{"full_name":"Ankita Jain"}'::jsonb,     'authenticated', 'authenticated', NOW() - INTERVAL '12 hours', NOW()),
  ('a1000000-0000-0000-0000-000000000025', '00000000-0000-0000-0000-000000000000', 'admin@atlas.app',            '$2a$12$dummyhashvalue000000000000000025', NOW(), '{"full_name":"ATLAS Admin"}'::jsonb,     'authenticated', 'authenticated', NOW() - INTERVAL '30 days', NOW())
ON CONFLICT (id) DO NOTHING;


-- ─── Step 2: Wait for trigger, then update profiles ──────
-- The trigger auto-created profiles. Now update admin + preferences.

UPDATE profiles SET role = 'admin' WHERE id = 'a1000000-0000-0000-0000-000000000025';
UPDATE profiles SET theme_preference = 'light' WHERE id = 'a1000000-0000-0000-0000-000000000003';
UPDATE profiles SET theme_preference = 'system' WHERE id = 'a1000000-0000-0000-0000-000000000007';
DO $$ BEGIN
  UPDATE profiles SET currency = 'USD' WHERE id = 'a1000000-0000-0000-0000-000000000010';
EXCEPTION WHEN undefined_column THEN NULL;
END $$;
UPDATE profiles SET last_sign_in_at = NOW() - INTERVAL '1 hour' WHERE id = 'a1000000-0000-0000-0000-000000000001';
UPDATE profiles SET last_sign_in_at = NOW() - INTERVAL '2 hours' WHERE id = 'a1000000-0000-0000-0000-000000000002';
UPDATE profiles SET last_sign_in_at = NOW() - INTERVAL '30 minutes' WHERE id = 'a1000000-0000-0000-0000-000000000025';


-- ─── Step 3: Insert 25 receipts ──────────────────────────

INSERT INTO receipts (id, user_id, merchant_name, merchant_city, receipt_date, total_amount, currency, subtotal, tax_amount, discount_amount, overall_confidence, model_used, gemini_confidence, ml_confidence, ml_server_available, confidence_tier, processing_time_ms, crowdtag_resolved, created_at) VALUES
  ('b1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'D-Mart',                 'Pune',    NOW()::date - 1,  2340.50, 'INR', 2100.00, 240.50, NULL,   0.9520, 'gemini',    0.9520, 0.8800, TRUE,  'high',   1200, TRUE,  NOW() - INTERVAL '1 day'),
  ('b1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', 'Vaishali Restaurant',    'Pune',    NOW()::date - 3,  850.00,  'INR', 750.00,  100.00, NULL,   0.9100, 'gemini',    0.9100, 0.8500, TRUE,  'high',   980,  TRUE,  NOW() - INTERVAL '3 days'),
  ('b1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000002', 'Reliance Fresh',         'Pune',    NOW()::date - 2,  1560.75, 'INR', 1400.00, 160.75, NULL,   0.8900, 'gemini',    0.8900, 0.8200, TRUE,  'high',   1100, FALSE, NOW() - INTERVAL '2 days'),
  ('b1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000002', 'Apollo Pharmacy',        'Pune',    NOW()::date - 5,  430.00,  'INR', 430.00,  0,      NULL,   0.8750, 'gemini',    0.8750, 0.7900, TRUE,  'high',   890,  TRUE,  NOW() - INTERVAL '5 days'),
  ('b1000000-0000-0000-0000-000000000005', 'a1000000-0000-0000-0000-000000000003', 'McDonald''s',            'Pune',    NOW()::date - 1,  420.00,  'INR', 380.00,  40.00,  NULL,   0.9800, 'gemini',    0.9800, 0.9200, TRUE,  'high',   750,  TRUE,  NOW() - INTERVAL '1 day'),
  ('b1000000-0000-0000-0000-000000000006', 'a1000000-0000-0000-0000-000000000003', 'Croma',                  'Pune',    NOW()::date - 7,  15999.00,'INR', 13559.32,2439.68,NULL,   0.9300, 'gemini',    0.9300, 0.8700, TRUE,  'high',   1500, FALSE, NOW() - INTERVAL '7 days'),
  ('b1000000-0000-0000-0000-000000000007', 'a1000000-0000-0000-0000-000000000004', 'Zara',                   'Mumbai',  NOW()::date - 4,  3450.00, 'INR', 2923.73, 526.27, NULL,   0.8100, 'custom_ml', 0.7500, 0.8100, TRUE,  'medium', 2100, FALSE, NOW() - INTERVAL '4 days'),
  ('b1000000-0000-0000-0000-000000000008', 'a1000000-0000-0000-0000-000000000004', 'Leopold Cafe',           'Mumbai',  NOW()::date - 2,  1280.00, 'INR', 1100.00, 180.00, NULL,   0.9400, 'gemini',    0.9400, 0.8800, TRUE,  'high',   1050, TRUE,  NOW() - INTERVAL '2 days'),
  ('b1000000-0000-0000-0000-000000000009', 'a1000000-0000-0000-0000-000000000005', 'Indian Oil Petrol Pump', 'Pune',    NOW()::date - 1,  2500.00, 'INR', 2500.00, 0,      NULL,   0.9700, 'gemini',    0.9700, 0.9100, TRUE,  'high',   680,  TRUE,  NOW() - INTERVAL '1 day'),
  ('b1000000-0000-0000-0000-000000000010', 'a1000000-0000-0000-0000-000000000005', 'PVR Cinemas',            'Pune',    NOW()::date - 6,  780.00,  'INR', 660.00,  120.00, NULL,   0.7200, 'gemini',    0.7200, 0.6500, TRUE,  'medium', 1800, FALSE, NOW() - INTERVAL '6 days'),
  ('b1000000-0000-0000-0000-000000000011', 'a1000000-0000-0000-0000-000000000006', 'Lakme Salon',            'Pune',    NOW()::date - 3,  1800.00, 'INR', 1525.42, 274.58, NULL,   0.8600, 'gemini',    0.8600, 0.8000, TRUE,  'high',   1300, TRUE,  NOW() - INTERVAL '3 days'),
  ('b1000000-0000-0000-0000-000000000012', 'a1000000-0000-0000-0000-000000000006', 'Domino''s Pizza',        'Pune',    NOW()::date - 1,  599.00,  'INR', 520.00,  79.00,  NULL,   0.9600, 'gemini',    0.9600, 0.9000, TRUE,  'high',   820,  TRUE,  NOW() - INTERVAL '1 day'),
  ('b1000000-0000-0000-0000-000000000013', 'a1000000-0000-0000-0000-000000000007', 'Crossword Bookstore',    'Pune',    NOW()::date - 8,  940.00,  'INR', 940.00,  0,      NULL,   0.9150, 'gemini',    0.9150, 0.8400, TRUE,  'high',   950,  FALSE, NOW() - INTERVAL '8 days'),
  ('b1000000-0000-0000-0000-000000000014', 'a1000000-0000-0000-0000-000000000007', 'Starbucks',              'Mumbai',  NOW()::date - 2,  650.00,  'INR', 550.85,  99.15,  NULL,   0.9000, 'gemini',    0.9000, 0.8300, TRUE,  'high',   1100, TRUE,  NOW() - INTERVAL '2 days'),
  ('b1000000-0000-0000-0000-000000000015', 'a1000000-0000-0000-0000-000000000008', 'Big Bazaar',             'Nagpur',  NOW()::date - 4,  3200.00, 'INR', 2900.00, 300.00, NULL,   0.8800, 'gemini',    0.8800, 0.8200, TRUE,  'high',   1400, TRUE,  NOW() - INTERVAL '4 days'),
  ('b1000000-0000-0000-0000-000000000016', 'a1000000-0000-0000-0000-000000000008', 'Wellness Forever',       'Nagpur',  NOW()::date - 1,  290.00,  'INR', 290.00,  0,      NULL,   0.9250, 'gemini',    0.9250, 0.8500, TRUE,  'high',   780,  FALSE, NOW() - INTERVAL '1 day'),
  ('b1000000-0000-0000-0000-000000000017', 'a1000000-0000-0000-0000-000000000009', 'Pantaloons',             'Nashik',  NOW()::date - 5,  2100.00, 'INR', 1779.66, 320.34, NULL,   0.7800, 'custom_ml', 0.7200, 0.7800, TRUE,  'medium', 2200, FALSE, NOW() - INTERVAL '5 days'),
  ('b1000000-0000-0000-0000-000000000018', 'a1000000-0000-0000-0000-000000000009', 'Haldiram''s',            'Nagpur',  NOW()::date - 2,  560.00,  'INR', 490.00,  70.00,  NULL,   0.9400, 'gemini',    0.9400, 0.8900, TRUE,  'high',   900,  TRUE,  NOW() - INTERVAL '2 days'),
  ('b1000000-0000-0000-0000-000000000019', 'a1000000-0000-0000-0000-000000000010', 'Vijay Sales',            'Mumbai',  NOW()::date - 3,  8999.00, 'INR', 7627.12, 1371.88,NULL,   0.8500, 'gemini',    0.8500, 0.7900, TRUE,  'high',   1600, FALSE, NOW() - INTERVAL '3 days'),
  ('b1000000-0000-0000-0000-000000000020', 'a1000000-0000-0000-0000-000000000010', 'IKEA',                   'Mumbai',  NOW()::date - 1,  4500.00, 'INR', 3813.56, 686.44, NULL,   0.9100, 'gemini',    0.9100, 0.8600, TRUE,  'high',   1350, TRUE,  NOW() - INTERVAL '1 day'),
  ('b1000000-0000-0000-0000-000000000021', 'a1000000-0000-0000-0000-000000000011', 'Uber',                   'Pune',    NOW()::date - 1,  245.00,  'INR', 245.00,  0,      NULL,   0.9900, 'gemini',    0.9900, 0.9500, TRUE,  'high',   500,  TRUE,  NOW() - INTERVAL '1 day'),
  ('b1000000-0000-0000-0000-000000000022', 'a1000000-0000-0000-0000-000000000012', 'Home Centre',            'Thane',   NOW()::date - 6,  6200.00, 'INR', 5254.24, 945.76, NULL,   0.8300, 'custom_ml', 0.7600, 0.8300, TRUE,  'medium', 2400, FALSE, NOW() - INTERVAL '6 days'),
  ('b1000000-0000-0000-0000-000000000023', 'a1000000-0000-0000-0000-000000000013', 'MedPlus',                'Pune',    NOW()::date - 2,  175.00,  'INR', 175.00,  0,      NULL,   0.9050, 'gemini',    0.9050, 0.8400, TRUE,  'high',   850,  TRUE,  NOW() - INTERVAL '2 days'),
  ('b1000000-0000-0000-0000-000000000024', 'a1000000-0000-0000-0000-000000000014', 'Swiggy',                 'Mumbai',  NOW()::date - 1,  680.00,  'INR', 580.00,  60.00,  40.00,  0.5200, 'gemini',    0.5200, 0.4500, FALSE, 'low',    3200, FALSE, NOW() - INTERVAL '1 day'),
  ('b1000000-0000-0000-0000-000000000025', 'a1000000-0000-0000-0000-000000000015', 'KFC',                    'Kolhapur',NOW()::date - 3,  520.00,  'INR', 460.00,  60.00,  NULL,   0.9350, 'gemini',    0.9350, 0.8700, TRUE,  'high',   920,  TRUE,  NOW() - INTERVAL '3 days')
ON CONFLICT (id) DO NOTHING;


-- ─── Step 4: Insert 75+ line items (3 per receipt avg) ────
-- NOTE: `amount` is the OLD column name (= total_price). Included for backwards compat.

INSERT INTO line_items (receipt_id, user_id, item_name, quantity, unit_price, total_price, amount, category, confidence, confidence_tier) VALUES
  -- Receipt 1: D-Mart groceries
  ('b1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'Tata Salt 1kg',             2, 28.00,   56.00,   56.00,   'Groceries',          0.9800, 'high'),
  ('b1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'Aashirvaad Atta 5kg',       1, 280.00,  280.00,  280.00,  'Groceries',          0.9700, 'high'),
  ('b1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'Amul Butter 500g',          1, 270.00,  270.00,  270.00,  'Groceries',          0.9500, 'high'),
  ('b1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'Surf Excel Liquid 1L',      1, 220.00,  220.00,  220.00,  'Home & Household',   0.9100, 'high'),
  ('b1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'Colgate MaxFresh',          2, 95.00,   190.00,  190.00,  'Personal Care',      0.8900, 'high'),

  -- Receipt 2: Vaishali Restaurant
  ('b1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', 'Masala Dosa',               2, 120.00,  240.00,  240.00,  'Food & Dining',      0.9500, 'high'),
  ('b1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', 'Filter Coffee',             2, 60.00,   120.00,  120.00,  'Food & Dining',      0.9300, 'high'),
  ('b1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', 'Idli Sambar',               1, 90.00,   90.00,   90.00,   'Food & Dining',      0.9400, 'high'),

  -- Receipt 3: Reliance Fresh
  ('b1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000002', 'Onions 2kg',                1, 60.00,   60.00,   60.00,   'Groceries',          0.9600, 'high'),
  ('b1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000002', 'Tomatoes 1kg',              1, 40.00,   40.00,   40.00,   'Groceries',          0.9500, 'high'),
  ('b1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000002', 'Fortune Oil 5L',            1, 750.00,  750.00,  750.00,  'Groceries',          0.9200, 'high'),

  -- Receipt 4: Apollo Pharmacy
  ('b1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000002', 'Crocin Advance',            1, 30.00,   30.00,   30.00,   'Health & Medicine',  0.9300, 'high'),
  ('b1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000002', 'Dettol Antiseptic 250ml',   1, 120.00,  120.00,  120.00,  'Health & Medicine',  0.8800, 'high'),
  ('b1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000002', 'Band-Aid Pack',             2, 45.00,   90.00,   90.00,   'Health & Medicine',  0.8600, 'high'),

  -- Receipt 5: McDonald's
  ('b1000000-0000-0000-0000-000000000005', 'a1000000-0000-0000-0000-000000000003', 'McAloo Tikki Meal',         1, 169.00,  169.00,  169.00,  'Food & Dining',      0.9800, 'high'),
  ('b1000000-0000-0000-0000-000000000005', 'a1000000-0000-0000-0000-000000000003', 'McChicken Burger',          1, 149.00,  149.00,  149.00,  'Food & Dining',      0.9700, 'high'),
  ('b1000000-0000-0000-0000-000000000005', 'a1000000-0000-0000-0000-000000000003', 'Coke Medium',               2, 51.00,   102.00,  102.00,  'Food & Dining',      0.9900, 'high'),

  -- Receipt 6: Croma
  ('b1000000-0000-0000-0000-000000000006', 'a1000000-0000-0000-0000-000000000003', 'boAt Airdopes 141',         1, 1299.00, 1299.00, 1299.00, 'Electronics',        0.9500, 'high'),
  ('b1000000-0000-0000-0000-000000000006', 'a1000000-0000-0000-0000-000000000003', 'USB-C Cable 2m',            2, 350.00,  700.00,  700.00,  'Electronics',        0.9200, 'high'),
  ('b1000000-0000-0000-0000-000000000006', 'a1000000-0000-0000-0000-000000000003', 'Samsung 25W Charger',       1, 1499.00, 1499.00, 1499.00, 'Electronics',        0.9400, 'high'),

  -- Receipt 7: Zara
  ('b1000000-0000-0000-0000-000000000007', 'a1000000-0000-0000-0000-000000000004', 'Cotton T-Shirt',            2, 990.00,  1980.00, 1980.00, 'Clothing & Fashion', 0.8500, 'high'),
  ('b1000000-0000-0000-0000-000000000007', 'a1000000-0000-0000-0000-000000000004', 'Slim Fit Jeans',            1, 1470.00, 1470.00, 1470.00, 'Clothing & Fashion', 0.7800, 'medium'),

  -- Receipt 8: Leopold Cafe
  ('b1000000-0000-0000-0000-000000000008', 'a1000000-0000-0000-0000-000000000004', 'Chicken Biryani',           1, 380.00,  380.00,  380.00,  'Food & Dining',      0.9500, 'high'),
  ('b1000000-0000-0000-0000-000000000008', 'a1000000-0000-0000-0000-000000000004', 'Mango Lassi',               2, 150.00,  300.00,  300.00,  'Food & Dining',      0.9300, 'high'),
  ('b1000000-0000-0000-0000-000000000008', 'a1000000-0000-0000-0000-000000000004', 'Chocolate Brownie',         1, 220.00,  220.00,  220.00,  'Food & Dining',      0.9100, 'high'),

  -- Receipt 9: Petrol Pump
  ('b1000000-0000-0000-0000-000000000009', 'a1000000-0000-0000-0000-000000000005', 'Petrol (Regular)',          25, 100.00, 2500.00, 2500.00, 'Transport',          0.9800, 'high'),

  -- Receipt 10: PVR Cinemas
  ('b1000000-0000-0000-0000-000000000010', 'a1000000-0000-0000-0000-000000000005', 'Movie Ticket x2',           2, 250.00,  500.00,  500.00,  'Entertainment',      0.8200, 'medium'),
  ('b1000000-0000-0000-0000-000000000010', 'a1000000-0000-0000-0000-000000000005', 'Large Popcorn Combo',       1, 280.00,  280.00,  280.00,  'Entertainment',      0.6500, 'medium'),

  -- Receipt 11: Lakme Salon
  ('b1000000-0000-0000-0000-000000000011', 'a1000000-0000-0000-0000-000000000006', 'Haircut & Styling',         1, 800.00,  800.00,  800.00,  'Personal Care',      0.9200, 'high'),
  ('b1000000-0000-0000-0000-000000000011', 'a1000000-0000-0000-0000-000000000006', 'Hair Spa Treatment',        1, 1000.00, 1000.00, 1000.00, 'Personal Care',      0.8400, 'medium'),

  -- Receipt 12: Domino's
  ('b1000000-0000-0000-0000-000000000012', 'a1000000-0000-0000-0000-000000000006', 'Peppy Paneer Pizza Medium', 1, 349.00,  349.00,  349.00,  'Takeout & Delivery', 0.9700, 'high'),
  ('b1000000-0000-0000-0000-000000000012', 'a1000000-0000-0000-0000-000000000006', 'Garlic Breadsticks',        1, 99.00,   99.00,   99.00,   'Takeout & Delivery', 0.9500, 'high'),
  ('b1000000-0000-0000-0000-000000000012', 'a1000000-0000-0000-0000-000000000006', 'Coke 500ml',                1, 59.00,   59.00,   59.00,   'Takeout & Delivery', 0.9600, 'high'),

  -- Receipt 13: Crossword Bookstore
  ('b1000000-0000-0000-0000-000000000013', 'a1000000-0000-0000-0000-000000000007', 'Atomic Habits (Book)',       1, 450.00,  450.00,  450.00,  'Education',          0.9300, 'high'),
  ('b1000000-0000-0000-0000-000000000013', 'a1000000-0000-0000-0000-000000000007', 'Notebook A5 Pack',           3, 80.00,   240.00,  240.00,  'Education',          0.9600, 'high'),
  ('b1000000-0000-0000-0000-000000000013', 'a1000000-0000-0000-0000-000000000007', 'Pilot V5 Pen Set',           1, 250.00,  250.00,  250.00,  'Education',          0.8900, 'high'),

  -- Receipt 14: Starbucks
  ('b1000000-0000-0000-0000-000000000014', 'a1000000-0000-0000-0000-000000000007', 'Caramel Frappuccino Venti', 1, 420.00,  420.00,  420.00,  'Food & Dining',      0.9500, 'high'),
  ('b1000000-0000-0000-0000-000000000014', 'a1000000-0000-0000-0000-000000000007', 'Blueberry Muffin',           1, 230.00,  230.00,  230.00,  'Food & Dining',      0.8700, 'high'),

  -- Receipt 15: Big Bazaar
  ('b1000000-0000-0000-0000-000000000015', 'a1000000-0000-0000-0000-000000000008', 'Basmati Rice 5kg',           1, 450.00,  450.00,  450.00,  'Groceries',          0.9400, 'high'),
  ('b1000000-0000-0000-0000-000000000015', 'a1000000-0000-0000-0000-000000000008', 'Maggi Family Pack',          2, 120.00,  240.00,  240.00,  'Groceries',          0.9100, 'high'),
  ('b1000000-0000-0000-0000-000000000015', 'a1000000-0000-0000-0000-000000000008', 'Vim Dishwash Bar',           4, 35.00,   140.00,  140.00,  'Home & Household',   0.8800, 'high'),
  ('b1000000-0000-0000-0000-000000000015', 'a1000000-0000-0000-0000-000000000008', 'Dove Soap Pack of 3',        1, 180.00,  180.00,  180.00,  'Personal Care',      0.8500, 'high'),

  -- Receipt 16: Wellness Forever
  ('b1000000-0000-0000-0000-000000000016', 'a1000000-0000-0000-0000-000000000008', 'Vitamin C Tablets',          1, 150.00,  150.00,  150.00,  'Health & Medicine',  0.9500, 'high'),
  ('b1000000-0000-0000-0000-000000000016', 'a1000000-0000-0000-0000-000000000008', 'ORS Sachets Pack',           1, 40.00,   40.00,   40.00,   'Health & Medicine',  0.9100, 'high'),
  ('b1000000-0000-0000-0000-000000000016', 'a1000000-0000-0000-0000-000000000008', 'Digital Thermometer',        1, 100.00,  100.00,  100.00,  'Health & Medicine',  0.8300, 'medium'),

  -- Receipt 17: Pantaloons
  ('b1000000-0000-0000-0000-000000000017', 'a1000000-0000-0000-0000-000000000009', 'Formal Shirt',               1, 1200.00, 1200.00, 1200.00, 'Clothing & Fashion', 0.8200, 'medium'),
  ('b1000000-0000-0000-0000-000000000017', 'a1000000-0000-0000-0000-000000000009', 'Chinos',                     1, 900.00,  900.00,  900.00,  'Clothing & Fashion', 0.7500, 'medium'),

  -- Receipt 18: Haldiram's
  ('b1000000-0000-0000-0000-000000000018', 'a1000000-0000-0000-0000-000000000009', 'Chole Bhature',              1, 180.00,  180.00,  180.00,  'Food & Dining',      0.9600, 'high'),
  ('b1000000-0000-0000-0000-000000000018', 'a1000000-0000-0000-0000-000000000009', 'Gulab Jamun (6pc)',           1, 120.00,  120.00,  120.00,  'Food & Dining',      0.9400, 'high'),
  ('b1000000-0000-0000-0000-000000000018', 'a1000000-0000-0000-0000-000000000009', 'Namkeen Mix 500g',           1, 190.00,  190.00,  190.00,  'Groceries',          0.8700, 'high'),

  -- Receipt 19: Vijay Sales
  ('b1000000-0000-0000-0000-000000000019', 'a1000000-0000-0000-0000-000000000010', 'LG Monitor 24"',             1, 8999.00, 8999.00, 8999.00, 'Electronics',        0.8800, 'high'),

  -- Receipt 20: IKEA
  ('b1000000-0000-0000-0000-000000000020', 'a1000000-0000-0000-0000-000000000010', 'KALLAX Shelf Unit',          1, 2999.00, 2999.00, 2999.00, 'Home & Household',   0.9200, 'high'),
  ('b1000000-0000-0000-0000-000000000020', 'a1000000-0000-0000-0000-000000000010', 'LED Desk Lamp',              1, 799.00,  799.00,  799.00,  'Home & Household',   0.9000, 'high'),
  ('b1000000-0000-0000-0000-000000000020', 'a1000000-0000-0000-0000-000000000010', 'Storage Box Set',            2, 349.00,  698.00,  698.00,  'Home & Household',   0.8800, 'high'),

  -- Receipt 21: Uber
  ('b1000000-0000-0000-0000-000000000021', 'a1000000-0000-0000-0000-000000000011', 'Uber Go Ride',               1, 245.00,  245.00,  245.00,  'Transport',          0.9900, 'high'),

  -- Receipt 22: Home Centre
  ('b1000000-0000-0000-0000-000000000022', 'a1000000-0000-0000-0000-000000000012', 'Bed Sheet Set',              1, 2500.00, 2500.00, 2500.00, 'Home & Household',   0.8500, 'high'),
  ('b1000000-0000-0000-0000-000000000022', 'a1000000-0000-0000-0000-000000000012', 'Cushion Covers Set of 5',    1, 1200.00, 1200.00, 1200.00, 'Home & Household',   0.8100, 'medium'),
  ('b1000000-0000-0000-0000-000000000022', 'a1000000-0000-0000-0000-000000000012', 'Table Runner',               1, 800.00,  800.00,  800.00,  'Home & Household',   0.7900, 'medium'),

  -- Receipt 23: MedPlus
  ('b1000000-0000-0000-0000-000000000023', 'a1000000-0000-0000-0000-000000000013', 'Paracetamol Strip',          2, 25.00,   50.00,   50.00,   'Health & Medicine',  0.9600, 'high'),
  ('b1000000-0000-0000-0000-000000000023', 'a1000000-0000-0000-0000-000000000013', 'Betadine Ointment',          1, 65.00,   65.00,   65.00,   'Health & Medicine',  0.8900, 'high'),
  ('b1000000-0000-0000-0000-000000000023', 'a1000000-0000-0000-0000-000000000013', 'Cotton Roll',                1, 60.00,   60.00,   60.00,   'Health & Medicine',  0.8700, 'high'),

  -- Receipt 24: Swiggy (low confidence — blurry receipt)
  ('b1000000-0000-0000-0000-000000000024', 'a1000000-0000-0000-0000-000000000014', 'Chicken Fried Rice',         1, 280.00,  280.00,  280.00,  'Takeout & Delivery', 0.5500, 'low'),
  ('b1000000-0000-0000-0000-000000000024', 'a1000000-0000-0000-0000-000000000014', 'Manchurian Gravy',           1, 240.00,  240.00,  240.00,  'Takeout & Delivery', 0.4800, 'low'),
  ('b1000000-0000-0000-0000-000000000024', 'a1000000-0000-0000-0000-000000000014', 'Delivery Fee',               1, 40.00,   40.00,   40.00,   'Takeout & Delivery', 0.5000, 'low'),

  -- Receipt 25: KFC
  ('b1000000-0000-0000-0000-000000000025', 'a1000000-0000-0000-0000-000000000015', 'Zinger Burger',              1, 199.00,  199.00,  199.00,  'Food & Dining',      0.9600, 'high'),
  ('b1000000-0000-0000-0000-000000000025', 'a1000000-0000-0000-0000-000000000015', 'Hot Wings 5pc',              1, 179.00,  179.00,  179.00,  'Food & Dining',      0.9400, 'high'),
  ('b1000000-0000-0000-0000-000000000025', 'a1000000-0000-0000-0000-000000000015', 'Pepsi Medium',               1, 79.00,   79.00,   79.00,   'Food & Dining',      0.9100, 'high')
ON CONFLICT DO NOTHING;


-- ─── Step 5: Seed user_trust_scores for 25 users ─────────
-- (Run this AFTER crowdtag-schema.sql has been run)

INSERT INTO user_trust_scores (user_id, trust_score, total_scans, correct_votes, incorrect_votes, accuracy_rate, tier) VALUES
  ('a1000000-0000-0000-0000-000000000001', 1.500, 45,  40,  5,  0.8889, 'experienced'),
  ('a1000000-0000-0000-0000-000000000002', 1.200, 30,  26,  4,  0.8667, 'experienced'),
  ('a1000000-0000-0000-0000-000000000003', 2.000, 120, 105, 15, 0.8750, 'validated'),
  ('a1000000-0000-0000-0000-000000000004', 0.800, 12,  9,   3,  0.7500, 'experienced'),
  ('a1000000-0000-0000-0000-000000000005', 1.800, 85,  78,  7,  0.9176, 'experienced'),
  ('a1000000-0000-0000-0000-000000000006', 2.500, 520, 490, 30, 0.9423, 'expert'),
  ('a1000000-0000-0000-0000-000000000007', 1.000, 18,  15,  3,  0.8333, 'experienced'),
  ('a1000000-0000-0000-0000-000000000008', 0.500, 5,   3,   2,  0.6000, 'new'),
  ('a1000000-0000-0000-0000-000000000009', 0.500, 8,   6,   2,  0.7500, 'new'),
  ('a1000000-0000-0000-0000-000000000010', 1.300, 38,  33,  5,  0.8684, 'experienced'),
  ('a1000000-0000-0000-0000-000000000011', 0.500, 3,   2,   1,  0.6667, 'new'),
  ('a1000000-0000-0000-0000-000000000012', 0.700, 10,  7,   3,  0.7000, 'experienced'),
  ('a1000000-0000-0000-0000-000000000013', 1.100, 22,  19,  3,  0.8636, 'experienced'),
  ('a1000000-0000-0000-0000-000000000014', 0.500, 2,   1,   1,  0.5000, 'new'),
  ('a1000000-0000-0000-0000-000000000015', 0.900, 15,  13,  2,  0.8667, 'experienced'),
  ('a1000000-0000-0000-0000-000000000016', 0.500, 4,   3,   1,  0.7500, 'new'),
  ('a1000000-0000-0000-0000-000000000017', 1.400, 42,  37,  5,  0.8810, 'experienced'),
  ('a1000000-0000-0000-0000-000000000018', 0.500, 1,   1,   0,  1.0000, 'new'),
  ('a1000000-0000-0000-0000-000000000019', 0.600, 9,   6,   3,  0.6667, 'new'),
  ('a1000000-0000-0000-0000-000000000020', 2.000, 110, 98,  12, 0.8909, 'validated'),
  ('a1000000-0000-0000-0000-000000000021', 0.500, 6,   5,   1,  0.8333, 'new'),
  ('a1000000-0000-0000-0000-000000000022', 0.500, 7,   5,   2,  0.7143, 'new'),
  ('a1000000-0000-0000-0000-000000000023', 1.600, 55,  50,  5,  0.9091, 'experienced'),
  ('a1000000-0000-0000-0000-000000000024', 0.500, 4,   2,   2,  0.5000, 'new'),
  ('a1000000-0000-0000-0000-000000000025', 2.500, 999, 950, 49, 0.9509, 'expert')
ON CONFLICT (user_id) DO NOTHING;


-- ─── Step 6: Seed crowdtag_events ────────────────────────

INSERT INTO crowdtag_events (event_type, merchant_key, payload, created_at) VALUES
  ('merchant_seeded',   'dmart_pune',           '{"category":"Groceries","source":"hardcoded"}'::jsonb,                          NOW() - INTERVAL '20 days'),
  ('merchant_seeded',   'mcdonalds_pune',       '{"category":"Food & Dining","source":"hardcoded"}'::jsonb,                      NOW() - INTERVAL '20 days'),
  ('merchant_seeded',   'apollo_pharmacy_pune', '{"category":"Health & Medicine","source":"hardcoded"}'::jsonb,                  NOW() - INTERVAL '20 days'),
  ('vote_logged',       'dmart_pune',           '{"category":"Groceries","confidence":0.95,"is_manual":false}'::jsonb,           NOW() - INTERVAL '15 days'),
  ('vote_logged',       'dmart_pune',           '{"category":"Groceries","confidence":0.92,"is_manual":false}'::jsonb,           NOW() - INTERVAL '14 days'),
  ('vote_logged',       'mcdonalds_pune',       '{"category":"Food & Dining","confidence":0.98,"is_manual":false}'::jsonb,       NOW() - INTERVAL '12 days'),
  ('vote_logged',       'dmart_pune',           '{"category":"Groceries","confidence":0.97,"is_manual":false}'::jsonb,           NOW() - INTERVAL '10 days'),
  ('merchant_resolved', 'dmart_pune',           '{"dominant_category":"Groceries","confidence":0.94,"total_votes":35}'::jsonb,   NOW() - INTERVAL '10 days'),
  ('vote_logged',       'mcdonalds_pune',       '{"category":"Food & Dining","confidence":0.96,"is_manual":true}'::jsonb,        NOW() - INTERVAL '8 days'),
  ('merchant_resolved', 'mcdonalds_pune',       '{"dominant_category":"Food & Dining","confidence":0.97,"total_votes":32}'::jsonb, NOW() - INTERVAL '7 days'),
  ('vote_logged',       'croma_pune',           '{"category":"Electronics","confidence":0.93,"is_manual":false}'::jsonb,          NOW() - INTERVAL '6 days'),
  ('vote_logged',       'croma_pune',           '{"category":"Electronics","confidence":0.91,"is_manual":false}'::jsonb,          NOW() - INTERVAL '5 days'),
  ('vote_logged',       'zara_mumbai',          '{"category":"Clothing & Fashion","confidence":0.81,"is_manual":false}'::jsonb,   NOW() - INTERVAL '4 days'),
  ('vote_logged',       'leopold_cafe_mumbai',  '{"category":"Food & Dining","confidence":0.94,"is_manual":false}'::jsonb,        NOW() - INTERVAL '3 days'),
  ('drift_detected',    'big_bazaar_nagpur',    '{"previous_category":"Groceries","contra_votes":8,"threshold":6}'::jsonb,        NOW() - INTERVAL '2 days'),
  ('vote_logged',       'swiggy_mumbai',        '{"category":"Takeout & Delivery","confidence":0.52,"is_manual":false}'::jsonb,   NOW() - INTERVAL '1 day'),
  ('merchant_seeded',   'reliance_fresh_nashik','{"category":"Groceries","source":"hardcoded"}'::jsonb,                           NOW() - INTERVAL '20 days'),
  ('vote_logged',       'lakme_salon_pune',     '{"category":"Personal Care","confidence":0.86,"is_manual":false}'::jsonb,        NOW() - INTERVAL '3 days'),
  ('merchant_resolved', 'apollo_pharmacy_pune', '{"dominant_category":"Health & Medicine","confidence":0.91,"total_votes":28}'::jsonb, NOW() - INTERVAL '5 days'),
  ('vote_logged',       'uber_pune',            '{"category":"Transport","confidence":0.99,"is_manual":false}'::jsonb,             NOW() - INTERVAL '1 day'),
  ('vote_logged',       'pvr_cinemas_pune',     '{"category":"Entertainment","confidence":0.72,"is_manual":false}'::jsonb,         NOW() - INTERVAL '6 days'),
  ('vote_logged',       'crossword_bookstore_pune', '{"category":"Education","confidence":0.92,"is_manual":false}'::jsonb,         NOW() - INTERVAL '8 days'),
  ('vote_logged',       'ikea_mumbai',          '{"category":"Home & Household","confidence":0.91,"is_manual":false}'::jsonb,      NOW() - INTERVAL '1 day'),
  ('vote_logged',       'dominos_pizza_pune',   '{"category":"Takeout & Delivery","confidence":0.96,"is_manual":false}'::jsonb,    NOW() - INTERVAL '1 day'),
  ('merchant_resolved', 'dominos_pizza_pune',   '{"dominant_category":"Takeout & Delivery","confidence":0.95,"total_votes":40}'::jsonb, NOW() - INTERVAL '1 day')
ON CONFLICT DO NOTHING;


-- ═══════════════════════════════════════════════════════════
-- VERIFY SEED DATA
-- ═══════════════════════════════════════════════════════════
-- SELECT 'profiles' AS tbl, COUNT(*) FROM profiles
-- UNION ALL SELECT 'receipts', COUNT(*) FROM receipts
-- UNION ALL SELECT 'line_items', COUNT(*) FROM line_items
-- UNION ALL SELECT 'categories', COUNT(*) FROM categories
-- UNION ALL SELECT 'user_trust_scores', COUNT(*) FROM user_trust_scores
-- UNION ALL SELECT 'crowdtag_events', COUNT(*) FROM crowdtag_events;
