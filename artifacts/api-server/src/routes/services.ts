import { Router, type IRouter } from "express";
import { db, servicesTable, salonsTable } from "@workspace/db";
import { eq, and } from "drizzle-orm";
import { requireAuth } from "../middlewares/auth";

const router: IRouter = Router();

router.get("/salons/:salonId/services", async (req, res): Promise<void> => {
  const rawId = Array.isArray(req.params.salonId) ? req.params.salonId[0] : req.params.salonId;
  const salonId = parseInt(rawId, 10);
  const services = await db.select().from(servicesTable).where(and(eq(servicesTable.salonId, salonId), eq(servicesTable.isActive, true)));
  res.json(services);
});

router.post("/salons/:salonId/services", requireAuth, async (req, res): Promise<void> => {
  const rawId = Array.isArray(req.params.salonId) ? req.params.salonId[0] : req.params.salonId;
  const salonId = parseInt(rawId, 10);
  const [salon] = await db.select().from(salonsTable).where(eq(salonsTable.id, salonId)).limit(1);
  if (!salon || (salon.ownerId !== req.user!.userId && req.user!.role !== "admin")) {
    res.status(403).json({ error: "Forbidden" });
    return;
  }
  const { name, description, price, durationMinutes, category, imageUrl, discountPercent } = req.body;
  if (!name || price == null || !durationMinutes) {
    res.status(400).json({ error: "name, price, and durationMinutes are required" });
    return;
  }
  const [service] = await db.insert(servicesTable).values({ salonId, name, description, price, durationMinutes, category, imageUrl, discountPercent }).returning();
  res.status(201).json(service);
});

router.patch("/salons/:salonId/services/:serviceId", requireAuth, async (req, res): Promise<void> => {
  const rawSalonId = Array.isArray(req.params.salonId) ? req.params.salonId[0] : req.params.salonId;
  const rawServiceId = Array.isArray(req.params.serviceId) ? req.params.serviceId[0] : req.params.serviceId;
  const salonId = parseInt(rawSalonId, 10);
  const serviceId = parseInt(rawServiceId, 10);
  const [salon] = await db.select().from(salonsTable).where(eq(salonsTable.id, salonId)).limit(1);
  if (!salon || (salon.ownerId !== req.user!.userId && req.user!.role !== "admin")) {
    res.status(403).json({ error: "Forbidden" });
    return;
  }
  const { name, description, price, durationMinutes, category, imageUrl, isActive, discountPercent } = req.body;
  const [service] = await db.update(servicesTable).set({ name, description, price, durationMinutes, category, imageUrl, isActive, discountPercent }).where(and(eq(servicesTable.id, serviceId), eq(servicesTable.salonId, salonId))).returning();
  if (!service) {
    res.status(404).json({ error: "Service not found" });
    return;
  }
  res.json(service);
});

router.delete("/salons/:salonId/services/:serviceId", requireAuth, async (req, res): Promise<void> => {
  const rawSalonId = Array.isArray(req.params.salonId) ? req.params.salonId[0] : req.params.salonId;
  const rawServiceId = Array.isArray(req.params.serviceId) ? req.params.serviceId[0] : req.params.serviceId;
  const salonId = parseInt(rawSalonId, 10);
  const serviceId = parseInt(rawServiceId, 10);
  const [salon] = await db.select().from(salonsTable).where(eq(salonsTable.id, salonId)).limit(1);
  if (!salon || (salon.ownerId !== req.user!.userId && req.user!.role !== "admin")) {
    res.status(403).json({ error: "Forbidden" });
    return;
  }
  await db.delete(servicesTable).where(and(eq(servicesTable.id, serviceId), eq(servicesTable.salonId, salonId)));
  res.json({ success: true, message: "Service deleted" });
});

export default router;
