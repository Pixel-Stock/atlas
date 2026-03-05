/**
 * ATLAS CrowdTag — Hardcoded Maharashtra Merchant Seeder
 * =======================================================
 * Zero API cost. Zero external dependencies.
 * Seeds ~400 real merchants across 8 Maharashtra cities.
 *
 * Cities covered:
 *   Pune, Mumbai, Nagpur, Nashik, Aurangabad,
 *   Thane, Kolhapur, Solapur
 *
 * Usage:
 *   SUPABASE_URL=your_url \
 *   SUPABASE_SERVICE_ROLE_KEY=your_key \
 *   npx tsx scripts/seed-maharashtra.ts
 *
 * Safe to re-run — uses ON CONFLICT DO NOTHING.
 * Never overwrites real user votes.
 */

import { createClient } from "@supabase/supabase-js";

const SUPABASE_URL = process.env.SUPABASE_URL ?? process.env.NEXT_PUBLIC_SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
    console.error("❌  Missing env vars: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required.");
    process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

// ─────────────────────────────────────────────
// TYPES
// ─────────────────────────────────────────────

interface MerchantSeed {
    name: string;
    city: string;
    category: string;
}

// ─────────────────────────────────────────────
// THE DATASET — 400+ REAL MAHARASHTRA MERCHANTS
// ─────────────────────────────────────────────

const MERCHANTS: MerchantSeed[] = [

    // ══════════════════════════════════════════
    // PUNE
    // ══════════════════════════════════════════

    // Groceries & Supermarkets
    { name: "D-Mart", city: "Pune", category: "Groceries" },
    { name: "Reliance Fresh", city: "Pune", category: "Groceries" },
    { name: "Big Bazaar", city: "Pune", category: "Groceries" },
    { name: "More Supermarket", city: "Pune", category: "Groceries" },
    { name: "Star Bazaar", city: "Pune", category: "Groceries" },
    { name: "Spencer's Retail", city: "Pune", category: "Groceries" },
    { name: "Ratnadeep Supermarket", city: "Pune", category: "Groceries" },
    { name: "Dorabjee's", city: "Pune", category: "Groceries" },
    { name: "Hypercity", city: "Pune", category: "Groceries" },
    { name: "Heritage Fresh", city: "Pune", category: "Groceries" },
    { name: "Spar Hypermarket", city: "Pune", category: "Groceries" },
    { name: "Nature's Basket", city: "Pune", category: "Groceries" },
    { name: "Godrej Nature's Basket", city: "Pune", category: "Groceries" },
    { name: "Nilgiris", city: "Pune", category: "Groceries" },

    // Food & Dining
    { name: "Vaishali Restaurant", city: "Pune", category: "Food & Dining" },
    { name: "Irani Cafe", city: "Pune", category: "Food & Dining" },
    { name: "Cafe Good Luck", city: "Pune", category: "Food & Dining" },
    { name: "Malaka Spice", city: "Pune", category: "Food & Dining" },
    { name: "The Flour Works", city: "Pune", category: "Food & Dining" },
    { name: "Vohuman Cafe", city: "Pune", category: "Food & Dining" },
    { name: "Hotel Shreyas", city: "Pune", category: "Food & Dining" },
    { name: "Chitale Bandhu Mithaiwale", city: "Pune", category: "Food & Dining" },
    { name: "Cafe Peter", city: "Pune", category: "Food & Dining" },
    { name: "Kayani Bakery", city: "Pune", category: "Food & Dining" },
    { name: "Cafe Goodluck", city: "Pune", category: "Food & Dining" },
    { name: "McDonald's", city: "Pune", category: "Food & Dining" },
    { name: "KFC", city: "Pune", category: "Food & Dining" },
    { name: "Subway", city: "Pune", category: "Food & Dining" },
    { name: "Pizza Hut", city: "Pune", category: "Food & Dining" },
    { name: "Burger King", city: "Pune", category: "Food & Dining" },
    { name: "Barbeque Nation", city: "Pune", category: "Food & Dining" },
    { name: "Social", city: "Pune", category: "Food & Dining" },
    { name: "Mainland China", city: "Pune", category: "Food & Dining" },
    { name: "The Great Kabab Factory", city: "Pune", category: "Food & Dining" },

    // Takeout & Delivery
    { name: "Domino's Pizza", city: "Pune", category: "Takeout & Delivery" },
    { name: "Pizza Hut Delivery", city: "Pune", category: "Takeout & Delivery" },
    { name: "Box8", city: "Pune", category: "Takeout & Delivery" },
    { name: "Faasos", city: "Pune", category: "Takeout & Delivery" },
    { name: "Rebel Foods", city: "Pune", category: "Takeout & Delivery" },
    { name: "Behrouz Biryani", city: "Pune", category: "Takeout & Delivery" },
    { name: "Oven Story", city: "Pune", category: "Takeout & Delivery" },
    { name: "Biryani By Kilo", city: "Pune", category: "Takeout & Delivery" },
    { name: "Swiggy", city: "Pune", category: "Takeout & Delivery" },
    { name: "Zomato", city: "Pune", category: "Takeout & Delivery" },

    // Health & Medicine
    { name: "Apollo Pharmacy", city: "Pune", category: "Health & Medicine" },
    { name: "MedPlus", city: "Pune", category: "Health & Medicine" },
    { name: "Wellness Forever", city: "Pune", category: "Health & Medicine" },
    { name: "Netmeds", city: "Pune", category: "Health & Medicine" },
    { name: "1mg", city: "Pune", category: "Health & Medicine" },
    { name: "Sahyadri Hospital", city: "Pune", category: "Health & Medicine" },
    { name: "Ruby Hall Clinic", city: "Pune", category: "Health & Medicine" },
    { name: "KEM Hospital", city: "Pune", category: "Health & Medicine" },
    { name: "Jehangir Hospital", city: "Pune", category: "Health & Medicine" },
    { name: "Noble Hospital", city: "Pune", category: "Health & Medicine" },
    { name: "Deenanath Mangeshkar Hospital", city: "Pune", category: "Health & Medicine" },
    { name: "Oyster & Pearl Hospital", city: "Pune", category: "Health & Medicine" },

    // Personal Care
    { name: "Looks Salon", city: "Pune", category: "Personal Care" },
    { name: "Enrich Salon", city: "Pune", category: "Personal Care" },
    { name: "VLCC", city: "Pune", category: "Personal Care" },
    { name: "Naturals Salon", city: "Pune", category: "Personal Care" },
    { name: "Lakme Salon", city: "Pune", category: "Personal Care" },
    { name: "Green Trends", city: "Pune", category: "Personal Care" },
    { name: "Jawed Habib", city: "Pune", category: "Personal Care" },
    { name: "Truefitt & Hill", city: "Pune", category: "Personal Care" },

    // Electronics
    { name: "Croma", city: "Pune", category: "Electronics" },
    { name: "Reliance Digital", city: "Pune", category: "Electronics" },
    { name: "Vijay Sales", city: "Pune", category: "Electronics" },
    { name: "Apple Store Authorized", city: "Pune", category: "Electronics" },
    { name: "Samsung SmartCafe", city: "Pune", category: "Electronics" },
    { name: "OnePlus Experience Store", city: "Pune", category: "Electronics" },
    { name: "Poorvika Mobiles", city: "Pune", category: "Electronics" },
    { name: "Sangeetha Mobiles", city: "Pune", category: "Electronics" },

    // Clothing & Fashion
    { name: "Westside", city: "Pune", category: "Clothing & Fashion" },
    { name: "Pantaloons", city: "Pune", category: "Clothing & Fashion" },
    { name: "Lifestyle", city: "Pune", category: "Clothing & Fashion" },
    { name: "Shoppers Stop", city: "Pune", category: "Clothing & Fashion" },
    { name: "Zara", city: "Pune", category: "Clothing & Fashion" },
    { name: "H&M", city: "Pune", category: "Clothing & Fashion" },
    { name: "Max Fashion", city: "Pune", category: "Clothing & Fashion" },
    { name: "FBB", city: "Pune", category: "Clothing & Fashion" },
    { name: "Fabindia", city: "Pune", category: "Clothing & Fashion" },
    { name: "Raymond", city: "Pune", category: "Clothing & Fashion" },
    { name: "Peter England", city: "Pune", category: "Clothing & Fashion" },

    // Transport
    { name: "Indian Oil Petrol Pump", city: "Pune", category: "Transport" },
    { name: "HPCL Petrol Pump", city: "Pune", category: "Transport" },
    { name: "BPCL Petrol Pump", city: "Pune", category: "Transport" },
    { name: "Shell Petrol Station", city: "Pune", category: "Transport" },
    { name: "Ola Auto", city: "Pune", category: "Transport" },
    { name: "Uber", city: "Pune", category: "Transport" },
    { name: "Rapido", city: "Pune", category: "Transport" },
    { name: "PMPML Bus", city: "Pune", category: "Transport" },

    // Entertainment
    { name: "PVR Cinemas", city: "Pune", category: "Entertainment" },
    { name: "INOX", city: "Pune", category: "Entertainment" },
    { name: "Cinepolis", city: "Pune", category: "Entertainment" },
    { name: "City Pride Multiplex", city: "Pune", category: "Entertainment" },
    { name: "E-Square Multiplex", city: "Pune", category: "Entertainment" },
    { name: "Gold's Gym", city: "Pune", category: "Entertainment" },
    { name: "Anytime Fitness", city: "Pune", category: "Entertainment" },
    { name: "Cult.fit", city: "Pune", category: "Entertainment" },

    // Home & Household
    { name: "IKEA", city: "Pune", category: "Home & Household" },
    { name: "Home Centre", city: "Pune", category: "Home & Household" },
    { name: "Nilkamal", city: "Pune", category: "Home & Household" },
    { name: "Durian Furniture", city: "Pune", category: "Home & Household" },
    { name: "HomeTown", city: "Pune", category: "Home & Household" },
    { name: "Godrej Interio", city: "Pune", category: "Home & Household" },
    { name: "Urban Ladder", city: "Pune", category: "Home & Household" },

    // Education
    { name: "BYJU'S Learning Centre", city: "Pune", category: "Education" },
    { name: "Crossword Bookstore", city: "Pune", category: "Education" },
    { name: "Landmark Books", city: "Pune", category: "Education" },
    { name: "Akash Institute", city: "Pune", category: "Education" },
    { name: "TIME Institute", city: "Pune", category: "Education" },


    // ══════════════════════════════════════════
    // MUMBAI
    // ══════════════════════════════════════════

    // Groceries
    { name: "D-Mart", city: "Mumbai", category: "Groceries" },
    { name: "Reliance Smart", city: "Mumbai", category: "Groceries" },
    { name: "Big Bazaar", city: "Mumbai", category: "Groceries" },
    { name: "Star Bazaar", city: "Mumbai", category: "Groceries" },
    { name: "Nature's Basket", city: "Mumbai", category: "Groceries" },
    { name: "Hypercity", city: "Mumbai", category: "Groceries" },
    { name: "Spencer's Retail", city: "Mumbai", category: "Groceries" },
    { name: "Spar Hypermarket", city: "Mumbai", category: "Groceries" },
    { name: "Heritage Fresh", city: "Mumbai", category: "Groceries" },

    // Food & Dining
    { name: "Leopold Cafe", city: "Mumbai", category: "Food & Dining" },
    { name: "Cafe Mondegar", city: "Mumbai", category: "Food & Dining" },
    { name: "Britannia & Co", city: "Mumbai", category: "Food & Dining" },
    { name: "Trishna", city: "Mumbai", category: "Food & Dining" },
    { name: "Khyber", city: "Mumbai", category: "Food & Dining" },
    { name: "Copper Chimney", city: "Mumbai", category: "Food & Dining" },
    { name: "Status Restaurant", city: "Mumbai", category: "Food & Dining" },
    { name: "Sardar Pav Bhaji", city: "Mumbai", category: "Food & Dining" },
    { name: "Juhu Beach Stalls", city: "Mumbai", category: "Food & Dining" },
    { name: "McDonald's", city: "Mumbai", category: "Food & Dining" },
    { name: "KFC", city: "Mumbai", category: "Food & Dining" },
    { name: "Burger King", city: "Mumbai", category: "Food & Dining" },
    { name: "Pizza Hut", city: "Mumbai", category: "Food & Dining" },
    { name: "Subway", city: "Mumbai", category: "Food & Dining" },
    { name: "Barbeque Nation", city: "Mumbai", category: "Food & Dining" },
    { name: "Social", city: "Mumbai", category: "Food & Dining" },
    { name: "Hard Rock Cafe", city: "Mumbai", category: "Food & Dining" },
    { name: "Starbucks", city: "Mumbai", category: "Food & Dining" },
    { name: "Chaayos", city: "Mumbai", category: "Food & Dining" },
    { name: "Third Wave Coffee", city: "Mumbai", category: "Food & Dining" },

    // Takeout & Delivery
    { name: "Domino's Pizza", city: "Mumbai", category: "Takeout & Delivery" },
    { name: "Faasos", city: "Mumbai", category: "Takeout & Delivery" },
    { name: "Box8", city: "Mumbai", category: "Takeout & Delivery" },
    { name: "Behrouz Biryani", city: "Mumbai", category: "Takeout & Delivery" },
    { name: "Biryani By Kilo", city: "Mumbai", category: "Takeout & Delivery" },
    { name: "Oven Story", city: "Mumbai", category: "Takeout & Delivery" },
    { name: "Swiggy", city: "Mumbai", category: "Takeout & Delivery" },
    { name: "Zomato", city: "Mumbai", category: "Takeout & Delivery" },

    // Health & Medicine
    { name: "Apollo Pharmacy", city: "Mumbai", category: "Health & Medicine" },
    { name: "MedPlus", city: "Mumbai", category: "Health & Medicine" },
    { name: "Wellness Forever", city: "Mumbai", category: "Health & Medicine" },
    { name: "Lilavati Hospital", city: "Mumbai", category: "Health & Medicine" },
    { name: "Kokilaben Hospital", city: "Mumbai", category: "Health & Medicine" },
    { name: "Hinduja Hospital", city: "Mumbai", category: "Health & Medicine" },
    { name: "Breach Candy Hospital", city: "Mumbai", category: "Health & Medicine" },
    { name: "Nanavati Hospital", city: "Mumbai", category: "Health & Medicine" },
    { name: "Fortis Hospital", city: "Mumbai", category: "Health & Medicine" },
    { name: "Netmeds", city: "Mumbai", category: "Health & Medicine" },

    // Personal Care
    { name: "Lakme Salon", city: "Mumbai", category: "Personal Care" },
    { name: "Enrich Salon", city: "Mumbai", category: "Personal Care" },
    { name: "VLCC", city: "Mumbai", category: "Personal Care" },
    { name: "Naturals Salon", city: "Mumbai", category: "Personal Care" },
    { name: "Jawed Habib", city: "Mumbai", category: "Personal Care" },
    { name: "Looks Salon", city: "Mumbai", category: "Personal Care" },

    // Electronics
    { name: "Croma", city: "Mumbai", category: "Electronics" },
    { name: "Reliance Digital", city: "Mumbai", category: "Electronics" },
    { name: "Vijay Sales", city: "Mumbai", category: "Electronics" },
    { name: "Apple Authorized Reseller", city: "Mumbai", category: "Electronics" },
    { name: "Samsung SmartCafe", city: "Mumbai", category: "Electronics" },
    { name: "iStore", city: "Mumbai", category: "Electronics" },

    // Clothing & Fashion
    { name: "Zara", city: "Mumbai", category: "Clothing & Fashion" },
    { name: "H&M", city: "Mumbai", category: "Clothing & Fashion" },
    { name: "Shoppers Stop", city: "Mumbai", category: "Clothing & Fashion" },
    { name: "Lifestyle", city: "Mumbai", category: "Clothing & Fashion" },
    { name: "Pantaloons", city: "Mumbai", category: "Clothing & Fashion" },
    { name: "Westside", city: "Mumbai", category: "Clothing & Fashion" },
    { name: "Fabindia", city: "Mumbai", category: "Clothing & Fashion" },
    { name: "Mango", city: "Mumbai", category: "Clothing & Fashion" },
    { name: "United Colors of Benetton", city: "Mumbai", category: "Clothing & Fashion" },

    // Transport
    { name: "Indian Oil Petrol Pump", city: "Mumbai", category: "Transport" },
    { name: "HPCL Petrol Pump", city: "Mumbai", category: "Transport" },
    { name: "BPCL Petrol Pump", city: "Mumbai", category: "Transport" },
    { name: "Ola", city: "Mumbai", category: "Transport" },
    { name: "Uber", city: "Mumbai", category: "Transport" },
    { name: "Rapido", city: "Mumbai", category: "Transport" },
    { name: "BEST Bus", city: "Mumbai", category: "Transport" },
    { name: "Mumbai Metro", city: "Mumbai", category: "Transport" },

    // Entertainment
    { name: "PVR Cinemas", city: "Mumbai", category: "Entertainment" },
    { name: "INOX", city: "Mumbai", category: "Entertainment" },
    { name: "Cinepolis", city: "Mumbai", category: "Entertainment" },
    { name: "Gold's Gym", city: "Mumbai", category: "Entertainment" },
    { name: "Cult.fit", city: "Mumbai", category: "Entertainment" },
    { name: "Anytime Fitness", city: "Mumbai", category: "Entertainment" },

    // Home & Household
    { name: "IKEA", city: "Mumbai", category: "Home & Household" },
    { name: "Home Centre", city: "Mumbai", category: "Home & Household" },
    { name: "HomeTown", city: "Mumbai", category: "Home & Household" },
    { name: "Nilkamal", city: "Mumbai", category: "Home & Household" },
    { name: "Godrej Interio", city: "Mumbai", category: "Home & Household" },


    // ══════════════════════════════════════════
    // NAGPUR
    // ══════════════════════════════════════════

    { name: "D-Mart", city: "Nagpur", category: "Groceries" },
    { name: "Reliance Fresh", city: "Nagpur", category: "Groceries" },
    { name: "Big Bazaar", city: "Nagpur", category: "Groceries" },
    { name: "More Supermarket", city: "Nagpur", category: "Groceries" },
    { name: "Variety Store", city: "Nagpur", category: "Groceries" },
    { name: "Haldiram's", city: "Nagpur", category: "Food & Dining" },
    { name: "McDonald's", city: "Nagpur", category: "Food & Dining" },
    { name: "KFC", city: "Nagpur", category: "Food & Dining" },
    { name: "Domino's Pizza", city: "Nagpur", category: "Takeout & Delivery" },
    { name: "Pizza Hut", city: "Nagpur", category: "Food & Dining" },
    { name: "Burger King", city: "Nagpur", category: "Food & Dining" },
    { name: "Apollo Pharmacy", city: "Nagpur", category: "Health & Medicine" },
    { name: "MedPlus", city: "Nagpur", category: "Health & Medicine" },
    { name: "Wellness Forever", city: "Nagpur", category: "Health & Medicine" },
    { name: "Orange City Hospital", city: "Nagpur", category: "Health & Medicine" },
    { name: "Wockhardt Hospital", city: "Nagpur", category: "Health & Medicine" },
    { name: "Croma", city: "Nagpur", category: "Electronics" },
    { name: "Reliance Digital", city: "Nagpur", category: "Electronics" },
    { name: "Vijay Sales", city: "Nagpur", category: "Electronics" },
    { name: "Shoppers Stop", city: "Nagpur", category: "Clothing & Fashion" },
    { name: "Pantaloons", city: "Nagpur", category: "Clothing & Fashion" },
    { name: "Lifestyle", city: "Nagpur", category: "Clothing & Fashion" },
    { name: "Max Fashion", city: "Nagpur", category: "Clothing & Fashion" },
    { name: "Indian Oil Petrol Pump", city: "Nagpur", category: "Transport" },
    { name: "HPCL Petrol Pump", city: "Nagpur", category: "Transport" },
    { name: "Ola", city: "Nagpur", category: "Transport" },
    { name: "Uber", city: "Nagpur", category: "Transport" },
    { name: "PVR Cinemas", city: "Nagpur", category: "Entertainment" },
    { name: "Inox", city: "Nagpur", category: "Entertainment" },
    { name: "Lakme Salon", city: "Nagpur", category: "Personal Care" },
    { name: "VLCC", city: "Nagpur", category: "Personal Care" },
    { name: "Home Centre", city: "Nagpur", category: "Home & Household" },
    { name: "Nilkamal", city: "Nagpur", category: "Home & Household" },


    // ══════════════════════════════════════════
    // NASHIK
    // ══════════════════════════════════════════

    { name: "D-Mart", city: "Nashik", category: "Groceries" },
    { name: "Reliance Fresh", city: "Nashik", category: "Groceries" },
    { name: "Big Bazaar", city: "Nashik", category: "Groceries" },
    { name: "More Supermarket", city: "Nashik", category: "Groceries" },
    { name: "McDonald's", city: "Nashik", category: "Food & Dining" },
    { name: "KFC", city: "Nashik", category: "Food & Dining" },
    { name: "Domino's Pizza", city: "Nashik", category: "Takeout & Delivery" },
    { name: "Subway", city: "Nashik", category: "Food & Dining" },
    { name: "Burger King", city: "Nashik", category: "Food & Dining" },
    { name: "Apollo Pharmacy", city: "Nashik", category: "Health & Medicine" },
    { name: "MedPlus", city: "Nashik", category: "Health & Medicine" },
    { name: "Wellness Forever", city: "Nashik", category: "Health & Medicine" },
    { name: "Croma", city: "Nashik", category: "Electronics" },
    { name: "Reliance Digital", city: "Nashik", category: "Electronics" },
    { name: "Pantaloons", city: "Nashik", category: "Clothing & Fashion" },
    { name: "Lifestyle", city: "Nashik", category: "Clothing & Fashion" },
    { name: "Max Fashion", city: "Nashik", category: "Clothing & Fashion" },
    { name: "Indian Oil Petrol Pump", city: "Nashik", category: "Transport" },
    { name: "HPCL Petrol Pump", city: "Nashik", category: "Transport" },
    { name: "Ola", city: "Nashik", category: "Transport" },
    { name: "PVR Cinemas", city: "Nashik", category: "Entertainment" },
    { name: "Lakme Salon", city: "Nashik", category: "Personal Care" },
    { name: "Naturals Salon", city: "Nashik", category: "Personal Care" },
    { name: "Home Centre", city: "Nashik", category: "Home & Household" },


    // ══════════════════════════════════════════
    // AURANGABAD (Chhatrapati Sambhajinagar)
    // ══════════════════════════════════════════

    { name: "D-Mart", city: "Aurangabad", category: "Groceries" },
    { name: "Reliance Fresh", city: "Aurangabad", category: "Groceries" },
    { name: "Big Bazaar", city: "Aurangabad", category: "Groceries" },
    { name: "More Supermarket", city: "Aurangabad", category: "Groceries" },
    { name: "McDonald's", city: "Aurangabad", category: "Food & Dining" },
    { name: "KFC", city: "Aurangabad", category: "Food & Dining" },
    { name: "Domino's Pizza", city: "Aurangabad", category: "Takeout & Delivery" },
    { name: "Subway", city: "Aurangabad", category: "Food & Dining" },
    { name: "Hotel Nandanvan", city: "Aurangabad", category: "Food & Dining" },
    { name: "Apollo Pharmacy", city: "Aurangabad", category: "Health & Medicine" },
    { name: "MedPlus", city: "Aurangabad", category: "Health & Medicine" },
    { name: "Government Medical College", city: "Aurangabad", category: "Health & Medicine" },
    { name: "Croma", city: "Aurangabad", category: "Electronics" },
    { name: "Reliance Digital", city: "Aurangabad", category: "Electronics" },
    { name: "Pantaloons", city: "Aurangabad", category: "Clothing & Fashion" },
    { name: "Max Fashion", city: "Aurangabad", category: "Clothing & Fashion" },
    { name: "Indian Oil Petrol Pump", city: "Aurangabad", category: "Transport" },
    { name: "HPCL Petrol Pump", city: "Aurangabad", category: "Transport" },
    { name: "Ola", city: "Aurangabad", category: "Transport" },
    { name: "Cinepolis", city: "Aurangabad", category: "Entertainment" },
    { name: "Lakme Salon", city: "Aurangabad", category: "Personal Care" },


    // ══════════════════════════════════════════
    // THANE
    // ══════════════════════════════════════════

    { name: "D-Mart", city: "Thane", category: "Groceries" },
    { name: "Reliance Fresh", city: "Thane", category: "Groceries" },
    { name: "Big Bazaar", city: "Thane", category: "Groceries" },
    { name: "Star Bazaar", city: "Thane", category: "Groceries" },
    { name: "More Supermarket", city: "Thane", category: "Groceries" },
    { name: "McDonald's", city: "Thane", category: "Food & Dining" },
    { name: "KFC", city: "Thane", category: "Food & Dining" },
    { name: "Domino's Pizza", city: "Thane", category: "Takeout & Delivery" },
    { name: "Pizza Hut", city: "Thane", category: "Food & Dining" },
    { name: "Burger King", city: "Thane", category: "Food & Dining" },
    { name: "Subway", city: "Thane", category: "Food & Dining" },
    { name: "Barbeque Nation", city: "Thane", category: "Food & Dining" },
    { name: "Chaayos", city: "Thane", category: "Food & Dining" },
    { name: "Apollo Pharmacy", city: "Thane", category: "Health & Medicine" },
    { name: "MedPlus", city: "Thane", category: "Health & Medicine" },
    { name: "Wellness Forever", city: "Thane", category: "Health & Medicine" },
    { name: "Fortis Hospital", city: "Thane", category: "Health & Medicine" },
    { name: "Jupiter Hospital", city: "Thane", category: "Health & Medicine" },
    { name: "Croma", city: "Thane", category: "Electronics" },
    { name: "Reliance Digital", city: "Thane", category: "Electronics" },
    { name: "Vijay Sales", city: "Thane", category: "Electronics" },
    { name: "Shoppers Stop", city: "Thane", category: "Clothing & Fashion" },
    { name: "Pantaloons", city: "Thane", category: "Clothing & Fashion" },
    { name: "Lifestyle", city: "Thane", category: "Clothing & Fashion" },
    { name: "Zara", city: "Thane", category: "Clothing & Fashion" },
    { name: "H&M", city: "Thane", category: "Clothing & Fashion" },
    { name: "Indian Oil Petrol Pump", city: "Thane", category: "Transport" },
    { name: "HPCL Petrol Pump", city: "Thane", category: "Transport" },
    { name: "Ola", city: "Thane", category: "Transport" },
    { name: "Uber", city: "Thane", category: "Transport" },
    { name: "PVR Cinemas", city: "Thane", category: "Entertainment" },
    { name: "INOX", city: "Thane", category: "Entertainment" },
    { name: "Gold's Gym", city: "Thane", category: "Entertainment" },
    { name: "Cult.fit", city: "Thane", category: "Entertainment" },
    { name: "Lakme Salon", city: "Thane", category: "Personal Care" },
    { name: "Enrich Salon", city: "Thane", category: "Personal Care" },
    { name: "Home Centre", city: "Thane", category: "Home & Household" },
    { name: "HomeTown", city: "Thane", category: "Home & Household" },
    { name: "IKEA", city: "Thane", category: "Home & Household" },


    // ══════════════════════════════════════════
    // KOLHAPUR
    // ══════════════════════════════════════════

    { name: "D-Mart", city: "Kolhapur", category: "Groceries" },
    { name: "Reliance Fresh", city: "Kolhapur", category: "Groceries" },
    { name: "Big Bazaar", city: "Kolhapur", category: "Groceries" },
    { name: "More Supermarket", city: "Kolhapur", category: "Groceries" },
    { name: "McDonald's", city: "Kolhapur", category: "Food & Dining" },
    { name: "KFC", city: "Kolhapur", category: "Food & Dining" },
    { name: "Domino's Pizza", city: "Kolhapur", category: "Takeout & Delivery" },
    { name: "Hotel Opal", city: "Kolhapur", category: "Food & Dining" },
    { name: "Padma Guest House", city: "Kolhapur", category: "Food & Dining" },
    { name: "Apollo Pharmacy", city: "Kolhapur", category: "Health & Medicine" },
    { name: "MedPlus", city: "Kolhapur", category: "Health & Medicine" },
    { name: "CPR Hospital", city: "Kolhapur", category: "Health & Medicine" },
    { name: "Croma", city: "Kolhapur", category: "Electronics" },
    { name: "Reliance Digital", city: "Kolhapur", category: "Electronics" },
    { name: "Pantaloons", city: "Kolhapur", category: "Clothing & Fashion" },
    { name: "Max Fashion", city: "Kolhapur", category: "Clothing & Fashion" },
    { name: "Indian Oil Petrol Pump", city: "Kolhapur", category: "Transport" },
    { name: "HPCL Petrol Pump", city: "Kolhapur", category: "Transport" },
    { name: "PVR Cinemas", city: "Kolhapur", category: "Entertainment" },
    { name: "Lakme Salon", city: "Kolhapur", category: "Personal Care" },
    { name: "Home Centre", city: "Kolhapur", category: "Home & Household" },


    // ══════════════════════════════════════════
    // SOLAPUR
    // ══════════════════════════════════════════

    { name: "D-Mart", city: "Solapur", category: "Groceries" },
    { name: "Reliance Fresh", city: "Solapur", category: "Groceries" },
    { name: "Big Bazaar", city: "Solapur", category: "Groceries" },
    { name: "More Supermarket", city: "Solapur", category: "Groceries" },
    { name: "McDonald's", city: "Solapur", category: "Food & Dining" },
    { name: "KFC", city: "Solapur", category: "Food & Dining" },
    { name: "Domino's Pizza", city: "Solapur", category: "Takeout & Delivery" },
    { name: "Subway", city: "Solapur", category: "Food & Dining" },
    { name: "Apollo Pharmacy", city: "Solapur", category: "Health & Medicine" },
    { name: "MedPlus", city: "Solapur", category: "Health & Medicine" },
    { name: "Solapur Civil Hospital", city: "Solapur", category: "Health & Medicine" },
    { name: "Croma", city: "Solapur", category: "Electronics" },
    { name: "Reliance Digital", city: "Solapur", category: "Electronics" },
    { name: "Pantaloons", city: "Solapur", category: "Clothing & Fashion" },
    { name: "Max Fashion", city: "Solapur", category: "Clothing & Fashion" },
    { name: "Indian Oil Petrol Pump", city: "Solapur", category: "Transport" },
    { name: "HPCL Petrol Pump", city: "Solapur", category: "Transport" },
    { name: "Ola", city: "Solapur", category: "Transport" },
    { name: "Cinepolis", city: "Solapur", category: "Entertainment" },
    { name: "Lakme Salon", city: "Solapur", category: "Personal Care" },
    { name: "Home Centre", city: "Solapur", category: "Home & Household" },
];

// ─────────────────────────────────────────────
// NORMALIZER (mirrors Postgres normalize_merchant_key)
// ─────────────────────────────────────────────

function normalizeMerchantKey(name: string, city: string): string {
    const normalize = (s: string) =>
        s.toLowerCase()
            .replace(/[^a-z0-9\s]/g, "")   // strip punctuation
            .trim()
            .replace(/\s+/g, "_");          // spaces → underscores
    return `${normalize(name)}_${normalize(city)}`;
}

// ─────────────────────────────────────────────
// SEEDER
// ─────────────────────────────────────────────

interface SeedStats {
    seeded: number;
    skipped: number;
    errors: number;
    byCategory: Record<string, number>;
    byCity: Record<string, number>;
}

async function seedMerchant(merchant: MerchantSeed, stats: SeedStats): Promise<void> {
    const key = normalizeMerchantKey(merchant.name, merchant.city);

    const { data, error } = await supabase.rpc("seed_merchant_from_places", {
        p_name: merchant.name,
        p_city: merchant.city,
        p_country: "IN",
        p_category: merchant.category,
        p_place_id: `hardcoded_${key}`,   // stable fake ID — not used functionally
        p_types: [merchant.category.toLowerCase().replace(/[\s&]/g, "_")],
    });

    if (error) {
        if (error.message?.includes("duplicate") || error.message?.includes("unique")) {
            stats.skipped++;
        } else {
            stats.errors++;
            console.error(`  ❌ ${merchant.name} (${merchant.city}): ${error.message}`);
        }
        return;
    }

    if (data?.seeded) {
        stats.seeded++;
        stats.byCategory[merchant.category] = (stats.byCategory[merchant.category] ?? 0) + 1;
        stats.byCity[merchant.city] = (stats.byCity[merchant.city] ?? 0) + 1;
    } else {
        stats.skipped++;  // ON CONFLICT — merchant already existed, real votes protected
    }
}

async function main(): Promise<void> {
    console.log("═".repeat(52));
    console.log("  ATLAS CrowdTag — Maharashtra Merchant Seeder");
    console.log(`  Total merchants to seed : ${MERCHANTS.length}`);
    console.log(`  Cities                  : Pune, Mumbai, Nagpur,`);
    console.log(`                           Nashik, Aurangabad, Thane,`);
    console.log(`                           Kolhapur, Solapur`);
    console.log(`  Google Places API       : NOT REQUIRED ✅`);
    console.log("═".repeat(52));
    console.log();

    const stats: SeedStats = {
        seeded: 0,
        skipped: 0,
        errors: 0,
        byCategory: {},
        byCity: {},
    };

    // Seed in batches of 20 — avoids overwhelming Supabase
    const BATCH_SIZE = 20;
    const total = MERCHANTS.length;
    let processed = 0;

    for (let i = 0; i < total; i += BATCH_SIZE) {
        const batch = MERCHANTS.slice(i, i + BATCH_SIZE);
        await Promise.all(batch.map(m => seedMerchant(m, stats)));
        processed += batch.length;
        process.stdout.write(`\r  Progress: ${processed}/${total} merchants...`);
    }

    console.log("\n");
    console.log("═".repeat(52));
    console.log("  SEEDING COMPLETE");
    console.log(`  ✅ Seeded   : ${stats.seeded}`);
    console.log(`  ⏭️  Skipped  : ${stats.skipped} (already existed)`);
    console.log(`  ❌ Errors   : ${stats.errors}`);

    console.log("\n  By City:");
    Object.entries(stats.byCity)
        .sort(([, a], [, b]) => b - a)
        .forEach(([city, count]) =>
            console.log(`    ${city.padEnd(20)} ${count}`)
        );

    console.log("\n  By Category:");
    Object.entries(stats.byCategory)
        .sort(([, a], [, b]) => b - a)
        .forEach(([cat, count]) =>
            console.log(`    ${cat.padEnd(25)} ${count}`)
        );

    console.log("═".repeat(52));

    if (stats.errors > 0) {
        console.log("\n⚠️  Some merchants failed. Check errors above.");
        console.log("   Most likely cause: seed_merchant_from_places RPC not found.");
        console.log("   Fix: Run crowdtag-schema.sql in Supabase SQL Editor first.");
        process.exit(1);
    }
}

main().catch(err => {
    console.error("\n💥 Fatal error:", err.message);
    console.error("   Make sure SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are set.");
    process.exit(1);
});
