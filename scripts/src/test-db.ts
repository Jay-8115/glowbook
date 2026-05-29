import { db, adminsTable } from "@workspace/db";
import { sql } from "drizzle-orm";

async function testConnection() {
  console.log("=========================================");
  console.log("GLOWBOOK DATABASE CONNECTIVITY DIAGNOSTIC");
  console.log("=========================================");

  const dbUrl = process.env.DATABASE_URL;
  if (!dbUrl) {
    console.error("✖ Error: DATABASE_URL environment variable is not defined!");
    console.log("Please run: $env:DATABASE_URL=\"your-connection-string\" (PowerShell)");
    process.exit(1);
  }

  // Mask sensitive parts of the DATABASE_URL for logging
  try {
    const parsed = new URL(dbUrl.startsWith("postgresql://") || dbUrl.startsWith("postgres://") ? dbUrl : `postgres://${dbUrl}`);
    console.log(`Host: ${parsed.hostname}`);
    console.log(`Port: ${parsed.port || "5432"}`);
    console.log(`User: ${parsed.username}`);
    console.log(`Database: ${parsed.pathname.slice(1)}`);
  } catch (e) {
    console.log("Connection URL (masked):", dbUrl.slice(0, 15) + "..." + dbUrl.slice(-10));
  }

  console.log("\nConnecting to PostgreSQL database...");
  try {
    // 1. Basic raw query test
    const startTime = Date.now();
    const rawResult = await db.execute(sql`SELECT 1 as connection_test`);
    const duration = Date.now() - startTime;
    console.log(`✔ Basic connection query successful! (Time: ${duration}ms)`);
    console.log("Result:", rawResult.rows);

    // 2. adminsTable query test
    console.log("\nQuerying admins table...");
    const admins = await db.select().from(adminsTable).limit(1);
    console.log("✔ SELECT * FROM admins LIMIT 1 successful!");
    if (admins.length > 0) {
      console.log("Admin account found:", {
        id: admins[0].id,
        name: admins[0].name,
        email: admins[0].email,
        phone: admins[0].phone,
        createdAt: admins[0].createdAt,
      });
    } else {
      console.log("No admin accounts found in admins table.");
    }
  } catch (error: any) {
    console.error("\n✖ Database Connection Failed!");
    console.error("Error Code:", error.code || "N/A");
    console.error("Error Message:", error.message || error);
    if (error.code === "ENETUNREACH") {
      console.error("\n[DIAGNOSTIC ADVISORY]: Network Unreachable (ENETUNREACH).");
      console.error("This is caused by trying to connect to an IPv6-only host from an IPv4-only network.");
      console.error("Solution: Switch your DATABASE_URL to use the Supabase Connection Pooler in Session Mode (port 5432) or buy the dedicated IPv4 add-on.");
    }
  }
  process.exit(0);
}

testConnection();
