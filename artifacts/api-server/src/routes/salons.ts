import { Router, type IRouter } from "express";
import { db, salonsTable, servicesTable, staffTable, reviewsTable, favoritesTable, usersTable, bookingsTable } from "@workspace/db";
import { eq, desc, and, gte, like, sql } from "drizzle-orm";
import { requireAuth, optionalAuth } from "../middlewares/auth";

const router: IRouter = Router();

function salonToApi(salon: typeof salonsTable.$inferSelect, extras: { isFavorited?: boolean | null; distanceKm?: number | null } = {}) {
  return {
    id: salon.id,
    name: salon.name,
    description: salon.description,
    ownerId: salon.ownerId,
    address: salon.address,
    city: salon.city,
    state: salon.state,
    lat: salon.lat,
    lng: salon.lng,
    phone: salon.phone,
    imageUrl: salon.imageUrl,
    images: salon.images ?? [],
    avgRating: salon.avgRating,
    totalReviews: salon.totalReviews,
    isActive: salon.isActive,
    isVerified: salon.isVerified,
    openTime: salon.openTime,
    closeTime: salon.closeTime,
    totalSeats: salon.totalSeats ?? null,
    distanceKm: extras.distanceKm ?? null,
    isFavorited: extras.isFavorited ?? null,
    createdAt: salon.createdAt,
  };
}

// GET /api/salons/featured
router.get("/salons/featured", optionalAuth, async (req, res): Promise<void> => {
  const allSalons = await db.select().from(salonsTable).where(eq(salonsTable.isActive, true)).limit(30);

  let favSalonIds = new Set<number>();
  if (req.user) {
    const favRows = await db.select({ salonId: favoritesTable.salonId }).from(favoritesTable).where(eq(favoritesTable.userId, req.user.userId));
    favSalonIds = new Set(favRows.map((f) => f.salonId));
  }

  const withFav = (s: typeof salonsTable.$inferSelect) => salonToApi(s, { isFavorited: favSalonIds.has(s.id) });
  const topRated = [...allSalons].sort((a, b) => b.avgRating - a.avgRating).slice(0, 8).map(withFav);
  const trending = [...allSalons].sort((a, b) => b.totalBookings - a.totalBookings).slice(0, 8).map(withFav);
  const nearby = [...allSalons].slice(0, 8).map(withFav);

  res.json({ trending, topRated, nearby });
});

// GET /api/salons/my
router.get("/salons/my", requireAuth, async (req, res): Promise<void> => {
  const salons = await db.select().from(salonsTable).where(eq(salonsTable.ownerId, req.user!.userId));
  res.json(salons.map((s) => salonToApi(s)));
});

// GET /api/salons
router.get("/salons", optionalAuth, async (req, res): Promise<void> => {
  const { search, minRating, sortBy, page = "1", limit = "20" } = req.query as Record<string, string>;
  const pageNum = parseInt(page, 10);
  const limitNum = Math.min(parseInt(limit, 10), 50);
  const offset = (pageNum - 1) * limitNum;

  let conditions = [eq(salonsTable.isActive, true)];
  if (search) {
    conditions.push(like(salonsTable.name, `%${search}%`));
  }
  if (minRating) {
    conditions.push(gte(salonsTable.avgRating, parseFloat(minRating)));
  }

  const salons = await db.select().from(salonsTable).where(and(...conditions)).limit(limitNum).offset(offset);
  const [countRow] = await db.select({ count: sql<number>`count(*)::int` }).from(salonsTable).where(and(...conditions));

  let favSalonIds = new Set<number>();
  if (req.user) {
    const favRows = await db.select({ salonId: favoritesTable.salonId }).from(favoritesTable).where(eq(favoritesTable.userId, req.user.userId));
    favSalonIds = new Set(favRows.map((f) => f.salonId));
  }

  const result = salons.map((s) => salonToApi(s, { isFavorited: favSalonIds.has(s.id) }));

  res.json({
    salons: result,
    total: countRow?.count ?? 0,
    page: pageNum,
    limit: limitNum,
  });
});

// POST /api/salons
router.post("/salons", requireAuth, async (req, res): Promise<void> => {
  const { name, description, address, city, state, lat, lng, phone, imageUrl, images, openTime, closeTime } = req.body;
  if (!name || !address || !city) {
    res.status(400).json({ error: "name, address, and city are required" });
    return;
  }
  const { totalSeats } = req.body;
  const [salon] = await db.insert(salonsTable).values({
    name, description, ownerId: req.user!.userId, address, city, state, lat, lng, phone,
    imageUrl, images: images ?? [], openTime, closeTime, totalSeats: totalSeats ?? null,
  }).returning();
  res.status(201).json(salonToApi(salon));
});

// GET /api/salons/:id
router.get("/salons/:id", optionalAuth, async (req, res): Promise<void> => {
  const rawId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
  const id = parseInt(rawId, 10);
  const [salon] = await db.select().from(salonsTable).where(eq(salonsTable.id, id)).limit(1);
  if (!salon) {
    res.status(404).json({ error: "Salon not found" });
    return;
  }

  const [services, staff] = await Promise.all([
    db.select().from(servicesTable).where(and(eq(servicesTable.salonId, id), eq(servicesTable.isActive, true))),
    db.select().from(staffTable).where(eq(staffTable.salonId, id)),
  ]);

  const recentReviewsRaw = await db
    .select({ review: reviewsTable, user: usersTable })
    .from(reviewsTable)
    .leftJoin(usersTable, eq(reviewsTable.userId, usersTable.id))
    .where(eq(reviewsTable.salonId, id))
    .orderBy(desc(reviewsTable.createdAt))
    .limit(5);

  let isFavorited: boolean | null = null;
  if (req.user) {
    const [fav] = await db.select().from(favoritesTable).where(and(eq(favoritesTable.userId, req.user.userId), eq(favoritesTable.salonId, id))).limit(1);
    isFavorited = !!fav;
  }

  const recentReviews = recentReviewsRaw.map(({ review, user }) => ({
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
    ...salonToApi(salon, { isFavorited }),
    services,
    staff,
    recentReviews,
  });
});

// PATCH /api/salons/:id
router.patch("/salons/:id", requireAuth, async (req, res): Promise<void> => {
  const rawId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
  const id = parseInt(rawId, 10);
  const [existing] = await db.select().from(salonsTable).where(eq(salonsTable.id, id)).limit(1);
  if (!existing) {
    res.status(404).json({ error: "Salon not found" });
    return;
  }
  if (existing.ownerId !== req.user!.userId && req.user!.role !== "admin") {
    res.status(403).json({ error: "Forbidden" });
    return;
  }
  const { name, description, address, city, state, lat, lng, phone, imageUrl, images, openTime, closeTime, isActive, totalSeats } = req.body;
  const [salon] = await db.update(salonsTable).set({ name, description, address, city, state, lat, lng, phone, imageUrl, images, openTime, closeTime, isActive, totalSeats: totalSeats ?? undefined }).where(eq(salonsTable.id, id)).returning();
  res.json(salonToApi(salon));
});

// GET /api/salons/:id/stats
router.get("/salons/:id/stats", requireAuth, async (req, res): Promise<void> => {
  const rawId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
  const id = parseInt(rawId, 10);
  const [salon] = await db.select().from(salonsTable).where(eq(salonsTable.id, id)).limit(1);
  if (!salon) {
    res.status(404).json({ error: "Salon not found" });
    return;
  }

  const allBookings = await db.select().from(bookingsTable).where(eq(bookingsTable.salonId, id));
  const now = new Date();
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
  const thisMonthBookings = allBookings.filter((b) => new Date(b.createdAt) >= monthStart);
  const completedBookings = allBookings.filter((b) => b.status === "completed");
  const thisMonthCompleted = thisMonthBookings.filter((b) => b.status === "completed");

  const uniqueCustomers = new Set(allBookings.map((b) => b.userId)).size;
  const byStatus = {
    pending: allBookings.filter((b) => b.status === "pending").length,
    accepted: allBookings.filter((b) => b.status === "accepted").length,
    in_progress: allBookings.filter((b) => b.status === "in_progress").length,
    completed: completedBookings.length,
    cancelled: allBookings.filter((b) => b.status === "cancelled").length,
  };

  res.json({
    totalBookings: allBookings.length,
    totalRevenue: completedBookings.reduce((sum, b) => sum + b.totalPrice, 0),
    activeCustomers: uniqueCustomers,
    avgRating: salon.avgRating,
    totalReviews: salon.totalReviews,
    thisMonthBookings: thisMonthBookings.length,
    thisMonthRevenue: thisMonthCompleted.reduce((sum, b) => sum + b.totalPrice, 0),
    bookingsByStatus: byStatus,
  });
});

// GET /api/salons/:id/availability
router.get("/salons/:id/availability", async (req, res): Promise<void> => {
  const rawId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
  const id = parseInt(rawId, 10);
  const { date } = req.query as Record<string, string>;
  if (!date) {
    res.status(400).json({ error: "date is required" });
    return;
  }

  const [salon] = await db.select().from(salonsTable).where(eq(salonsTable.id, id)).limit(1);
  if (!salon) {
    res.status(404).json({ error: "Salon not found" });
    return;
  }

  const dayBookings = await db.select().from(bookingsTable).where(and(eq(bookingsTable.salonId, id), eq(bookingsTable.bookingDate, date)));
  const bookedTimes = new Set(dayBookings.filter((b) => b.status !== "cancelled").map((b) => b.startTime));

  const open = salon.openTime ?? "09:00";
  const close = salon.closeTime ?? "20:00";
  const [openH, openM] = open.split(":").map(Number);
  const [closeH, closeM] = close.split(":").map(Number);
  const slots: { time: string; available: boolean; staffId: null }[] = [];
  let h = openH, m = openM;
  while (h < closeH || (h === closeH && m < closeM)) {
    const time = `${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}`;
    slots.push({ time, available: !bookedTimes.has(time), staffId: null });
    m += 30;
    if (m >= 60) { h += 1; m -= 60; }
  }

  res.json(slots);
});

export default router;
