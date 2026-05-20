import { Router, type IRouter } from "express";
import { db, usersTable, salonsTable, favoritesTable } from "@workspace/db";
import { eq, and, inArray } from "drizzle-orm";
import { requireAuth } from "../middlewares/auth";

const router: IRouter = Router();

router.patch("/users/profile", requireAuth, async (req, res): Promise<void> => {
  const { name, phone, avatarUrl } = req.body;
  const [user] = await db
    .update(usersTable)
    .set({ name, phone, avatarUrl })
    .where(eq(usersTable.id, req.user!.userId))
    .returning();
  res.json({
    id: user.id,
    name: user.name,
    email: user.email,
    phone: user.phone,
    avatarUrl: user.avatarUrl,
    role: user.role,
    createdAt: user.createdAt,
  });
});

router.get("/users/favorites", requireAuth, async (req, res): Promise<void> => {
  const favRows = await db
    .select({ salonId: favoritesTable.salonId })
    .from(favoritesTable)
    .where(eq(favoritesTable.userId, req.user!.userId));
  if (favRows.length === 0) {
    res.json([]);
    return;
  }
  const ids = favRows.map((f) => f.salonId);
  const salons = await db.select().from(salonsTable).where(inArray(salonsTable.id, ids));
  res.json(salons.map((s) => ({ ...s, isFavorited: true, distanceKm: null })));
});

router.post("/users/favorites/:salonId", requireAuth, async (req, res): Promise<void> => {
  const rawId = Array.isArray(req.params.salonId) ? req.params.salonId[0] : req.params.salonId;
  const salonId = parseInt(rawId, 10);
  await db
    .insert(favoritesTable)
    .values({ userId: req.user!.userId, salonId })
    .onConflictDoNothing();
  res.json({ success: true, message: "Added to favorites" });
});

router.delete("/users/favorites/:salonId", requireAuth, async (req, res): Promise<void> => {
  const rawId = Array.isArray(req.params.salonId) ? req.params.salonId[0] : req.params.salonId;
  const salonId = parseInt(rawId, 10);
  await db
    .delete(favoritesTable)
    .where(and(eq(favoritesTable.userId, req.user!.userId), eq(favoritesTable.salonId, salonId)));
  res.json({ success: true, message: "Removed from favorites" });
});

export default router;
