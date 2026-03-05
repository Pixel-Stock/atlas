/**
 * ATLAS CrowdTag — Google Places Seeder
 * ======================================
 * Drop at: scripts/seed-places.ts
 * Run with: npx tsx scripts/seed-places.ts --cities "Pune" --limit 50
 *
 * Pre-populates merchant_fingerprints with real merchant data
 * from Google Places API (New). Seeded merchants start at
 * 0.70 confidence with 5 virtual votes.
 *
 * Required env vars:
 *   GOOGLE_PLACES_API_KEY
 *   SUPABASE_URL (or NEXT_PUBLIC_SUPABASE_URL)
 *   SUPABASE_SERVICE_ROLE_KEY
 */

import { createClient } from "@supabase/supabase-js";

// ─────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────

const GOOGLE_API_KEY = process.env.GOOGLE_PLACES_API_KEY;
const SUPABASE_URL = process.env.SUPABASE_URL ?? process.env.NEXT_PUBLIC_SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!GOOGLE_API_KEY) { console.error("❌ GOOGLE_PLACES_API_KEY not set"); process.exit(1); }
if (!SUPABASE_URL) { console.error("❌ SUPABASE_URL not set"); process.exit(1); }
if (!SUPABASE_KEY) { console.error("❌ SUPABASE_SERVICE_ROLE_KEY not set"); process.exit(1); }

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// ─────────────────────────────────────────────
// QUERY TYPES → ATLAS CATEGORIES
// ─────────────────────────────────────────────

const QUERY_TO_CATEGORY: Record<string, string> = {
    "supermarket": "Groceries",
    "grocery store": "Groceries",
    "convenience store": "Groceries",
    "pharmacy": "Health & Medicine",
    "drugstore": "Health & Medicine",
    "hospital": "Health & Medicine",
    "restaurant": "Food & Dining",
    "cafe": "Food & Dining",
    "bakery": "Food & Dining",
    "fast food": "Takeout & Delivery",
    "meal delivery": "Takeout & Delivery",
    "clothing store": "Clothing & Fashion",
    "gas station": "Transport",
};

// ─────────────────────────────────────────────
// ARGS
// ─────────────────────────────────────────────

function parseArgs() {
    const args = process.argv.slice(2);
    const flags: Record<string, string> = {};
    for (let i = 0; i < args.length; i += 2) {
        const key = args[i].replace(/^--/, "");
        flags[key] = args[i + 1] ?? "";
    }
    return {
        cities: (flags.cities ?? "Pune").split(",").map((c) => c.trim()),
        country: flags.country ?? "IN",
        limit: parseInt(flags.limit ?? "100", 10),
    };
}

// ─────────────────────────────────────────────
// GOOGLE PLACES TEXT SEARCH
// ─────────────────────────────────────────────

interface PlaceResult {
    displayName?: { text: string };
    formattedAddress?: string;
    types?: string[];
    id?: string;
}

async function searchPlaces(
    query: string,
    city: string,
    country: string,
    pageToken?: string,
): Promise<{ places: PlaceResult[]; nextPageToken?: string }> {
    const url = "https://places.googleapis.com/v1/places:searchText";

    const body: Record<string, unknown> = {
        textQuery: `${query} in ${city}, ${country}`,
        maxResultCount: 20,
        languageCode: "en",
    };

    if (pageToken) {
        body.pageToken = pageToken;
    }

    const response = await fetch(url, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            "X-Goog-Api-Key": GOOGLE_API_KEY!,
            "X-Goog-FieldMask": "places.displayName,places.formattedAddress,places.types,places.id,nextPageToken",
        },
        body: JSON.stringify(body),
    });

    if (!response.ok) {
        const errText = await response.text();
        console.error(`   ⚠️  Places API error: ${response.status} — ${errText}`);
        return { places: [] };
    }

    const data = await response.json();
    return {
        places: data.places ?? [],
        nextPageToken: data.nextPageToken,
    };
}

// ─────────────────────────────────────────────
// SEED ONE MERCHANT
// ─────────────────────────────────────────────

async function seedMerchant(
    place: PlaceResult,
    city: string,
    country: string,
    category: string,
): Promise<"seeded" | "skipped" | "error"> {
    const name = place.displayName?.text;
    if (!name) return "skipped";

    try {
        const { error } = await supabase.rpc("seed_merchant_from_places", {
            p_name: name,
            p_city: city,
            p_country: country,
            p_category: category,
            p_place_id: place.id ?? null,
            p_types: place.types ?? [],
        });

        if (error) {
            // ON CONFLICT DO NOTHING → not actually an error
            if (error.message?.includes("duplicate") || error.code === "23505") {
                return "skipped";
            }
            console.error(`   ❌ Error seeding ${name}:`, error.message);
            return "error";
        }

        return "seeded";
    } catch (err) {
        console.error(`   ❌ Exception seeding ${name}:`, err);
        return "error";
    }
}

// ─────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────

async function main() {
    const { cities, country, limit } = parseArgs();

    console.log("═══════════════════════════════════════════");
    console.log("  ATLAS CrowdTag — Google Places Seeder");
    console.log(`  Cities  : ${cities.join(", ")}`);
    console.log(`  Country : ${country}`);
    console.log(`  Limit   : ${limit} per city`);
    console.log("═══════════════════════════════════════════\n");

    let totalFetched = 0;
    let totalSeeded = 0;
    let totalSkipped = 0;
    let totalErrors = 0;
    const categoryCount: Record<string, number> = {};

    for (const city of cities) {
        console.log(`🏙️  Seeding: ${city}, ${country}`);
        let cityFetched = 0;

        for (const [query, category] of Object.entries(QUERY_TO_CATEGORY)) {
            if (cityFetched >= limit) break;

            let pageToken: string | undefined;
            let pages = 0;

            do {
                const { places, nextPageToken } = await searchPlaces(query, city, country, pageToken);
                const count = places.length;
                console.log(`   📍 "${query}" → ${count} results`);

                for (const place of places) {
                    if (cityFetched >= limit) break;

                    const result = await seedMerchant(place, city, country, category);
                    if (result === "seeded") {
                        totalSeeded++;
                        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
                    } else if (result === "skipped") {
                        totalSkipped++;
                    } else {
                        totalErrors++;
                    }
                    cityFetched++;
                    totalFetched++;
                }

                pageToken = nextPageToken;
                pages++;

                // Rate limit: 2s delay between paginated requests
                if (pageToken) {
                    await new Promise((resolve) => setTimeout(resolve, 2000));
                }
            } while (pageToken && pages < 3 && cityFetched < limit);

            // Small delay between query types
            await new Promise((resolve) => setTimeout(resolve, 500));
        }

        console.log("");
    }

    console.log("═══════════════════════════════════════════");
    console.log("  SEEDING COMPLETE");
    console.log(`  Fetched  : ${totalFetched}`);
    console.log(`  Seeded   : ${totalSeeded} (new merchants)`);
    console.log(`  Skipped  : ${totalSkipped} (already existed)`);
    console.log(`  Errors   : ${totalErrors}`);
    console.log("");
    console.log("  By Category:");

    const sorted = Object.entries(categoryCount).sort((a, b) => b[1] - a[1]);
    for (const [cat, count] of sorted) {
        console.log(`    ${cat.padEnd(25)} ${count}`);
    }

    console.log("═══════════════════════════════════════════");
}

main().catch((err) => {
    console.error("Fatal error:", err);
    process.exit(1);
});
