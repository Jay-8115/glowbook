import { Router, type IRouter } from "express";
import { db, staffTable, salonsTable } from "@workspace/db";
import { eq } from "drizzle-orm";
import { requireAuth } from "../middlewares/auth";

const router: IRouter = Router();

router.get("/salons/:salonId/staff", async (req, res): Promise<void> => {
  const rawId = Array.isArray(req.params.salonId) ? req.params.salonId[0] : req.params.salonId;
  const salonId = parseInt(rawId, 10);
  const staff = await db.select().from(staffTable).where(eq(staffTable.salonId, salonId));
  res.json(staff);
});

router.post("/salons/:salonId/staff", requireAuth, async (req, res): Promise<void> => {
  const rawId = Array.isArray(req.params.salonId) ? req.params.salonId[0] : req.params.salonId;
  const salonId = parseInt(rawId, 10);
  const [salon] = await db.select().from(salonsTable).where(eq(salonsTable.id, salonId)).limit(1);
  if (!salon || (salon.ownerId !== req.user!.userId && req.user!.role !== "admin")) {
    res.status(403).json({ error: "Forbidden" });
    return;
  }
  const { name, role, specialization, avatarUrl } = req.body;
  if (!name) {
    res.status(400).json({ error: "name is required" });
    return;
  }
  const [member] = await db.insert(staffTable).values({ salonId, name, role, specialization, avatarUrl }).returning();
  res.status(201).json(member);
});

export default router;
