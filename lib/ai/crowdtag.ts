/**
 * ATLAS CrowdTag Engine — crowdtag.ts
 * =====================================
 * Drop at: lib/ai/crowdtag.ts
 *
 * Phase 2 FULL implementation — replaces crowdtag-stub.ts.
 * Handles merchant resolution, vote logging, drift detection,
 * trust scores, and admin analytics via Supabase RPCs.
 */

import { createSupabaseServerClient, createSupabaseServiceClient } from "@/lib/supabase/server";

// ─────────────────────────────────────────────
// TYPES
// ─────────────────────────────────────────────

export interface MerchantResolution {
    found: boolean;
    merchant_key?: string;
    is_resolved?: boolean;
    dominant_category?: string;
    confidence?: number;
    total_votes?: number;
    is_multi_category?: boolean;
    category_distribution?: Record<string, number>;
    seeded?: boolean;
}

export interface MerchantVoteParams {
    merchantName: string;
    city?: string;
    category: string;
    userId: string;
    confidence: number;
    receiptId?: string;
    isManual?: boolean;
}

export interface MerchantVoteResult {
    merchant_key: string;
    dominant_category: string;
    confidence: number;
    is_resolved: boolean;
    total_votes: number;
    duplicate?: boolean;
}

export interface DriftResult {
    drift_detected: boolean;
    contra_votes: number;
    dominant_category: string;
    merchant_key: string;
    reason?: string;
}

export interface UserTrustScore {
    trust_score: number;
    tier: "new" | "experienced" | "validated" | "expert";
    accuracy: number;
    total_scans: number;
}

export interface CrowdTagConfidenceTier {
    tier: "community_verified" | "building" | "seeded" | "unverified";
    label: string;
    color: string;
    icon: string;
}

export interface CrowdTagAdminSummary {
    total_merchants: number;
    resolved_merchants: number;
    seeded_merchants: number;
    drift_merchants: number;
    multi_category_merchants: number;
    avg_confidence: number;
    avg_votes_per_merchant: number;
    total_votes_cast: number;
}

export interface TopMerchant {
    merchant_key: string;
    display_name: string;
    city: string;
    dominant_category: string;
    confidence_score: number;
    total_votes: number;
    is_resolved: boolean;
    is_multi_category: boolean;
    category_distribution: Record<string, number>;
    seeded_from_places_api: boolean;
}

export interface CrowdTagEvent {
    id: string;
    event_type: string;
    merchant_key: string;
    payload: Record<string, unknown>;
    created_at: string;
}

// ─────────────────────────────────────────────
// CORE FUNCTIONS
// ─────────────────────────────────────────────

/**
 * Resolve a merchant before running AI categorization.
 * If resolved (30+ votes, 75%+ confidence), returns cached category instantly.
 */
export async function resolveMerchant(
    merchantName: string,
    city: string = "",
): Promise<MerchantResolution> {
    try {
        const supabase = await createSupabaseServerClient();
        const { data, error } = await supabase.rpc("resolve_merchant_for_user", {
            p_merchant_name: merchantName,
            p_city: city,
        });

        if (error) {
            console.error("[ATLAS/crowdtag] resolveMerchant RPC error:", error.message);
            return { found: false };
        }

        return (data as MerchantResolution) ?? { found: false };
    } catch (err) {
        console.error("[ATLAS/crowdtag] resolveMerchant failed:", err);
        return { found: false };
    }
}

/**
 * Log a merchant vote after every successful scan.
 * MUST be called non-blocking — never delay the user response.
 */
export async function logMerchantVote(
    params: MerchantVoteParams,
): Promise<MerchantVoteResult | null> {
    try {
        const supabase = await createSupabaseServerClient();
        const { data, error } = await supabase.rpc("upsert_merchant_vote", {
            p_merchant_name: params.merchantName,
            p_city: params.city ?? "",
            p_category: params.category,
            p_user_id: params.userId,
            p_confidence: params.confidence,
            p_receipt_id: params.receiptId ?? null,
            p_is_manual: params.isManual ?? false,
        });

        if (error) {
            console.error("[ATLAS/crowdtag] logMerchantVote RPC error:", error.message);
            return null;
        }

        if (process.env.NODE_ENV === "development") {
            console.log("[ATLAS/crowdtag] Vote logged:", data);
        }

        return data as MerchantVoteResult;
    } catch (err) {
        console.error("[ATLAS/crowdtag] logMerchantVote failed:", err);
        return null;
    }
}

/**
 * Check a resolved merchant for drift.
 * Call every 10th vote (handled automatically by the DB function).
 */
export async function checkMerchantDrift(
    merchantKey: string,
): Promise<DriftResult> {
    try {
        const supabase = await createSupabaseServerClient();
        const { data, error } = await supabase.rpc("check_merchant_drift", {
            p_merchant_key: merchantKey,
        });

        if (error) {
            console.error("[ATLAS/crowdtag] checkMerchantDrift RPC error:", error.message);
            return { drift_detected: false, contra_votes: 0, dominant_category: "", merchant_key: merchantKey };
        }

        return data as DriftResult;
    } catch (err) {
        console.error("[ATLAS/crowdtag] checkMerchantDrift failed:", err);
        return { drift_detected: false, contra_votes: 0, dominant_category: "", merchant_key: merchantKey };
    }
}

/**
 * Get a user's trust score and tier.
 */
export async function getUserTrustScore(userId: string): Promise<UserTrustScore> {
    try {
        const supabase = await createSupabaseServerClient();
        const { data, error } = await supabase
            .from("user_trust_scores")
            .select("trust_score, tier, accuracy_rate, total_scans")
            .eq("user_id", userId)
            .single();

        if (error || !data) {
            return { trust_score: 0.5, tier: "new", accuracy: 0, total_scans: 0 };
        }

        return {
            trust_score: data.trust_score,
            tier: data.tier,
            accuracy: data.accuracy_rate,
            total_scans: data.total_scans,
        };
    } catch {
        return { trust_score: 0.5, tier: "new", accuracy: 0, total_scans: 0 };
    }
}

/**
 * Get CrowdTag confidence tier for UI badges.
 */
export function getCrowdTagConfidenceTier(confidence: number): CrowdTagConfidenceTier {
    if (confidence >= 0.85) {
        return { tier: "community_verified", label: "Community Verified", color: "#10b981", icon: "shield-check" };
    }
    if (confidence >= 0.70) {
        return { tier: "building", label: "Building Consensus", color: "#f59e0b", icon: "users" };
    }
    if (confidence >= 0.50) {
        return { tier: "seeded", label: "Pre-Verified", color: "#6b7280", icon: "database" };
    }
    return { tier: "unverified", label: "Unverified", color: "#ef4444", icon: "alert-circle" };
}

/**
 * Search merchants by name (for autocomplete).
 */
export async function searchMerchants(
    query: string,
    limit: number = 10,
): Promise<TopMerchant[]> {
    try {
        const supabase = await createSupabaseServerClient();
        const { data, error } = await supabase
            .from("merchant_fingerprints")
            .select("merchant_key, display_name, city, dominant_category, confidence_score, total_votes, is_resolved, is_multi_category, category_distribution, seeded_from_places_api")
            .ilike("display_name", `%${query}%`)
            .order("total_votes", { ascending: false })
            .limit(limit);

        if (error) {
            console.error("[ATLAS/crowdtag] searchMerchants error:", error.message);
            return [];
        }

        return (data ?? []) as TopMerchant[];
    } catch {
        return [];
    }
}

// ─────────────────────────────────────────────
// ADMIN FUNCTIONS (server-side only)
// ─────────────────────────────────────────────

/**
 * Get CrowdTag admin summary stats.
 */
export async function getCrowdTagAdminSummary(): Promise<CrowdTagAdminSummary | null> {
    try {
        const supabase = await createSupabaseServerClient();
        const { data, error } = await supabase
            .from("crowdtag_admin_summary")
            .select("*")
            .single();

        if (error) {
            console.error("[ATLAS/crowdtag] getCrowdTagAdminSummary error:", error.message);
            return null;
        }

        return data as CrowdTagAdminSummary;
    } catch {
        return null;
    }
}

/**
 * Get category distribution across all merchants.
 */
export async function getCategoryDistribution(): Promise<
    { dominant_category: string; merchant_count: number; resolved_count: number; total_votes: number; avg_confidence: number }[]
> {
    try {
        const supabase = await createSupabaseServerClient();
        const { data, error } = await supabase
            .from("crowdtag_category_distribution")
            .select("*");

        if (error) return [];
        return data ?? [];
    } catch {
        return [];
    }
}

/**
 * Get top merchants by vote count.
 */
export async function getTopMerchants(limit: number = 100): Promise<TopMerchant[]> {
    try {
        const supabase = await createSupabaseServerClient();
        const { data, error } = await supabase
            .from("crowdtag_top_merchants")
            .select("*")
            .limit(limit);

        if (error) return [];
        return (data ?? []) as TopMerchant[];
    } catch {
        return [];
    }
}

/**
 * Get recent CrowdTag events.
 */
export async function getRecentEvents(limit: number = 50): Promise<CrowdTagEvent[]> {
    try {
        const supabase = await createSupabaseServerClient();
        const { data, error } = await supabase
            .from("crowdtag_events")
            .select("*")
            .order("created_at", { ascending: false })
            .limit(limit);

        if (error) return [];
        return (data ?? []) as CrowdTagEvent[];
    } catch {
        return [];
    }
}

/**
 * Get merchants with active drift detection.
 */
export async function getDriftedMerchants(): Promise<TopMerchant[]> {
    try {
        const supabase = await createSupabaseServerClient();
        const { data, error } = await supabase
            .from("merchant_fingerprints")
            .select("merchant_key, display_name, city, dominant_category, confidence_score, total_votes, is_resolved, is_multi_category, category_distribution, seeded_from_places_api")
            .eq("drift_detected", true)
            .order("drift_detected_at", { ascending: false });

        if (error) return [];
        return (data ?? []) as TopMerchant[];
    } catch {
        return [];
    }
}
