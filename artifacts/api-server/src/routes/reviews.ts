import { Router, type IRouter } from "express";
import { db, reviewsTable, salonsTable, usersTable } from "@workspace/db";
import { eq, desc, avg, count, sql } from "drizzle-orm";
import { requireAuth, optionalAuth } from "../middlewares/auth";

const router: IRouter = Router();

router.get("/salons/:salonId/reviews", optionalAuth, async (req, res): Promise<void> => {
  const rawId = Array.isArray(req.params.salonId) ? req.params.salonId[0] : req.params.salonId;
  const salonId = parseInt(rawId, 10);
  const { page = "1", limit = "10" } = req.query as Record<string, string>;
  const pageNum = parseInt(page, 10);
  const limitNum = parseInt(limit, 10);
  const offset = (pageNum - 1) * limitNum;

  const reviewsWithUsers = await db
    .select({ review: reviewsTable, user: usersTable })
    .from(reviewsTable)
    .leftJoin(usersTable, eq(reviewsTable.userId, usersTable.id))
    .where(eq(reviewsTable.salonId, salonId))
    .orderBy(desc(reviewsTable.createdAt))
    .limit(limitNum)
    .offset(offset);

  const [totalRow] = await db.select({ count: sql<number>`count(*)::int` }).from(reviewsTable).where(eq(reviewsTable.salonId, salonId));
  const [avgRow] = await db.select({ avg: avg(reviewsTable.rating) }).from(reviewsTable).where(eq(reviewsTable.salonId, salonId));

  const reviews = reviewsWithUsers.map(({ review, user }) => ({
    id: review.id,
    userId: review.userId,
    salonId: review.salonId,
    bookingId: review.bookingId,
    rating: review.rating,
    comment: review.comment,
    createdAt: review.createdAt,
    user: user ? { id: user.id, name: user.name, email: user.email, phone: user.phone, avatarUrl: user.avatarUrl, role: user.role, createdAt: user.createdAt } : undefined,
  }));

  res.json({
    reviews,
    total: totalRow?.count ?? 0,
    page: pageNum,
    limit: limitNum,
    avgRating: parseFloat(avgRow?.avg ?? "0") || 0,
  });
});

router.post("/salons/:salonId/reviews", requireAuth, async (req, res): Promise<void> => {
  const rawId = Array.isArray(req.params.salonId) ? req.params.salonId[0] : req.params.salonId;
  const salonId = parseInt(rawId, 10);
  const { rating, comment, bookingId } = req.body;
  if (!rating || rating < 1 || rating > 5) {
    res.status(400).json({ error: "rating must be between 1 and 5" });
    return;
  }
  const [review] = await db.insert(reviewsTable).values({
    userId: req.user!.userId,
    salonId,
    rating,
    comment: comment ?? null,
    bookingId: bookingId ?? null,
  }).returning();

  // Update salon avg rating
  const [avgRow] = await db.select({ avg: avg(reviewsTable.rating), cnt: count() }).from(reviewsTable).where(eq(reviewsTable.salonId, salonId));
  const newAvg = parseFloat(avgRow?.avg ?? "0") || 0;
  const newCount = avgRow?.cnt ?? 0;
  await db.update(salonsTable).set({ avgRating: newAvg, totalReviews: newCount }).where(eq(salonsTable.id, salonId));

  const [user] = await db.select().from(usersTable).where(eq(usersTable.id, req.user!.userId)).limit(1);
  res.status(201).json({
    id: review.id,
    userId: review.userId,
    salonId: review.salonId,
    bookingId: review.bookingId,
    rating: review.rating,
    comment: review.comment,
    createdAt: review.createdAt,
    user: user ? { id: user.id, name: user.name, email: user.email, phone: user.phone, avatarUrl: user.avatarUrl, role: user.role, createdAt: user.createdAt } : undefined,
  });
});

export default router;
