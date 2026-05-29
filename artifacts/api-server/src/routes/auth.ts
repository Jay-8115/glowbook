import { Router, type IRouter } from "express";
import bcrypt from "bcrypt";
import { db, usersTable, adminsTable } from "@workspace/db";
import { eq } from "drizzle-orm";
import { requireAuth, signToken } from "../middlewares/auth";

const router: IRouter = Router();

router.post("/auth/register", async (req, res): Promise<void> => {
  const { name, email, password, phone, role } = req.body;
  if (!name || !email || !password) {
    res.status(400).json({ error: "name, email, and password are required" });
    return;
  }
  const existing = await db.select().from(usersTable).where(eq(usersTable.email, email)).limit(1);
  if (existing.length > 0) {
    res.status(400).json({ error: "Email already registered" });
    return;
  }
  const passwordHash = await bcrypt.hash(password, 10);
  const [user] = await db.insert(usersTable).values({
    name,
    email,
    passwordHash,
    phone: phone ?? null,
    role: role === "owner" ? "owner" : "user",
  }).returning();
  const token = signToken({ userId: user.id, role: user.role });
  res.status(201).json({
    token,
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      avatarUrl: user.avatarUrl,
      role: user.role,
      createdAt: user.createdAt,
    },
  });
});

router.post("/auth/login", async (req, res): Promise<void> => {
  const { email, password } = req.body;
  if (!email || !password) {
    res.status(400).json({ error: "email and password are required" });
    return;
  }

  const appType = req.headers["x-app-type"];
  let account: any = null;
  let isTableAdmin = false;

  try {
    if (appType === "admin") {
      // 1. Primary path for admin app: query adminsTable
      const [admin] = await db.select().from(adminsTable).where(eq(adminsTable.email, email)).limit(1);
      if (admin) {
        account = admin;
        isTableAdmin = true;
      } else {
        // Fallback: search usersTable
        const [user] = await db.select().from(usersTable).where(eq(usersTable.email, email)).limit(1);
        if (user) {
          account = user;
          isTableAdmin = user.role === "admin";
        }
      }
    } else {
      // 2. Primary path for user/owner app: query usersTable
      const [user] = await db.select().from(usersTable).where(eq(usersTable.email, email)).limit(1);
      if (user) {
        account = user;
        isTableAdmin = user.role === "admin";
      } else {
        // Fallback: search adminsTable
        const [admin] = await db.select().from(adminsTable).where(eq(adminsTable.email, email)).limit(1);
        if (admin) {
          account = admin;
          isTableAdmin = true;
        }
      }
    }

    if (!account) {
      res.status(401).json({ error: "Invalid credentials" });
      return;
    }

    const valid = await bcrypt.compare(password, account.passwordHash);
    if (!valid) {
      res.status(401).json({ error: "Invalid credentials" });
      return;
    }

    const role = isTableAdmin ? "admin" : (account.role ?? "user");
    const token = signToken({ userId: account.id, role });

    res.json({
      token,
      user: {
        id: account.id,
        name: account.name,
        email: account.email,
        phone: account.phone ?? null,
        avatarUrl: account.avatarUrl ?? null,
        role,
        createdAt: account.createdAt,
      },
    });
  } catch (error: any) {
    console.error("Login route error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

router.get("/auth/me", requireAuth, async (req, res): Promise<void> => {
  try {
    if (req.user!.role === "admin") {
      // Try adminsTable first
      const [admin] = await db.select().from(adminsTable).where(eq(adminsTable.id, req.user!.userId)).limit(1);
      if (admin) {
        res.json({
          id: admin.id,
          name: admin.name,
          email: admin.email,
          phone: admin.phone ?? null,
          avatarUrl: null,
          role: "admin",
          createdAt: admin.createdAt,
        });
        return;
      }
      // Fallback: try usersTable
      const [user] = await db.select().from(usersTable).where(eq(usersTable.id, req.user!.userId)).limit(1);
      if (user) {
        res.json({
          id: user.id,
          name: user.name,
          email: user.email,
          phone: user.phone ?? null,
          avatarUrl: user.avatarUrl ?? null,
          role: user.role,
          createdAt: user.createdAt,
        });
        return;
      }
    } else {
      // Try usersTable first
      const [user] = await db.select().from(usersTable).where(eq(usersTable.id, req.user!.userId)).limit(1);
      if (user) {
        res.json({
          id: user.id,
          name: user.name,
          email: user.email,
          phone: user.phone ?? null,
          avatarUrl: user.avatarUrl ?? null,
          role: user.role,
          createdAt: user.createdAt,
        });
        return;
      }
      // Fallback: try adminsTable
      const [admin] = await db.select().from(adminsTable).where(eq(adminsTable.id, req.user!.userId)).limit(1);
      if (admin) {
        res.json({
          id: admin.id,
          name: admin.name,
          email: admin.email,
          phone: admin.phone ?? null,
          avatarUrl: null,
          role: "admin",
          createdAt: admin.createdAt,
        });
        return;
      }
    }

    res.status(404).json({ error: "User not found" });
  } catch (error) {
    console.error("Auth me route error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

export default router;
