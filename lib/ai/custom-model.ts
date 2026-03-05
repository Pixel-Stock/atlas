/**
 * ATLAS Custom ML Model — TypeScript Integration
 * ================================================
 * Drop this file at: lib/ai/custom-model.ts
 *
 * This module is the custom ML model side of the dual-model pipeline.
 * It calls the Python ONNX inference server (server.py) and returns
 * a result in the same shape as the Gemini module so pipeline.ts
 * can compare confidence scores and pick the winner.
 *
 * In browser contexts (future TF.js support), it falls back gracefully.
 */

import { ATLASReceiptResult, LineItem, ModelSource } from "@/types";

// ─────────────────────────────────────────────
// TYPES
// ─────────────────────────────────────────────

interface MLServerPrediction {
  predicted_class: string;
  class_index: number;
  confidence: number;
  confidence_tier: "high" | "medium" | "low";
  all_probabilities: Record<string, number>;
  model_version: string;
  inference_time_ms: number;
  action: "auto_accept" | "confirm" | "retake";
}

interface MLModelConfig {
  serverUrl: string;
  timeoutMs: number;
  modelVersion: string;
}

// ─────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────

const ML_CONFIG: MLModelConfig = {
  serverUrl:    process.env.ATLAS_ML_SERVER_URL ?? "http://localhost:8001",
  timeoutMs:    8000,   // 8s timeout — if ML server is slow, Gemini wins by default
  modelVersion: "1.0.0",
};

// ─────────────────────────────────────────────
// HEALTH CHECK
// ─────────────────────────────────────────────

let _serverHealthy: boolean | null = null;
let _lastHealthCheck = 0;
const HEALTH_CHECK_TTL_MS = 30_000; // recheck every 30s

async function isServerHealthy(): Promise<boolean> {
  const now = Date.now();
  if (_serverHealthy !== null && now - _lastHealthCheck < HEALTH_CHECK_TTL_MS) {
    return _serverHealthy;
  }

  try {
    const response = await fetch(`${ML_CONFIG.serverUrl}/health`, {
      signal: AbortSignal.timeout(2000),
    });
    const data = await response.json();
    _serverHealthy = data.status === "ok" && data.model_loaded === true;
  } catch {
    _serverHealthy = false;
  }

  _lastHealthCheck = now;
  return _serverHealthy!;
}

// ─────────────────────────────────────────────
// CORE PREDICTION
// ─────────────────────────────────────────────

/**
 * Sends image to the Python ONNX inference server.
 * Returns null if server is unavailable (Gemini takes over).
 */
async function callMLServer(
  imageBlob: Blob,
): Promise<MLServerPrediction | null> {
  const healthy = await isServerHealthy();
  if (!healthy) {
    if (process.env.NODE_ENV === "development") {
      console.warn("[ATLAS/ML] Server unavailable — Gemini will be used");
    }
    return null;
  }

  const formData = new FormData();
  formData.append("file", imageBlob, "receipt.jpg");

  try {
    const controller = new AbortController();
    const timeout    = setTimeout(() => controller.abort(), ML_CONFIG.timeoutMs);

    const response = await fetch(`${ML_CONFIG.serverUrl}/predict`, {
      method: "POST",
      body:   formData,
      signal: controller.signal,
    });

    clearTimeout(timeout);

    if (!response.ok) {
      const err = await response.text();
      throw new Error(`ML server returned ${response.status}: ${err}`);
    }

    return (await response.json()) as MLServerPrediction;
  } catch (error) {
    if (error instanceof Error && error.name === "AbortError") {
      console.error(`[ATLAS/ML] Timeout after ${ML_CONFIG.timeoutMs}ms`);
    } else {
      console.error("[ATLAS/ML] Prediction error:", error);
    }
    return null;
  }
}

// ─────────────────────────────────────────────
// RESULT MAPPER
// ─────────────────────────────────────────────

/**
 * Maps ML server output → ATLASReceiptResult shape.
 * This is intentionally lightweight — the ML model is a receipt detector/classifier,
 * not a text extractor. Line items are extracted by Gemini.
 * The ML model's job is to:
 *   1. Validate: is this actually a receipt?
 *   2. Classify: what type?
 *   3. Quality check: is image good enough for OCR?
 */
function mapMLResultToAtlasFormat(
  prediction: MLServerPrediction,
): Partial<ATLASReceiptResult> {
  // Derive category hint from predicted class name
  const classLower = prediction.predicted_class.toLowerCase();

  const categoryMap: Record<string, string> = {
    grocery:      "Groceries",
    food:         "Food & Dining",
    restaurant:   "Food & Dining",
    medical:      "Health & Medicine",
    pharmacy:     "Health & Medicine",
    health:       "Health & Medicine",
    electronics:  "Electronics",
    clothing:     "Clothing & Fashion",
    fashion:      "Clothing & Fashion",
    transport:    "Transport",
    fuel:         "Transport",
    home:         "Home & Household",
    utility:      "Home & Household",
    entertainment:"Entertainment",
    education:    "Education",
    takeout:      "Takeout & Delivery",
    delivery:     "Takeout & Delivery",
  };

  let categoryHint: string | undefined;
  for (const [key, category] of Object.entries(categoryMap)) {
    if (classLower.includes(key)) {
      categoryHint = category;
      break;
    }
  }

  return {
    overall_confidence: prediction.confidence,
    ml_classification:  prediction.predicted_class,
    category_hint:      categoryHint,
    ml_action:          prediction.action,
    ml_inference_ms:    prediction.inference_time_ms,
    model_version:      prediction.model_version,
  };
}

// ─────────────────────────────────────────────
// PUBLIC API
// ─────────────────────────────────────────────

export interface CustomMLResult {
  /** Overall confidence score 0.0–1.0. 0 means model unavailable. */
  confidence:        number;
  /** Predicted receipt class (e.g. "grocery", "restaurant") */
  predicted_class:   string;
  /** Confidence tier: high | medium | low */
  confidence_tier:   "high" | "medium" | "low";
  /** Category hint for downstream categorization */
  category_hint:     string | undefined;
  /** What ATLAS should do with this result */
  action:            "auto_accept" | "confirm" | "retake";
  /** Inference time in ms */
  inference_time_ms: number;
  /** Whether the ML server was available */
  server_available:  boolean;
  /** Model version */
  model_version:     string;
}

/**
 * Main entry point called by pipeline.ts
 *
 * @param imageBlob - The receipt image as a Blob
 * @returns CustomMLResult — confidence 0 if server unavailable (Gemini wins)
 */
export async function runCustomMLModel(
  imageBlob: Blob,
): Promise<CustomMLResult> {
  const prediction = await callMLServer(imageBlob);

  // Server unavailable → return 0 confidence so Gemini wins
  if (!prediction) {
    return {
      confidence:        0,
      predicted_class:   "unknown",
      confidence_tier:   "low",
      category_hint:     undefined,
      action:            "retake",
      inference_time_ms: 0,
      server_available:  false,
      model_version:     ML_CONFIG.modelVersion,
    };
  }

  const mapped = mapMLResultToAtlasFormat(prediction);

  return {
    confidence:        prediction.confidence,
    predicted_class:   prediction.predicted_class,
    confidence_tier:   prediction.confidence_tier,
    category_hint:     mapped.category_hint,
    action:            prediction.action,
    inference_time_ms: prediction.inference_time_ms,
    server_available:  true,
    model_version:     prediction.model_version,
  };
}

/**
 * Check if ML server is reachable.
 * Call this on app startup to show server status in admin panel.
 */
export async function getMLServerStatus(): Promise<{
  healthy:       boolean;
  version:       string;
  model_loaded:  boolean;
}> {
  try {
    const response = await fetch(`${ML_CONFIG.serverUrl}/health`, {
      signal: AbortSignal.timeout(3000),
    });
    const data = await response.json();
    return {
      healthy:      data.status === "ok",
      version:      data.model_version ?? "unknown",
      model_loaded: data.model_loaded ?? false,
    };
  } catch {
    return { healthy: false, version: "unreachable", model_loaded: false };
  }
}

/**
 * Get class labels from ML server.
 * Used in admin panel to display model info.
 */
export async function getMLModelClasses(): Promise<Record<string, string>> {
  try {
    const response = await fetch(`${ML_CONFIG.serverUrl}/classes`, {
      signal: AbortSignal.timeout(3000),
    });
    return await response.json();
  } catch {
    return {};
  }
}
