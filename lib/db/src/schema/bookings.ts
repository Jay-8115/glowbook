import { pgTable, serial, text, integer, real, timestamp, pgEnum, date } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod/v4";
import { usersTable } from "./users";
import { salonsTable } from "./salons";
import { servicesTable } from "./services";
import { staffTable } from "./staff";

export const bookingStatusEnum = pgEnum("booking_status", [
  "pending",
  "accepted",
  "in_progress",
  "completed",
  "cancelled",
]);

export const bookingsTable = pgTable("bookings", {
  id: serial("id").primaryKey(),
  userId: integer("user_id").notNull().references(() => usersTable.id),
  salonId: integer("salon_id").notNull().references(() => salonsTable.id),
  serviceId: integer("service_id").notNull().references(() => servicesTable.id),
  staffId: integer("staff_id").references(() => staffTable.id),
  bookingDate: date("booking_date").notNull(),
  startTime: text("start_time").notNull(),
  endTime: text("end_time"),
  status: bookingStatusEnum("status").notNull().default("pending"),
  totalPrice: real("total_price").notNull(),
  notes: text("notes"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow().$onUpdate(() => new Date()),
});

export const insertBookingSchema = createInsertSchema(bookingsTable).omit({
  id: true,
  status: true,
  createdAt: true,
  updatedAt: true,
});
export type InsertBooking = z.infer<typeof insertBookingSchema>;
export type Booking = typeof bookingsTable.$inferSelect;
