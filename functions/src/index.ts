import * as admin from "firebase-admin";
import { setGlobalOptions } from "firebase-functions/v2";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";

setGlobalOptions({
  region: "southamerica-east1",
  memory: "256MiB",
  timeoutSeconds: 60,
});

admin.initializeApp();
const db = admin.firestore();

type CommentData = {
  status?: string;
  createdAt?: FirebaseFirestore.FieldValue | admin.firestore.Timestamp;
  rating?: number;
  userId?: string;
};

// --- STATES (unificados) ---
const PENDING = "pending";
const APPROVED = "approved";
const REJECTED = "rejected";

/**
 * Al crear comentario en POI (LEGADO): forzar status='pending', createdAt y normalizar rating 1..5
 */
export const onCommentCreateForcePending = onDocumentCreated(
  "pois/{poiId}/comments/{commentId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const d = snap.data() as CommentData;
    const patch: Record<string, unknown> = {};

    if (d?.status !== PENDING) patch.status = PENDING;
    if (!d?.createdAt) patch.createdAt = admin.firestore.FieldValue.serverTimestamp();

    const r = typeof d?.rating === "number" ? Math.round(d.rating) : 0;
    patch.rating = Math.max(1, Math.min(5, r || 1));

    if (Object.keys(patch).length > 0) {
      await snap.ref.update(patch);
    }
  }
);

/**
 * Si pasa a 'approved' en POI (LEGADO), recalcular ratingAvg y ratingCount del POI
 */
export const onCommentApproveUpdate = onDocumentUpdated(
  "pois/{poiId}/comments/{commentId}",
  async (event) => {
    const before = event.data?.before.data() as CommentData | undefined;
    const after = event.data?.after.data() as CommentData | undefined;
    if (!before || !after) return;

    if (before.status === APPROVED || after.status !== APPROVED) return;

    const { poiId } = event.params as { poiId: string };
    const poiRef = db.doc(`pois/${poiId}`);

    const approvedSnap = await poiRef.collection("comments").where("status", "==", APPROVED).get();

    let sum = 0;
    approvedSnap.forEach((doc) => {
      const data = doc.data() as CommentData;
      const rating = typeof data.rating === "number" ? data.rating : 0;
      sum += rating;
    });

    const count = approvedSnap.size;
    const avg = count > 0 ? Number((sum / count).toFixed(2)) : 0;

    await poiRef.update({
      ratingAvg: avg,
      ratingCount: count,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
);

// ===== POIs (LEGADO) =====
export const approveComment = onCall(async (req) => {
  const auth = req.auth;
  if (!auth || auth.token?.role !== "admin") {
    throw new HttpsError("permission-denied", "Admin only");
  }
  const { poiId, commentId } = (req.data ?? {}) as { poiId?: string; commentId?: string };
  if (!poiId || !commentId) throw new HttpsError("invalid-argument", "poiId and commentId are required");

  await db.doc(`pois/${poiId}/comments/${commentId}`).update({
    status: APPROVED,
    approvedAt: admin.firestore.FieldValue.serverTimestamp(),
    approvedBy: auth.uid,
  });
  return { ok: true };
});

export const rejectComment = onCall(async (req) => {
  const auth = req.auth;
  if (!auth || auth.token?.role !== "admin") {
    throw new HttpsError("permission-denied", "Admin only");
  }
  const { poiId, commentId } = (req.data ?? {}) as { poiId?: string; commentId?: string };
  if (!poiId || !commentId) throw new HttpsError("invalid-argument", "poiId and commentId are required");

  await db.doc(`pois/${poiId}/comments/${commentId}`).update({
    status: REJECTED,
    rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
    rejectedBy: auth.uid,
  });
  return { ok: true };
});

// ===== Categorías (VIGENTE) =====
export const approveCategoryComment = onCall(async (req) => {
  const auth = req.auth;
  if (!auth || auth.token?.role !== "admin") {
    throw new HttpsError("permission-denied", "Admin only");
  }
  const { categoryId, commentId } = (req.data ?? {}) as { categoryId?: string; commentId?: string };
  if (!categoryId || !commentId) throw new HttpsError("invalid-argument", "categoryId and commentId are required");

  await db.doc(`categories/${categoryId}/comments/${commentId}`).update({
    status: APPROVED,
    approvedAt: admin.firestore.FieldValue.serverTimestamp(),
    approvedBy: auth.uid,
  });
  return { ok: true };
});

export const rejectCategoryComment = onCall(async (req) => {
  const auth = req.auth;
  if (!auth || auth.token?.role !== "admin") {
    throw new HttpsError("permission-denied", "Admin only");
  }
  const { categoryId, commentId } = (req.data ?? {}) as { categoryId?: string; commentId?: string };
  if (!categoryId || !commentId) throw new HttpsError("invalid-argument", "categoryId and commentId are required");

  await db.doc(`categories/${categoryId}/comments/${commentId}`).update({
    status: REJECTED,
    rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
    rejectedBy: auth.uid,
  });
  return { ok: true };
});

/** Conceder admin (para dev / botón MakeMeAdmin) */
export const grantAdmin = onCall(async (req) => {
  const caller = req.auth;
  const { uid } = (req.data ?? {}) as { uid?: string };
  if (!uid) throw new HttpsError("invalid-argument", "uid required");

  const allowDev = true; // ⚠️ desactiva en producción
  const callerIsAdmin = caller?.token?.role === "admin";
  const callerSelfDev = allowDev && caller?.uid === uid;

  if (!callerIsAdmin && !callerSelfDev) {
    throw new HttpsError("permission-denied", "Admin only (or self-grant in dev)");
  }

  await admin.auth().setCustomUserClaims(uid, { role: "admin" });
  return { ok: true };
});
