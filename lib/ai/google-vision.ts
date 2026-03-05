/**
 * ATLAS — Google Cloud Vision OCR Engine
 * ========================================
 * Uses Google Cloud Vision API (document text detection) for high-accuracy
 * receipt text extraction as a secondary OCR source alongside Gemini Vision.
 *
 * Authentication: Uses service account JSON credentials file.
 * Set GOOGLE_APPLICATION_CREDENTIALS env var to the path of your
 * hackarena267-17d7f8466102.json file.
 *
 * This provides raw OCR text extraction — the actual receipt parsing
 * (merchant name, line items, categories) is still done by Gemini's
 * structured prompt. Google Vision's role is providing higher-quality
 * text when Gemini struggles with blurry/low-contrast receipts.
 */

import { logger } from "@/lib/utils/logger";
import type { GeminiResponse } from "@/types";

// ─────────────────────────────────────────────
// TYPES
// ─────────────────────────────────────────────

interface GoogleVisionTextAnnotation {
    description: string;
    locale?: string;
    boundingPoly?: {
        vertices: { x: number; y: number }[];
    };
}

interface GoogleVisionResponse {
    responses: {
        textAnnotations?: GoogleVisionTextAnnotation[];
        fullTextAnnotation?: {
            text: string;
            pages?: {
                blocks?: {
                    paragraphs?: {
                        words?: {
                            symbols?: {
                                text: string;
                                confidence: number;
                            }[];
                        }[];
                        confidence: number;
                    }[];
                }[];
            }[];
        };
        error?: {
            code: number;
            message: string;
        };
    }[];
}

export interface VisionOCRResult {
    raw_text: string;
    confidence: number;
    word_count: number;
    language: string | null;
    processing_time_ms: number;
}

// ─────────────────────────────────────────────
// AUTH — Service Account JWT Token Generation
// ─────────────────────────────────────────────

interface ServiceAccountCredentials {
    type: string;
    project_id: string;
    private_key_id: string;
    private_key: string;
    client_email: string;
    client_id: string;
    auth_uri: string;
    token_uri: string;
}

let _cachedToken: string | null = null;
let _tokenExpiry = 0;

/**
 * Load service account credentials from file or env.
 * Tries: GOOGLE_VISION_CREDENTIALS_JSON (inline JSON string) first,
 * then GOOGLE_APPLICATION_CREDENTIALS (file path).
 */
function loadCredentials(): ServiceAccountCredentials {
    // Option 1: Inline JSON (for Vercel/Railway env vars)
    const inlineJson = process.env.GOOGLE_VISION_CREDENTIALS_JSON;
    if (inlineJson) {
        try {
            return JSON.parse(inlineJson) as ServiceAccountCredentials;
        } catch {
            throw new Error("GOOGLE_VISION_CREDENTIALS_JSON is not valid JSON");
        }
    }

    // Option 2: File path
    const filePath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
    if (filePath) {
        try {
            const fs = require("fs");
            const content = fs.readFileSync(filePath, "utf8");
            return JSON.parse(content) as ServiceAccountCredentials;
        } catch (err) {
            throw new Error(
                `Failed to read credentials from ${filePath}: ${err instanceof Error ? err.message : err}`
            );
        }
    }

    throw new Error(
        "Google Vision credentials not configured. Set GOOGLE_VISION_CREDENTIALS_JSON or GOOGLE_APPLICATION_CREDENTIALS"
    );
}

/**
 * Create a signed JWT and exchange it for a Google OAuth2 access token.
 * Uses the service account's private key to sign the JWT.
 */
async function getAccessToken(): Promise<string> {
    const now = Math.floor(Date.now() / 1000);

    // Return cached token if still valid (5-min buffer)
    if (_cachedToken && _tokenExpiry > now + 300) {
        return _cachedToken;
    }

    const creds = loadCredentials();

    // Create JWT header + claims
    const header = { alg: "RS256", typ: "JWT" };
    const claims = {
        iss: creds.client_email,
        scope: "https://www.googleapis.com/auth/cloud-vision",
        aud: creds.token_uri,
        iat: now,
        exp: now + 3600,
    };

    // Base64url encode
    const b64url = (obj: unknown) =>
        Buffer.from(JSON.stringify(obj))
            .toString("base64")
            .replace(/\+/g, "-")
            .replace(/\//g, "_")
            .replace(/=+$/, "");

    const unsignedToken = `${b64url(header)}.${b64url(claims)}`;

    // Sign with RSA-SHA256 using the private key
    const crypto = require("crypto");
    const sign = crypto.createSign("RSA-SHA256");
    sign.update(unsignedToken);
    const signature = sign
        .sign(creds.private_key, "base64")
        .replace(/\+/g, "-")
        .replace(/\//g, "_")
        .replace(/=+$/, "");

    const jwt = `${unsignedToken}.${signature}`;

    // Exchange JWT for access token
    const tokenRes = await fetch(creds.token_uri, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
    });

    if (!tokenRes.ok) {
        const errText = await tokenRes.text();
        throw new Error(`Google OAuth2 token exchange failed: ${tokenRes.status} ${errText}`);
    }

    const tokenData = await tokenRes.json();
    _cachedToken = tokenData.access_token;
    _tokenExpiry = now + (tokenData.expires_in || 3600);

    return _cachedToken!;
}

// ─────────────────────────────────────────────
// CORE OCR — Document Text Detection
// ─────────────────────────────────────────────

/**
 * Run Google Cloud Vision DOCUMENT_TEXT_DETECTION on a receipt image.
 * This is superior to TEXT_DETECTION for receipts because it preserves
 * document structure (blocks → paragraphs → words → symbols).
 *
 * @param imageBuffer - Raw image bytes
 * @param mimeType    - Image MIME type (e.g., "image/jpeg")
 * @returns VisionOCRResult with extracted text and confidence
 */
export async function runGoogleVisionOCR(
    imageBuffer: Buffer,
    mimeType: string,
): Promise<VisionOCRResult> {
    const startTime = Date.now();
    logger.info("GoogleVision", "Starting document text detection");

    try {
        const accessToken = await getAccessToken();

        const requestBody = {
            requests: [
                {
                    image: {
                        content: imageBuffer.toString("base64"),
                    },
                    features: [
                        {
                            type: "DOCUMENT_TEXT_DETECTION",
                            maxResults: 1,
                        },
                    ],
                    imageContext: {
                        languageHints: ["en", "hi"],  // English + Hindi for Indian receipts
                    },
                },
            ],
        };

        const res = await fetch(
            "https://vision.googleapis.com/v1/images:annotate",
            {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    Authorization: `Bearer ${accessToken}`,
                },
                body: JSON.stringify(requestBody),
            }
        );

        if (!res.ok) {
            const errText = await res.text();
            throw new Error(`Vision API HTTP ${res.status}: ${errText}`);
        }

        const data: GoogleVisionResponse = await res.json();
        const response = data.responses?.[0];

        if (response?.error) {
            throw new Error(`Vision API error ${response.error.code}: ${response.error.message}`);
        }

        // Extract full text
        const fullText = response?.fullTextAnnotation?.text || "";
        const firstAnnotation = response?.textAnnotations?.[0];
        const language = firstAnnotation?.locale || null;

        // Calculate average confidence across all paragraphs
        let totalConfidence = 0;
        let paragraphCount = 0;

        if (response?.fullTextAnnotation?.pages) {
            for (const page of response.fullTextAnnotation.pages) {
                for (const block of page.blocks ?? []) {
                    for (const paragraph of block.paragraphs ?? []) {
                        totalConfidence += paragraph.confidence ?? 0;
                        paragraphCount++;
                    }
                }
            }
        }

        const avgConfidence = paragraphCount > 0 ? totalConfidence / paragraphCount : 0.5;
        const wordCount = fullText.split(/\s+/).filter(Boolean).length;
        const elapsed = Date.now() - startTime;

        logger.info("GoogleVision", `OCR complete in ${elapsed}ms`, {
            wordCount,
            confidence: avgConfidence.toFixed(3),
            language,
        });

        return {
            raw_text: fullText,
            confidence: avgConfidence,
            word_count: wordCount,
            language,
            processing_time_ms: elapsed,
        };
    } catch (error) {
        logger.error("GoogleVision", "OCR failed", error);
        return {
            raw_text: "",
            confidence: 0,
            word_count: 0,
            language: null,
            processing_time_ms: Date.now() - startTime,
        };
    }
}

// ─────────────────────────────────────────────
// ENHANCED RECEIPT PARSING
// ─────────────────────────────────────────────

/**
 * Parse raw OCR text into a structured receipt format.
 * This is a rule-based parser for common Indian receipt formats.
 * Used as a fallback when Gemini's direct analysis fails or has low confidence.
 */
export function parseReceiptText(rawText: string): Partial<GeminiResponse> {
    if (!rawText || rawText.length < 10) {
        return { overall_confidence: 0, line_items: [] };
    }

    const lines = rawText.split("\n").map((l) => l.trim()).filter(Boolean);

    // Extract merchant name (usually first non-empty line or line with all caps)
    const merchantName = extractMerchantName(lines);

    // Extract date
    const receiptDate = extractDate(rawText);

    // Extract line items with prices
    const lineItems = extractLineItems(lines);

    // Extract totals
    const totals = extractTotals(lines);

    // Confidence based on how much we could parse
    const confidence = calculateParseConfidence(merchantName, lineItems, totals);

    return {
        merchant_name: merchantName,
        receipt_date: receiptDate,
        total_amount: totals.total,
        currency: "INR",
        line_items: lineItems,
        subtotal: totals.subtotal,
        tax: totals.tax,
        discount: totals.discount,
        overall_confidence: confidence,
    };
}

// ─────────────────────────────────────────────
// PARSING HELPERS
// ─────────────────────────────────────────────

function extractMerchantName(lines: string[]): string {
    // Look for common patterns: uppercase lines, lines before address/date
    for (const line of lines.slice(0, 5)) {
        // Skip lines that look like addresses, dates, phone numbers
        if (/^\d{2}[\/-]\d{2}/.test(line)) continue;
        if (/phone|tel|mob|gstin|gst|fssai/i.test(line)) continue;
        if (/^\d{10,}/.test(line)) continue;
        if (line.length < 3) continue;

        return line;
    }
    return "Unknown Merchant";
}

function extractDate(text: string): string | null {
    // Common Indian date formats: DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
    const datePatterns = [
        /(\d{2})[\/\-.](\d{2})[\/\-.](\d{4})/,          // DD/MM/YYYY
        /(\d{4})[\/\-.](\d{2})[\/\-.](\d{2})/,          // YYYY/MM/DD
        /(\d{2})[\/\-.](\d{2})[\/\-.](\d{2})\s/,        // DD/MM/YY
        /(\d{1,2})\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*\s+(\d{4})/i,
    ];

    for (const pattern of datePatterns) {
        const match = text.match(pattern);
        if (match) {
            try {
                // Try to parse into YYYY-MM-DD
                const d = new Date(match[0]);
                if (!isNaN(d.getTime())) {
                    return d.toISOString().split("T")[0];
                }
            } catch {
                // Return raw match if parsing fails
                return match[0];
            }
        }
    }
    return null;
}

function extractLineItems(
    lines: string[],
): GeminiResponse["line_items"] {
    const items: GeminiResponse["line_items"] = [];

    // Pattern: item name followed by price (common in Indian receipts)
    // "Milk 1L        ₹65.00"
    // "Bread           28.00"
    // "2 x Eggs       ₹12.00"
    const pricePattern = /^(.+?)\s+₹?\s*(\d+(?:[.,]\d{1,2})?)\s*$/;
    const qtyPricePattern = /^(\d+)\s*[xX×]\s*(.+?)\s+₹?\s*(\d+(?:[.,]\d{1,2})?)\s*$/;

    for (const line of lines) {
        // Skip total/subtotal lines
        if (/total|subtotal|sub\s*total|grand\s*total|net\s*amt|round|change|cash|card|upi/i.test(line)) {
            continue;
        }
        // Skip header/footer lines
        if (/thank|visit|bill\s*no|invoice|receipt|gstin|gst|date|time|phone|mob|tel/i.test(line)) {
            continue;
        }

        // Try quantity × item format first
        const qtyMatch = line.match(qtyPricePattern);
        if (qtyMatch) {
            const qty = parseInt(qtyMatch[1], 10);
            const name = qtyMatch[2].trim();
            const totalPrice = parseFloat(qtyMatch[3].replace(",", ""));
            items.push({
                name,
                quantity: qty,
                unit_price: totalPrice / qty,
                total_price: totalPrice,
                category: "Other",  // Will be categorized by Gemini or CrowdTag
                confidence: 0.7,
            });
            continue;
        }

        // Try regular item + price format
        const priceMatch = line.match(pricePattern);
        if (priceMatch) {
            const name = priceMatch[1].trim();
            const price = parseFloat(priceMatch[2].replace(",", ""));
            // Skip very small or very large amounts (likely noise)
            if (price >= 1 && price <= 100000 && name.length >= 2) {
                items.push({
                    name,
                    quantity: 1,
                    unit_price: price,
                    total_price: price,
                    category: "Other",
                    confidence: 0.6,
                });
            }
        }
    }

    return items;
}

function extractTotals(lines: string[]): {
    total: number;
    subtotal: number | null;
    tax: number | null;
    discount: number | null;
} {
    let total = 0;
    let subtotal: number | null = null;
    let tax: number | null = null;
    let discount: number | null = null;

    for (const line of lines) {
        const amountMatch = line.match(/₹?\s*(\d+(?:[.,]\d{1,2})?)\s*$/);
        if (!amountMatch) continue;

        const amount = parseFloat(amountMatch[1].replace(",", ""));

        if (/grand\s*total|net\s*(amount|amt)|total\s*(amount|amt)|payable/i.test(line)) {
            total = amount;
        } else if (/sub\s*total|subtotal/i.test(line)) {
            subtotal = amount;
        } else if (/tax|gst|cgst|sgst|vat|cess/i.test(line)) {
            tax = (tax ?? 0) + amount;
        } else if (/discount|disc|off|savings/i.test(line)) {
            discount = amount;
        } else if (/^total/i.test(line) && !total) {
            total = amount;
        }
    }

    return { total, subtotal, tax, discount };
}

function calculateParseConfidence(
    merchantName: string,
    lineItems: GeminiResponse["line_items"],
    totals: { total: number; subtotal: number | null },
): number {
    let confidence = 0.3;  // Base confidence for any text

    if (merchantName && merchantName !== "Unknown Merchant") confidence += 0.15;
    if (lineItems.length > 0) confidence += 0.2;
    if (lineItems.length > 3) confidence += 0.1;
    if (totals.total > 0) confidence += 0.15;
    if (totals.subtotal !== null) confidence += 0.1;

    // Check if line item amounts roughly sum to total
    if (totals.total > 0 && lineItems.length > 0) {
        const itemSum = lineItems.reduce((s, i) => s + i.total_price, 0);
        const ratio = itemSum / totals.total;
        if (ratio >= 0.8 && ratio <= 1.2) confidence += 0.1;
    }

    return Math.min(confidence, 1.0);
}

// ─────────────────────────────────────────────
// HEALTH CHECK
// ─────────────────────────────────────────────

/**
 * Check if Google Vision API is accessible with current credentials.
 */
export async function checkGoogleVisionHealth(): Promise<{
    available: boolean;
    project_id: string;
    error?: string;
}> {
    try {
        const creds = loadCredentials();
        await getAccessToken();
        return { available: true, project_id: creds.project_id };
    } catch (error) {
        return {
            available: false,
            project_id: "",
            error: error instanceof Error ? error.message : String(error),
        };
    }
}
