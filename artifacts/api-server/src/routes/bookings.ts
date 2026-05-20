import { Router, type IRouter } from "express";
import { db, bookingsTable, salonsTable, servicesTable, staffTable, usersTable } from "@workspace/db";
import { eq, and, desc, inArray } from "drizzle-orm";
import { requireAuth } from "../middlewares/auth";

const router: IRouter = Router();

async function enrichBooking(booking: typeof bookingsTable.$inferSelect) {
  const [salon, service, user] = await Promise.all([
    db.select().from(salonsTable).where(eq(salonsTable.id, booking.salonId)).limit(1),
    db.select().from(servicesTable).where(eq(servicesTable.id, booking.serviceId)).limit(1),
    db.select().from(usersTable).where(eq(usersTable.id, booking.userId)).limit(1),
  ]);
  let staffMember = null;
  if (booking.staffId) {
    const [s] = await db.select().from(staffTable).where(eq(staffTable.id, booking.staffId)).limit(1);
    staffMember = s ?? null;
  }
  const u = user[0];
  return {
    ...booking,
    salon: salon[0] ? { ...salon[0], images: salon[0].images ?? [], distanceKm: null, isFavorited: null } : undefined,
    service: service[0],
    staff: staffMember,
    user: u ? { id: u.id, name: u.name, email: u.email, phone: u.phone, avatarUrl: u.avatarUrl, role: u.role, createdAt: u.createdAt } : undefined,
  };
}

router.get("/bookings", requireAuth, async (req, res): Promise<void> => {
  const { status, role } = req.query as Record<string, string>;
  const userId = req.user!.userId;

  let conditions: ReturnType<typeof eq>[] = [];
  if (role === "owner") {
    const mySalons = await db.select({ id: salonsTable.id }).from(salonsTable).where(eq(salonsTable.ownerId, userId));
    const salonIds = mySalons.map((s) => s.id);
    if (salonIds.length === 0) {
      res.json([]);
      return;
    }
    conditions.push(inArray(bookingsTable.salonId, salonIds) as unknown as ReturnType<typeof eq>);
  } else {
    conditions.push(eq(bookingsTable.userId, userId));
  }
  if (status) {
    conditions.push(eq(bookingsTable.status, status as "pending" | "accepted" | "in_progress" | "completed" | "cancelled"));
  }

  const bookings = await db.select().from(bookingsTable).where(and(...conditions)).orderBy(desc(bookingsTable.createdAt)).limit(50);
  const enriched = await Promise.all(bookings.map(enrichBooking));
  res.json(enriched);
});

router.post("/bookings", requireAuth, async (req, res): Promise<void> => {
  const { salonId, serviceId, staffId, bookingDate, startTime, notes } = req.body;
  if (!salonId || !serviceId || !bookingDate || !startTime) {
    res.status(400).json({ error: "salonId, serviceId, bookingDate, startTime are required" });
    return;
  }
  const [service] = await db.select().from(servicesTable).where(eq(servicesTable.id, serviceId)).limit(1);
  if (!service) {
    res.status(404).json({ error: "Service not found" });
    return;
  }
  const totalPrice = service.discountPercent ? service.price * (1 - service.discountPercent / 100) : service.price;
  const durationMins = service.durationMinutes;
  const [startH, startM] = startTime.split(":").map(Number);
  const endMinutes = startH * 60 + startM + durationMins;
  const endTime = `${String(Math.floor(endMinutes / 60)).padStart(2, "0")}:${String(endMinutes % 60).padStart(2, "0")}`;

  const [booking] = await db.insert(bookingsTable).values({
    userId: req.user!.userId, salonId, serviceId, staffId: staffId ?? null,
    bookingDate, startTime, endTime, totalPrice, notes: notes ?? null,
  }).returning();

  // increment total bookings count
  const [salonRow] = await db.select().from(salonsTable).where(eq(salonsTable.id, salonId)).limit(1);
  if (salonRow) {
    await db.update(salonsTable).set({ totalBookings: salonRow.totalBookings + 1 }).where(eq(salonsTable.id, salonId));
  }

  const enriched = await enrichBooking(booking);
  res.status(201).json(enriched);
});

router.get("/bookings/:id", requireAuth, async (req, res): Promise<void> => {
  const rawId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
  const id = parseInt(rawId, 10);
  const [booking] = await db.select().from(bookingsTable).where(eq(bookingsTable.id, id)).limit(1);
  if (!booking) {
    res.status(404).json({ error: "Booking not found" });
    return;
  }
  if (booking.userId !== req.user!.userId) {
    const mySalons = await db.select({ id: salonsTable.id }).from(salonsTable).where(eq(salonsTable.ownerId, req.user!.userId));
    const salonIds = mySalons.map((s) => s.id);
    if (!salonIds.includes(booking.salonId) && req.user!.role !== "admin") {
      res.status(403).json({ error: "Forbidden" });
      return;
    }
  }
  const enriched = await enrichBooking(booking);
  res.json(enriched);
});

router.patch("/bookings/:id/status", requireAuth, async (req, res): Promise<void> => {
  const rawId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
  const id = parseInt(rawId, 10);
  const { status } = req.body;
  if (!status) {
    res.status(400).json({ error: "status is required" });
    return;
  }
  const [booking] = await db.select().from(bookingsTable).where(eq(bookingsTable.id, id)).limit(1);
  if (!booking) {
    res.status(404).json({ error: "Booking not found" });
    return;
  }
  if (status === "cancelled" && booking.userId !== req.user!.userId) {
    res.status(403).json({ error: "Forbidden" });
    return;
  }
  const [updated] = await db.update(bookingsTable).set({ status }).where(eq(bookingsTable.id, id)).returning();
  const enriched = await enrichBooking(updated);
  res.json(enriched);
});

export default router;
