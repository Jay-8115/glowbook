import { pgTable, serial, text, integer, boolean, real, timestamp } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod/v4";
import { usersTable } from "./users";

export const salonsTable = pgTable("salons", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  description: text("description"),
  ownerId: integer("owner_id").notNull().references(() => usersTable.id),
  address: text("address").notNull(),
  city: text("city").notNull(),
  state: text("state"),
  lat: real("lat"),
  lng: real("lng"),
  phone: text("phone"),
  imageUrl: text("image_url"),
  images: text("images").array().notNull().default([]),
  avgRating: real("avg_rating").notNull().default(0),
  totalReviews: integer("total_reviews").notNull().default(0),
  totalBookings: integer("total_bookings").notNull().default(0),
  isActive: boolean("is_active").notNull().default(true),
  isVerified: boolean("is_verified").notNull().default(false),
  openTime: text("open_time"),
  closeTime: text("close_time"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow().$onUpdate(() => new Date()),
});

export const insertSalonSchema = createInsertSchema(salonsTable).omit({
  id: true,
  avgRating: true,
  totalReviews: true,
  totalBookings: true,
  isVerified: true,
  createdAt: true,
  updatedAt: true,
});
export type InsertSalon = z.infer<typeof insertSalonSchema>;
export type Salon = typeof salonsTable.$inferSelect;
