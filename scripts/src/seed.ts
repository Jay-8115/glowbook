import { db } from "@workspace/db";
import {
  usersTable, categoriesTable, salonsTable, servicesTable, staffTable, adminsTable,
} from "@workspace/db";
import bcrypt from "bcrypt";

async function seed() {
  console.log("Seeding database...");

  // Categories
  const cats = await db.insert(categoriesTable).values([
    { name: "Hair & Styling", icon: "scissors" },
    { name: "Nails", icon: "sparkles" },
    { name: "Makeup", icon: "star" },
    { name: "Massage", icon: "heart" },
    { name: "Skincare", icon: "sun" },
    { name: "Barber", icon: "user" },
  ]).onConflictDoNothing().returning();
  console.log(`✔ ${cats.length} categories seeded`);

  // Demo owner account
  const hash = await bcrypt.hash("password123", 10);
  const [owner] = await db.insert(usersTable).values({
    name: "Salon Owner",
    email: "owner@glowbook.com",
    passwordHash: hash,
    phone: "+1 555-0100",
    role: "owner",
  }).onConflictDoNothing().returning();

  const [customer] = await db.insert(usersTable).values({
    name: "Jane Smith",
    email: "jane@glowbook.com",
    passwordHash: hash,
    phone: "+1 555-0200",
    role: "user",
  }).onConflictDoNothing().returning();

  // Demo administrator accounts in both users and admins tables
  await db.insert(usersTable).values({
    name: "GlowBook Administrator",
    email: "admin@glowbook.com",
    passwordHash: hash,
    phone: "+1 555-0900",
    role: "admin",
  }).onConflictDoNothing();

  await db.insert(adminsTable).values({
    name: "GlowBook Administrator",
    email: "admin@glowbook.com",
    passwordHash: hash,
    phone: "+1 555-0900",
  }).onConflictDoNothing();

  console.log("✔ Demo users seeded (owner@glowbook.com / admin@glowbook.com / password123)");

  if (!owner) { console.log("Users already seeded, skipping salons"); return; }

  // Salons
  const salonsData = [
    {
      name: "Golden Scissors",
      description: "Premium hair salon with top stylists and a luxurious atmosphere.",
      ownerId: owner.id,
      address: "123 Fifth Avenue",
      city: "New York",
      state: "NY",
      lat: 40.7549, lng: -73.9840,
      phone: "+1 212-555-0101",
      imageUrl: "https://images.unsplash.com/photo-1560066984-138dadb4c035?w=800",
      images: [
        "https://images.unsplash.com/photo-1560066984-138dadb4c035?w=800",
        "https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?w=800",
      ],
      avgRating: 4.8,
      totalReviews: 127,
      totalBookings: 340,
      isActive: true,
      isVerified: true,
      openTime: "09:00",
      closeTime: "20:00",
    },
    {
      name: "Velvet Touch Spa",
      description: "Full-service beauty spa offering massages, facials, and body treatments.",
      ownerId: owner.id,
      address: "456 Sunset Blvd",
      city: "Los Angeles",
      state: "CA",
      lat: 34.0922, lng: -118.3661,
      phone: "+1 310-555-0202",
      imageUrl: "https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=800",
      images: ["https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=800"],
      avgRating: 4.6,
      totalReviews: 89,
      totalBookings: 215,
      isActive: true,
      isVerified: true,
      openTime: "10:00",
      closeTime: "19:00",
    },
    {
      name: "The Style Lab",
      description: "Creative hair coloring and cutting studio for the modern trendsetter.",
      ownerId: owner.id,
      address: "789 Michigan Ave",
      city: "Chicago",
      state: "IL",
      lat: 41.8919, lng: -87.6240,
      phone: "+1 312-555-0303",
      imageUrl: "https://images.unsplash.com/photo-1562322140-8baeececf3df?w=800",
      images: ["https://images.unsplash.com/photo-1562322140-8baeececf3df?w=800"],
      avgRating: 4.5,
      totalReviews: 64,
      totalBookings: 180,
      isActive: true,
      isVerified: false,
      openTime: "09:00",
      closeTime: "18:00",
    },
    {
      name: "Luxe Nail Bar",
      description: "Boutique nail salon offering gel, acrylic, and artistic nail designs.",
      ownerId: owner.id,
      address: "22 Collins Ave",
      city: "Miami",
      state: "FL",
      lat: 25.7617, lng: -80.1918,
      phone: "+1 305-555-0404",
      imageUrl: "https://images.unsplash.com/photo-1604654894610-df63bc536371?w=800",
      images: ["https://images.unsplash.com/photo-1604654894610-df63bc536371?w=800"],
      avgRating: 4.9,
      totalReviews: 203,
      totalBookings: 520,
      isActive: true,
      isVerified: true,
      openTime: "09:00",
      closeTime: "21:00",
    },
    {
      name: "Prestige Barber Co.",
      description: "Old-school barbershop vibes with modern precision cuts and hot towel shaves.",
      ownerId: owner.id,
      address: "88 King Street",
      city: "Houston",
      state: "TX",
      lat: 29.7604, lng: -95.3698,
      phone: "+1 713-555-0505",
      imageUrl: "https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800",
      images: ["https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800"],
      avgRating: 4.7,
      totalReviews: 156,
      totalBookings: 410,
      isActive: true,
      isVerified: true,
      openTime: "08:00",
      closeTime: "19:00",
    },
    {
      name: "Glow Beauty Studio",
      description: "Makeup artistry and skincare treatments by certified beauty experts.",
      ownerId: owner.id,
      address: "33 Pike St",
      city: "Seattle",
      state: "WA",
      lat: 47.6062, lng: -122.3321,
      phone: "+1 206-555-0606",
      imageUrl: "https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=800",
      images: ["https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=800"],
      avgRating: 4.4,
      totalReviews: 48,
      totalBookings: 130,
      isActive: true,
      isVerified: false,
      openTime: "10:00",
      closeTime: "18:00",
    },
  ];

  const salons = await db.insert(salonsTable).values(salonsData).returning();
  console.log(`✔ ${salons.length} salons seeded`);

  // Services per salon
  const servicesData = salons.flatMap((salon, i) => {
    if (i === 0) return [
      { salonId: salon.id, name: "Haircut & Style", price: 75, durationMinutes: 60, category: "Hair", description: "Cut and blowout by a master stylist" },
      { salonId: salon.id, name: "Color Treatment", price: 150, durationMinutes: 120, category: "Hair", description: "Full color, highlights, or balayage" },
      { salonId: salon.id, name: "Keratin Treatment", price: 200, durationMinutes: 150, category: "Hair", description: "Smooth and frizz-free for up to 3 months", discountPercent: 10 },
      { salonId: salon.id, name: "Blowout", price: 45, durationMinutes: 45, category: "Hair", description: "Professional blowout for any occasion" },
    ];
    if (i === 1) return [
      { salonId: salon.id, name: "Swedish Massage", price: 110, durationMinutes: 60, category: "Massage", description: "Relaxing full-body Swedish massage" },
      { salonId: salon.id, name: "Deep Tissue Massage", price: 130, durationMinutes: 90, category: "Massage", description: "Targets deep muscle tension" },
      { salonId: salon.id, name: "Hydrating Facial", price: 90, durationMinutes: 60, category: "Skincare", description: "Deep cleanse and hydration treatment" },
    ];
    if (i === 2) return [
      { salonId: salon.id, name: "Haircut", price: 65, durationMinutes: 45, category: "Hair", description: "Precision cut for all hair types" },
      { salonId: salon.id, name: "Balayage", price: 180, durationMinutes: 180, category: "Hair", description: "Hand-painted highlights for a natural look" },
    ];
    if (i === 3) return [
      { salonId: salon.id, name: "Gel Manicure", price: 45, durationMinutes: 60, category: "Nails", description: "Long-lasting gel color on natural nails" },
      { salonId: salon.id, name: "Acrylic Full Set", price: 70, durationMinutes: 90, category: "Nails", description: "Full acrylic set with any shape and length" },
      { salonId: salon.id, name: "Pedicure", price: 55, durationMinutes: 75, category: "Nails", description: "Relaxing foot soak, exfoliate, and polish" },
      { salonId: salon.id, name: "Nail Art Design", price: 25, durationMinutes: 30, category: "Nails", description: "Custom nail art on up to 10 nails", discountPercent: 15 },
    ];
    if (i === 4) return [
      { salonId: salon.id, name: "Classic Haircut", price: 30, durationMinutes: 30, category: "Barber", description: "Clean, precise cut for all hair types" },
      { salonId: salon.id, name: "Fade Cut", price: 35, durationMinutes: 40, category: "Barber", description: "Taper or skin fade with clean lines" },
      { salonId: salon.id, name: "Hot Towel Shave", price: 40, durationMinutes: 30, category: "Barber", description: "Traditional straight-razor shave experience" },
      { salonId: salon.id, name: "Cut & Shave Combo", price: 60, durationMinutes: 60, category: "Barber", description: "Haircut plus full hot towel shave", discountPercent: 10 },
    ];
    return [
      { salonId: salon.id, name: "Full Glam Makeup", price: 120, durationMinutes: 90, category: "Makeup", description: "Complete makeup look for events or special occasions" },
      { salonId: salon.id, name: "Bridal Makeup", price: 200, durationMinutes: 120, category: "Makeup", description: "Timeless bridal look with premium products" },
      { salonId: salon.id, name: "Anti-Aging Facial", price: 95, durationMinutes: 60, category: "Skincare", description: "Firming and lifting facial treatment" },
    ];
  });

  await db.insert(servicesTable).values(servicesData);
  console.log(`✔ ${servicesData.length} services seeded`);

  // Staff per salon
  const staffData = salons.flatMap((salon, i) => {
    const base = [
      { salonId: salon.id, name: "Alex Rivera", role: "Senior Stylist", specialization: "Color & Balayage", isAvailable: true },
      { salonId: salon.id, name: "Jordan Lee", role: "Stylist", specialization: "Cuts & Blowouts", isAvailable: true },
    ];
    if (i < 3) base.push({ salonId: salon.id, name: "Morgan Chen", role: "Junior Stylist", specialization: "Extensions", isAvailable: false });
    return base;
  });

  await db.insert(staffTable).values(staffData);
  console.log(`✔ ${staffData.length} staff members seeded`);

  console.log("\n✅ Database seeded successfully!");
  console.log("Demo accounts:");
  console.log("  Owner: owner@glowbook.com / password123");
  console.log("  Customer: jane@glowbook.com / password123");
}

seed().catch(console.error).finally(() => process.exit(0));
