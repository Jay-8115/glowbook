import { pgTable, integer, timestamp, primaryKey } from "drizzle-orm/pg-core";
import { usersTable } from "./users";
import { salonsTable } from "./salons";

export const favoritesTable = pgTable(
  "favorites",
  {
    userId: integer("user_id").notNull().references(() => usersTable.id, { onDelete: "cascade" }),
    salonId: integer("salon_id").notNull().references(() => salonsTable.id, { onDelete: "cascade" }),
    createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [primaryKey({ columns: [t.userId, t.salonId] })],
);

export type Favorite = typeof favoritesTable.$inferSelect;
