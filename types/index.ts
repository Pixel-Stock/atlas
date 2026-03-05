/* ============================================================
   ATLAS — Shared TypeScript Types
   ============================================================ */

// ─── Database Models ───────────────────────────────────────

export interface Profile {
    id: string;
    full_name: string;
    email: string;
    avatar_url: string | null;
    role: 'user' | 'admin';
    theme_preference: 'dark' | 'light' | 'system';
    created_at: string;
    updated_at: string;
}

export interface Receipt {
    id: string;
    user_id: string;
    merchant_name: string | null;
    receipt_date: string | null;
    total_amount: number | null;
    currency: string;
    overall_confidence: number | null;
    model_used: 'gemini' | 'custom_ml' | null;
    raw_text: string | null;
    is_torn_receipt: boolean;
    notes: string | null;
    created_at: string;
}

export interface LineItem {
    id: string;
    receipt_id: string;
    item_name: string;
    amount: number;
    category: string;
    confidence: number | null;
    manually_corrected: boolean;
    created_at: string;
}

export interface Category {
    id: string;
    name: string;
    icon: string | null;
    color: string | null;
    created_at: string;
}

export interface MerchantFingerprint {
    id: string;
    merchant_key: string;
    display_name: string | null;
    city: string | null;
    country: string;
    category_votes: Record<string, number>;
    dominant_category: string | null;
    confidence_score: number;
    total_votes: number;
    is_resolved: boolean;
    resolved_at: string | null;
    recent_votes: Record<string, unknown>[];
    drift_detected: boolean;
    drift_detected_at: string | null;
    last_drift_check: string | null;
    seeded_from_places_api: boolean;
    places_api_types: string[];
    places_place_id: string | null;
    category_distribution: Record<string, number>;
    is_multi_category: boolean;
    created_at: string;
    updated_at: string;
}

export interface CrowdTagVote {
    id: string;
    merchant_key: string;
    user_id: string;
    category: string;
    confidence: number;
    trust_weight: number;
    weighted_vote: number;
    is_manual: boolean;
    receipt_id: string | null;
    created_at: string;
}

export interface UserTrustScoreRecord {
    user_id: string;
    trust_score: number;
    total_scans: number;
    correct_votes: number;
    incorrect_votes: number;
    accuracy_rate: number;
    tier: 'new' | 'experienced' | 'validated' | 'expert';
    last_updated: string;
}

export interface CrowdTagEventRecord {
    id: string;
    event_type: 'merchant_resolved' | 'drift_detected' | 'merchant_seeded' | 'vote_logged';
    merchant_key: string;
    payload: Record<string, unknown>;
    created_at: string;
}

// ─── AI Pipeline Types (Phase 2) ──────────────────────────

export type ModelSource = 'gemini' | 'custom_ml';

export interface ATLASReceiptResult {
    merchant_name: string;
    receipt_date: string | null;
    total_amount: number;
    currency: string;
    items: GeminiLineItem[];
    subtotal: number | null;
    tax: number | null;
    discount: number | null;
    overall_confidence: number;
    model_used: ModelSource;
    gemini_confidence: number;
    ml_confidence: number;
    ml_server_available: boolean;
    confidence_tier: 'high' | 'medium' | 'low';
    processing_time_ms: number;
    is_torn_receipt: boolean;
    notes?: string;
    // ML model fields
    ml_classification?: string;
    category_hint?: string;
    ml_action?: string;
    ml_inference_ms?: number;
    model_version?: string;
    // CrowdTag Phase 2 fields
    crowdtag_hit?: boolean;
    crowdtag_category?: string;
    crowdtag_confidence?: number;
    crowdtag_is_multi_category?: boolean;
    crowdtag_distribution?: Record<string, number>;
}

// ─── API Request/Response Types ────────────────────────────

export interface ScanResult {
    merchant: string;
    date: string | null;
    total: number;
    currency: string;
    items: ScanLineItem[];
    overall_confidence: number;
    model_used: 'gemini' | 'custom_ml';
    raw_text: string;
}

export interface ScanLineItem {
    name: string;
    quantity: number;
    unit_price: number;
    total_price: number;
    category: string;
    confidence: number;
}

export interface GeminiResponse {
    merchant_name: string;
    receipt_date: string | null;
    total_amount: number;
    currency: string;
    line_items: GeminiLineItem[];
    subtotal: number | null;
    tax: number | null;
    discount: number | null;
    overall_confidence: number;
}

export interface GeminiLineItem {
    name: string;
    quantity: number;
    unit_price: number;
    total_price: number;
    category: string;
    confidence: number;
}

export interface MLModelResult {
    merchant_name: string;
    line_items: ScanLineItem[];
    overall_confidence: number;
    model_version: string;
}

export interface PipelineResult {
    winner: ScanResult;
    gemini_confidence: number;
    ml_confidence: number;
    model_used: 'gemini' | 'custom_ml';
}

// ─── Auth Types ────────────────────────────────────────────

export interface SignUpPayload {
    email: string;
    password: string;
    confirm_password: string;
    full_name: string;
}

export interface SignInPayload {
    email: string;
    password: string;
    remember_me: boolean;
}

export interface PasswordValidation {
    minLength: boolean;
    maxLength: boolean;
    hasUppercase: boolean;
    hasLowercase: boolean;
    hasNumber: boolean;
    hasSpecialChar: boolean;
    isValid: boolean;
}

// ─── Dashboard Types ───────────────────────────────────────

export interface DashboardStats {
    total_this_month: number;
    total_last_month: number;
    percent_change: number;
    top_category: string | null;
    receipts_scanned: number;
}

export interface SpendingByCategory {
    category: string;
    total: number;
    color: string;
    count: number;
}

export interface DailySpending {
    date: string;
    total: number;
}

export interface TransactionListItem {
    id: string;
    merchant_name: string | null;
    receipt_date: string | null;
    total_amount: number | null;
    category: string;
    confidence: number | null;
    model_used: 'gemini' | 'custom_ml' | null;
    created_at: string;
}

// ─── Insight Types ─────────────────────────────────────────

export interface WeeklyInsight {
    message: string;
    type: 'increase' | 'decrease' | 'neutral';
    category: string;
    percent_change: number;
}

export interface CategoryBreakdown {
    category: string;
    total_spent: number;
    percent_of_total: number;
    transaction_count: number;
    avg_per_transaction: number;
    color: string;
    icon: string;
}

// ─── Admin Types ───────────────────────────────────────────

export interface AdminStats {
    total_users: number;
    new_users_today: number;
    new_users_this_week: number;
    total_receipts: number;
    scans_today: number;
    avg_confidence: number;
    gemini_percent: number;
    custom_ml_percent: number;
    top_merchants: { name: string; count: number }[];
    category_distribution: { category: string; count: number; percent: number }[];
    error_rate: number;
}

export interface AdminUser {
    id: string;
    full_name: string;
    email: string;
    created_at: string;
    scan_count: number;
    last_active: string | null;
    is_active: boolean;
    role: 'user' | 'admin';
}

// ─── UI Types ──────────────────────────────────────────────

export type ThemeMode = 'dark' | 'light' | 'system';

export type DateRangeFilter = 'this_week' | 'this_month' | 'last_3_months' | 'custom';

export interface DateRange {
    start: Date;
    end: Date;
}

export type SortField = 'date' | 'amount' | 'confidence';
export type SortDirection = 'asc' | 'desc';

export interface TransactionFilters {
    search: string;
    categories: string[];
    date_range: DateRangeFilter;
    custom_date_range: DateRange | null;
    amount_min: number | null;
    amount_max: number | null;
    sort_field: SortField;
    sort_direction: SortDirection;
}

// ─── Confidence Color Helpers ──────────────────────────────

export type ConfidenceLevel = 'high' | 'medium' | 'low';

export function getConfidenceLevel(confidence: number): ConfidenceLevel {
    if (confidence >= 0.85) return 'high';
    if (confidence >= 0.60) return 'medium';
    return 'low';
}

export function getConfidenceColor(confidence: number): string {
    const level = getConfidenceLevel(confidence);
    switch (level) {
        case 'high':
            return 'var(--success)';
        case 'medium':
            return 'var(--warning)';
        case 'low':
            return 'var(--error)';
    }
}
