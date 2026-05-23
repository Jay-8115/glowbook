import { pgTable, serial, text, integer, timestamp } from "drizzle-orm/pg-core";
import { adminsTable } from "./admins";

export const adminLogsTable = pgTable("admin_logs", {
  id: serial("id").primaryKey(),
  adminId: integer("admin_id").notNull().references(() => adminsTable.id, { onDelete: "cascade" }),
  action: text("action").notNull(),
  target: text("target"),
  details: text("details"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});

export type AdminLog = typeof adminLogsTable.$inferSelect;
export type InsertAdminLog = typeof adminLogsTable.$inferInsert;
