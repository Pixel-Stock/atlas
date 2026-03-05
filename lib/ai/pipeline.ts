/**
 * ATLAS Dual-Model Pipeline v2 — pipeline.ts
 * =============================================
 * Drop this file at: lib/ai/pipeline.ts
 *
 * Phase 2 UPDATE:
 *   - Imports from crowdtag.ts (not crowdtag-stub.ts)
 *   - Adds Step 0: CrowdTag pre-resolution before AI categorization
 *   - Adds logManualCorrection() for user corrections
 *   - Adds multi-category distribution for "Other" line items
 *
 * Everything else (dual-model, confidence scoring, torn receipt mode,
 * quality gate, error handling) is identical to Phase 1.
 */

import { analyzeReceiptWithGemini } from "./gemini";
import { runCustomMLModel } from "./custom-model";
import { runGoogleVisionOCR, parseReceiptText } from "./google-vision";
import { resolveMerchant, logMerchantVote } from "./crowdtag";
import type { ATLASReceiptResult } from "@/types";

// ─────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────

const CONFIDENCE_REJECT_THRESHOLD = 0.60;  // below this → ask user to retake
const CONFIDENCE_WARN_THRESHOLD = 0.85;  // below this → amber badge, above → green

// ─────────────────────────────────────────────
// ERROR TYPE
// ─────────────────────────────────────────────

export interface ScanError {
  code: string;
  message: string;
  confidence?: number;
  retryable: boolean;
}

// ─────────────────────────────────────────────
// RESULT TYPE
// ─────────────────────────────────────────────

export type PipelineResult =
  | { success: true; data: ATLASReceiptResult }
  | { success: false; error: ScanError };

// ─────────────────────────────────────────────
// MAIN PIPELINE
// ─────────────────────────────────────────────

/**
 * runScanPipeline
 * ---------------
 * Phase 2 flow:
 * 0. CrowdTag pre-resolution (NEW)
 * 1. Run Gemini Vision + Custom ML model in parallel
 * 2. Compare confidence scores
 * 3. Winner's result is used
 * 4. Apply CrowdTag multi-category distribution if applicable
 * 5. Log merchant vote for CrowdTag
 * 6. Return structured result
 */
export async function runScanPipeline(
  imageBlob: Blob,
  userId: string,
  isTornMode = false,
  receiptId?: string,
): Promise<PipelineResult> {
  const startTime = Date.now();

  // ── Run ALL models in parallel (Gemini + ML + Google Vision OCR) ────
  const imageBuffer = Buffer.from(await imageBlob.arrayBuffer());
  const mimeType = imageBlob.type || "image/jpeg";

  const [geminiResult, mlResult, visionResult] = await Promise.allSettled([
    analyzeReceiptWithGemini(imageBuffer, mimeType),
    runCustomMLModel(imageBlob),
    runGoogleVisionOCR(imageBuffer, mimeType),
  ]);

  // ── Extract results ──────────────────────────────────────────────────
  let gemini = geminiResult.status === "fulfilled" ? geminiResult.value : null;
  const ml = mlResult.status === "fulfilled" ? mlResult.value : null;
  const vision = visionResult.status === "fulfilled" ? visionResult.value : null;

  // Google Vision OCR fallback: if Gemini failed or gave low confidence,
  // try to parse the Google Vision raw text as a structured receipt
  if ((!gemini || gemini.overall_confidence < 0.5) && vision && vision.raw_text.length > 20) {
    const visionParsed = parseReceiptText(vision.raw_text);
    if (visionParsed.overall_confidence && visionParsed.overall_confidence > (gemini?.overall_confidence ?? 0)) {
      console.log(`[ATLAS/pipeline] Google Vision OCR fallback activated (Vision conf: ${vision.confidence.toFixed(3)})`);
      gemini = {
        merchant_name: visionParsed.merchant_name || gemini?.merchant_name || "Unknown",
        receipt_date: visionParsed.receipt_date || gemini?.receipt_date || null,
        total_amount: visionParsed.total_amount || gemini?.total_amount || 0,
        currency: visionParsed.currency || gemini?.currency || "INR",
        line_items: visionParsed.line_items || gemini?.line_items || [],
        subtotal: visionParsed.subtotal ?? gemini?.subtotal ?? null,
        tax: visionParsed.tax ?? gemini?.tax ?? null,
        discount: visionParsed.discount ?? gemini?.discount ?? null,
        overall_confidence: visionParsed.overall_confidence,
      };
    }
  }

  const geminiConf = gemini?.overall_confidence ?? 0;
  const mlConf = ml?.confidence ?? 0;

  if (process.env.NODE_ENV === "development") {
    console.log(`[ATLAS/pipeline] Gemini confidence: ${geminiConf.toFixed(3)}`);
    console.log(`[ATLAS/pipeline] ML confidence:     ${mlConf.toFixed(3)}`);
  }

  // ── Both failed ───────────────────────────────────────────────────────
  if (!gemini && !ml) {
    return {
      success: false,
      error: {
        code: "BOTH_MODELS_FAILED",
        message: "Receipt scanning is temporarily unavailable. Please try again.",
        retryable: true,
      },
    };
  }

  // ── Pick winner ───────────────────────────────────────────────────────
  let winnerSource: "gemini" | "custom_ml";
  let winningConfidence: number;

  if (!gemini) {
    winnerSource = "custom_ml";
    winningConfidence = mlConf;
  } else if (!ml || mlConf === 0) {
    winnerSource = "gemini";
    winningConfidence = geminiConf;
  } else {
    winnerSource = geminiConf >= mlConf ? "gemini" : "custom_ml";
    winningConfidence = Math.max(geminiConf, mlConf);
  }

  // ── Quality gate ──────────────────────────────────────────────────────
  if (winningConfidence < CONFIDENCE_REJECT_THRESHOLD) {
    return {
      success: false,
      error: {
        code: "LOW_CONFIDENCE",
        message: isTornMode
          ? "Even in torn receipt mode, the image quality is too low. Make sure both halves are well-lit and fully visible."
          : "Image quality is too low to read this receipt. Please retake the photo in better lighting.",
        confidence: winningConfidence,
        retryable: true,
      },
    };
  }

  // ── Use Gemini result as primary (it has full text extraction) ─────────
  if (!gemini) {
    return {
      success: false,
      error: {
        code: "GEMINI_UNAVAILABLE",
        message: "Text extraction is temporarily unavailable. Please try again.",
        retryable: true,
      },
    };
  }

  // ── PHASE 2: CrowdTag pre-resolution ─────────────────────────────────
  let crowdtagHit = false;
  let crowdtagCategory: string | undefined;
  let crowdtagConfidence: number | undefined;
  let crowdtagIsMulti = false;
  let crowdtagDistribution: Record<string, number> | undefined;

  if (gemini.merchant_name) {
    try {
      const resolution = await resolveMerchant(gemini.merchant_name, "");
      if (resolution.found && resolution.is_resolved && resolution.confidence && resolution.confidence >= 0.75) {
        crowdtagHit = true;
        crowdtagCategory = resolution.dominant_category;
        crowdtagConfidence = resolution.confidence;
        crowdtagIsMulti = resolution.is_multi_category ?? false;
        crowdtagDistribution = resolution.category_distribution;

        if (process.env.NODE_ENV === "development") {
          console.log(`[ATLAS/pipeline] CrowdTag HIT: ${gemini.merchant_name} → ${crowdtagCategory} (${crowdtagConfidence})`);
        }
      }
    } catch (err) {
      // CrowdTag failure must never block the main pipeline
      console.error("[ATLAS/pipeline] CrowdTag pre-resolution failed:", err);
    }
  }

  // ── Apply ML category hint if confidence is high enough ───────────────
  let enrichedResult = { ...gemini };
  if (ml && ml.server_available && ml.confidence >= 0.70 && ml.category_hint) {
    enrichedResult = applyMLCategoryHint(enrichedResult, ml.category_hint);
  }

  // ── Apply CrowdTag multi-category distribution to "Other" items ──────
  if (crowdtagHit && crowdtagIsMulti && crowdtagDistribution) {
    enrichedResult = applyCrowdTagDistribution(enrichedResult, crowdtagDistribution);
  } else if (crowdtagHit && crowdtagCategory) {
    // Single-category CrowdTag resolution → apply to "Other" items
    enrichedResult = applyMLCategoryHint(enrichedResult, crowdtagCategory);
  }

  // ── Build final result ────────────────────────────────────────────────
  const result: ATLASReceiptResult = {
    ...enrichedResult,
    merchant_name: gemini.merchant_name,
    receipt_date: gemini.receipt_date,
    total_amount: gemini.total_amount,
    currency: gemini.currency,
    items: enrichedResult.line_items ?? [],
    subtotal: gemini.subtotal,
    tax: gemini.tax,
    discount: gemini.discount,
    model_used: winnerSource,
    overall_confidence: winningConfidence,
    gemini_confidence: geminiConf,
    ml_confidence: mlConf,
    ml_server_available: ml?.server_available ?? false,
    confidence_tier: getConfidenceTier(winningConfidence),
    processing_time_ms: Date.now() - startTime,
    is_torn_receipt: isTornMode,
    // CrowdTag Phase 2 fields
    crowdtag_hit: crowdtagHit,
    crowdtag_category: crowdtagCategory,
    crowdtag_confidence: crowdtagConfidence,
    crowdtag_is_multi_category: crowdtagIsMulti,
    crowdtag_distribution: crowdtagDistribution,
  };

  // ── CrowdTag vote logging (non-blocking) ──────────────────────────────
  if (result.merchant_name && result.items && result.items.length > 0) {
    const dominantCategory = getDominantCategory(result.items);
    logMerchantVote({
      merchantName: result.merchant_name,
      city: "",
      category: crowdtagCategory ?? dominantCategory,
      userId,
      confidence: winningConfidence,
      receiptId,
      isManual: false,
    }).catch((err) => {
      console.error("[ATLAS/crowdtag] Vote logging failed:", err);
    });
  }

  return { success: true, data: result };
}

// ─────────────────────────────────────────────
// MANUAL CORRECTION (Phase 2)
// ─────────────────────────────────────────────

/**
 * logManualCorrection
 * -------------------
 * Call this when a user manually corrects a category in the line item review UI.
 * Manual corrections get confidence=1.0 — the strongest possible vote signal.
 */
export async function logManualCorrection(params: {
  merchantName: string;
  city?: string;
  correctedCategory: string;
  userId: string;
  receiptId?: string;
}): Promise<void> {
  try {
    await logMerchantVote({
      merchantName: params.merchantName,
      city: params.city,
      category: params.correctedCategory,
      userId: params.userId,
      confidence: 1.0,   // maximum confidence for manual corrections
      receiptId: params.receiptId,
      isManual: true,
    });
  } catch (err) {
    console.error("[ATLAS/pipeline] Manual correction logging failed:", err);
  }
}

// ─────────────────────────────────────────────
// TORN RECEIPT MODE
// ─────────────────────────────────────────────

/**
 * runTornReceiptPipeline
 * ----------------------
 * Scans two image halves separately, merges line items.
 * Uses positional heuristics to avoid duplicate items.
 */
export async function runTornReceiptPipeline(
  topBlob: Blob,
  bottomBlob: Blob,
  userId: string,
): Promise<PipelineResult> {
  const [topResult, bottomResult] = await Promise.all([
    runScanPipeline(topBlob, userId, true),
    runScanPipeline(bottomBlob, userId, true),
  ]);

  if (!topResult.success && !bottomResult.success) {
    return {
      success: false,
      error: {
        code: "TORN_RECEIPT_BOTH_FAILED",
        message: "Could not read either half of the receipt. Please ensure both halves are flat and well-lit.",
        retryable: true,
      },
    };
  }

  if (!topResult.success) return bottomResult;
  if (!bottomResult.success) return topResult;

  const merged = mergeReceiptResults(topResult.data, bottomResult.data);
  return { success: true, data: merged };
}

// ─────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────

/**
 * Find the dominant category across line items by total spend amount.
 * This is more accurate than just using the first item's category.
 */
function getDominantCategory(items: ATLASReceiptResult["items"]): string {
  if (!items || items.length === 0) return "Other";
  const spendByCategory: Record<string, number> = {};
  for (const item of items) {
    const cat = item.category ?? "Other";
    spendByCategory[cat] = (spendByCategory[cat] ?? 0) + (item.total_price ?? 0);
  }
  const sorted = Object.entries(spendByCategory).sort(([, a], [, b]) => b - a);
  return sorted[0]?.[0] ?? "Other";
}

function getConfidenceTier(confidence: number): "high" | "medium" | "low" {
  if (confidence >= CONFIDENCE_WARN_THRESHOLD) return "high";
  if (confidence >= CONFIDENCE_REJECT_THRESHOLD) return "medium";
  return "low";
}

/**
 * If ML model strongly identifies the receipt type, apply that as
 * a default category for line items that Gemini categorized as "Other".
 */
function applyMLCategoryHint(
  result: any,
  categoryHint: string,
): any {
  return {
    ...result,
    line_items: result.line_items?.map((item: any) => ({
      ...item,
      category: item.category === "Other" ? categoryHint : item.category,
    })),
  };
}

/**
 * Phase 2: Distribute "Other" line items across CrowdTag's multi-category
 * distribution. E.g., if DMart is 60% Groceries / 25% Home / 15% Personal Care,
 * "Other" items get distributed proportionally.
 */
function applyCrowdTagDistribution(
  result: any,
  distribution: Record<string, number>,
): any {
  const categories = Object.entries(distribution).sort((a, b) => b[1] - a[1]);
  if (categories.length === 0) return result;

  const otherItems = result.line_items?.filter((item: any) => item.category === "Other") ?? [];
  if (otherItems.length === 0) return result;

  // Round-robin assign "Other" items proportionally
  let itemIndex = 0;
  const totalPercent = categories.reduce((sum, [, pct]) => sum + pct, 0);
  const assignments: string[] = [];

  for (const [cat, pct] of categories) {
    const count = Math.round((pct / totalPercent) * otherItems.length);
    for (let i = 0; i < count && assignments.length < otherItems.length; i++) {
      assignments.push(cat);
    }
  }
  // Fill remaining with dominant category
  while (assignments.length < otherItems.length) {
    assignments.push(categories[0][0]);
  }

  return {
    ...result,
    line_items: result.line_items?.map((item: any) => {
      if (item.category === "Other" && itemIndex < assignments.length) {
        return { ...item, category: assignments[itemIndex++] };
      }
      return item;
    }),
  };
}

/**
 * Merge two receipt halves. Deduplicates line items by name + amount.
 * Takes merchant/date/total from whichever half has higher confidence.
 */
function mergeReceiptResults(
  top: ATLASReceiptResult,
  bottom: ATLASReceiptResult,
): ATLASReceiptResult {
  const primary = top.overall_confidence >= bottom.overall_confidence ? top : bottom;

  // Merge line items, deduplicate by name+amount fingerprint
  const seen = new Set<string>();
  const allItems = [...(top.items ?? []), ...(bottom.items ?? [])];
  const dedupedItems = allItems.filter((item) => {
    const key = `${item.name.toLowerCase().trim()}:${item.total_price}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });

  const mergedTotal = dedupedItems.reduce((sum, item) => sum + item.total_price, 0);

  return {
    ...primary,
    items: dedupedItems,
    total_amount: mergedTotal,
    overall_confidence: (top.overall_confidence + bottom.overall_confidence) / 2,
    is_torn_receipt: true,
    notes: "Merged from two receipt halves",
    gemini_confidence: primary.gemini_confidence,
    ml_confidence: primary.ml_confidence,
  };
}
