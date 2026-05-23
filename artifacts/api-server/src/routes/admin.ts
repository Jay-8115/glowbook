import { Router, type IRouter, type Request, type Response, type NextFunction } from "express";
import { db, usersTable, salonsTable, bookingsTable, servicesTable, adminLogsTable, adminsTable } from "@workspace/db";
import { eq, like, and, sql, desc } from "drizzle-orm";
import { requireAuth } from "../middlewares/auth";

const router: IRouter = Router();

function requireAdmin(req: Request, res: Response, next: NextFunction): void {
  if (!req.user || req.user.role !== "admin") {
    res.status(403).json({ error: "Admin access required" });
    return;
  }
  next();
}

async function logAdminAction(userId: number, action: string, target?: string, details?: string) {
  try {
    const [user] = await db.select({ email: usersTable.email }).from(usersTable).where(eq(usersTable.id, userId)).limit(1);
    if (!user) return;

    const [admin] = await db.select().from(adminsTable).where(eq(adminsTable.email, user.email)).limit(1);
    if (admin) {
      await db.insert(adminLogsTable).values({
        adminId: admin.id,
        action,
        target: target ?? null,
        details: details ?? null,
      });
    } else {
      console.warn(`Admin with email ${user.email} not found in admins table.`);
    }
  } catch (e) {
    console.error("Failed to log admin action:", e);
  }
}

// GET /api/admin/stats
router.get("/admin/stats", requireAuth, requireAdmin, async (_req, res): Promise<void> => {
  const [
    usersRows,
    salonsRows,
    bookingsRows,
  ] = await Promise.all([
    db.select().from(usersTable),
    db.select().from(salonsTable),
    db.select().from(bookingsTable),
  ]);

  const totalUsers = usersRows.filter((u) => u.role === "user").length;
  const totalOwners = usersRows.filter((u) => u.role === "owner").length;
  const totalSalons = salonsRows.length;
  const activeSalons = salonsRows.filter((s) => s.isActive).length;
  const totalBookings = bookingsRows.length;
  const totalRevenue = bookingsRows.filter((b) => b.status === "completed").reduce((sum, b) => sum + b.totalPrice, 0);
  const activeBookings = bookingsRows.filter((b) => ["accepted", "in_progress"].includes(b.status)).length;
  const pendingBookings = bookingsRows.filter((b) => b.status === "pending").length;

  res.json({ totalUsers, totalOwners, totalSalons, activeSalons, totalBookings, totalRevenue, activeBookings, pendingBookings });
});

// GET /api/admin/users
router.get("/admin/users", requireAuth, requireAdmin, async (req, res): Promise<void> => {
  const page = String(req.query.page ?? "1");
  const limit = String(req.query.limit ?? "20");
  const search = req.query.search ? String(req.query.search) : undefined;
  const role = req.query.role ? String(req.query.role) : undefined;
  const pageNum = parseInt(page, 10);
  const limitNum = Math.min(parseInt(limit, 10), 100);
  const offset = (pageNum - 1) * limitNum;

  const conditions: any[] = [];
  if (search) conditions.push(like(usersTable.name, `%${search}%`));
  if (role) conditions.push(eq(usersTable.role, role as any));

  const whereClause = conditions.length > 0 ? and(...conditions) : undefined;
  const [users, countRow] = await Promise.all([
    db.select({
      id: usersTable.id,
      name: usersTable.name,
      email: usersTable.email,
      phone: usersTable.phone,
      avatarUrl: usersTable.avatarUrl,
      role: usersTable.role,
      createdAt: usersTable.createdAt,
    }).from(usersTable).where(whereClause).orderBy(desc(usersTable.createdAt)).limit(limitNum).offset(offset),
    db.select({ count: sql<number>`count(*)::int` }).from(usersTable).where(whereClause),
  ]);

  res.json({ users, total: countRow[0]?.count ?? 0, page: pageNum, limit: limitNum });
});

// PATCH /api/admin/users/:id
router.patch("/admin/users/:id", requireAuth, requireAdmin, async (req, res): Promise<void> => {
  const id = parseInt(String(req.params.id), 10);
  const { name, email, phone, role } = req.body;
  const [user] = await db.update(usersTable)
    .set({ ...(name && { name }), ...(email && { email }), phone: phone ?? undefined, ...(role && { role }) })
    .where(eq(usersTable.id, id))
    .returning({ id: usersTable.id, name: usersTable.name, email: usersTable.email, phone: usersTable.phone, avatarUrl: usersTable.avatarUrl, role: usersTable.role, createdAt: usersTable.createdAt });
  if (!user) { res.status(404).json({ error: "User not found" }); return; }
  
  // Log the action
  await logAdminAction(
    req.user!.userId,
    "UPDATE_USER",
    `User #${id}`,
    `Updated details/role of user ${user.name} (${user.email}) to role: ${role || user.role}`
  );
  
  res.json(user);
});

// DELETE /api/admin/users/:id
router.delete("/admin/users/:id", requireAuth, requireAdmin, async (req, res): Promise<void> => {
  const id = parseInt(String(req.params.id), 10);
  await db.delete(usersTable).where(eq(usersTable.id, id));
  
  // Log the action
  await logAdminAction(
    req.user!.userId,
    "DELETE_USER",
    `User #${id}`,
    `Deleted user account #${id}`
  );
  
  res.json({ success: true, message: "User deleted" });
});

// GET /api/admin/salons
router.get("/admin/salons", requireAuth, requireAdmin, async (req, res): Promise<void> => {
  const page = String(req.query.page ?? "1");
  const limit = String(req.query.limit ?? "20");
  const search = req.query.search ? String(req.query.search) : undefined;
  const isActive = req.query.isActive !== undefined ? String(req.query.isActive) : undefined;
  const isVerified = req.query.isVerified !== undefined ? String(req.query.isVerified) : undefined;
  const pageNum = parseInt(page, 10);
  const limitNum = Math.min(parseInt(limit, 10), 100);
  const offset = (pageNum - 1) * limitNum;

  const conditions: any[] = [];
  if (search) conditions.push(like(salonsTable.name, `%${search}%`));
  if (isActive !== undefined) conditions.push(eq(salonsTable.isActive, isActive === "true"));
  if (isVerified !== undefined) conditions.push(eq(salonsTable.isVerified, isVerified === "true"));

  const whereClause = conditions.length > 0 ? and(...conditions) : undefined;
  const [salons, countRow] = await Promise.all([
    db.select().from(salonsTable).where(whereClause).orderBy(desc(salonsTable.createdAt)).limit(limitNum).offset(offset),
    db.select({ count: sql<number>`count(*)::int` }).from(salonsTable).where(whereClause),
  ]);

  const salonsWithOwner = await Promise.all(salons.map(async (salon) => {
    const [owner] = await db.select({ id: usersTable.id, name: usersTable.name, email: usersTable.email }).from(usersTable).where(eq(usersTable.id, salon.ownerId)).limit(1);
    return { ...salon, owner };
  }));

  res.json({ salons: salonsWithOwner, total: countRow[0]?.count ?? 0, page: pageNum, limit: limitNum });
});

// PATCH /api/admin/salons/:id
router.patch("/admin/salons/:id", requireAuth, requireAdmin, async (req, res): Promise<void> => {
  const id = parseInt(String(req.params.id), 10);
  const { isActive, isVerified, name, description } = req.body;
  const [salon] = await db.update(salonsTable)
    .set({ ...(isActive !== undefined && { isActive }), ...(isVerified !== undefined && { isVerified }), ...(name && { name }), ...(description !== undefined && { description }) })
    .where(eq(salonsTable.id, id))
    .returning();
  if (!salon) { res.status(404).json({ error: "Salon not found" }); return; }
  
  // Log the action
  await logAdminAction(
    req.user!.userId,
    "UPDATE_SALON",
    `Salon #${id}`,
    `Updated salon details: ${salon.name}. Verified: ${salon.isVerified}, Active: ${salon.isActive}`
  );
  
  res.json(salon);
});

// DELETE /api/admin/salons/:id
router.delete("/admin/salons/:id", requireAuth, requireAdmin, async (req, res): Promise<void> => {
  const id = parseInt(String(req.params.id), 10);
  await db.delete(salonsTable).where(eq(salonsTable.id, id));
  
  // Log the action
  await logAdminAction(
    req.user!.userId,
    "DELETE_SALON",
    `Salon #${id}`,
    `Deleted salon listing #${id}`
  );
  
  res.json({ success: true, message: "Salon deleted" });
});

// GET /api/admin/bookings
router.get("/admin/bookings", requireAuth, requireAdmin, async (req, res): Promise<void> => {
  const page = String(req.query.page ?? "1");
  const limit = String(req.query.limit ?? "20");
  const status = req.query.status ? String(req.query.status) : undefined;
  const salonId = req.query.salonId ? String(req.query.salonId) : undefined;
  const pageNum = parseInt(page, 10);
  const limitNum = Math.min(parseInt(limit, 10), 100);
  const offset = (pageNum - 1) * limitNum;

  const conditions: any[] = [];
  if (status) conditions.push(eq(bookingsTable.status, status as any));
  if (salonId) conditions.push(eq(bookingsTable.salonId, parseInt(salonId, 10)));

  const whereClause = conditions.length > 0 ? and(...conditions) : undefined;
  const [bookings, countRow] = await Promise.all([
    db.select().from(bookingsTable).where(whereClause).orderBy(desc(bookingsTable.createdAt)).limit(limitNum).offset(offset),
    db.select({ count: sql<number>`count(*)::int` }).from(bookingsTable).where(whereClause),
  ]);

  const enriched = await Promise.all(bookings.map(async (b) => {
    const [[salon], [user], [service]] = await Promise.all([
      db.select({ id: salonsTable.id, name: salonsTable.name }).from(salonsTable).where(eq(salonsTable.id, b.salonId)).limit(1),
      db.select({ id: usersTable.id, name: usersTable.name, email: usersTable.email }).from(usersTable).where(eq(usersTable.id, b.userId)).limit(1),
      db.select({ id: servicesTable.id, name: servicesTable.name, price: servicesTable.price }).from(servicesTable).where(eq(servicesTable.id, b.serviceId)).limit(1),
    ]);
    return { ...b, salon, user, service };
  }));

  res.json({ bookings: enriched, total: countRow[0]?.count ?? 0, page: pageNum, limit: limitNum });
});

// GET /api/admin/logs
router.get("/admin/logs", requireAuth, requireAdmin, async (_req, res): Promise<void> => {
  try {
    const logs = await db
      .select({
        id: adminLogsTable.id,
        adminId: adminLogsTable.adminId,
        adminName: adminsTable.name,
        adminEmail: adminsTable.email,
        action: adminLogsTable.action,
        target: adminLogsTable.target,
        details: adminLogsTable.details,
        createdAt: adminLogsTable.createdAt,
      })
      .from(adminLogsTable)
      .innerJoin(adminsTable, eq(adminLogsTable.adminId, adminsTable.id))
      .orderBy(desc(adminLogsTable.createdAt))
      .limit(100);

    res.json({ logs });
  } catch (e) {
    res.status(500).json({ error: "Failed to fetch logs" });
  }
});

export default router;
