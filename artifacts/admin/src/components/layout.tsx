import React from "react";
import { Link, useLocation } from "wouter";
import { LayoutDashboard, Users, Store, CalendarDays, LogOut } from "lucide-react";
import { useAuth } from "@/lib/auth";
import { Button } from "@/components/ui/button";

interface SidebarItemProps {
  icon: React.ReactNode;
  label: string;
  href: string;
  isActive: boolean;
}

function SidebarItem({ icon, label, href, isActive }: SidebarItemProps) {
  return (
    <Link href={href} className={`flex items-center gap-3 px-4 py-3 rounded-md transition-colors ${isActive ? 'bg-primary text-primary-foreground font-medium' : 'text-muted-foreground hover:text-foreground hover:bg-muted'}`}>
      {icon}
      <span>{label}</span>
    </Link>
  );
}

export default function Layout({ children }: { children: React.ReactNode }) {
  const [location] = useLocation();
  const { logout } = useAuth();

  return (
    <div className="flex h-screen w-full bg-muted/30">
      <aside className="w-64 bg-card border-r flex flex-col">
        <div className="p-6 border-b">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-sm bg-accent flex items-center justify-center">
              <span className="text-accent-foreground font-bold text-lg">G</span>
            </div>
            <span className="font-bold text-xl tracking-tight text-foreground">GlowBook</span>
          </div>
          <p className="text-xs text-muted-foreground mt-1 tracking-widest uppercase">Admin Control</p>
        </div>
        
        <nav className="flex-1 p-4 space-y-1">
          <SidebarItem href="/" icon={<LayoutDashboard size={18} />} label="Dashboard" isActive={location === "/"} />
          <SidebarItem href="/users" icon={<Users size={18} />} label="Users" isActive={location === "/users"} />
          <SidebarItem href="/salons" icon={<Store size={18} />} label="Salons" isActive={location === "/salons"} />
          <SidebarItem href="/bookings" icon={<CalendarDays size={18} />} label="Bookings" isActive={location === "/bookings"} />
        </nav>

        <div className="p-4 border-t">
          <Button variant="ghost" className="w-full justify-start text-muted-foreground" onClick={logout}>
            <LogOut size={18} className="mr-2" />
            Sign out
          </Button>
        </div>
      </aside>

      <main className="flex-1 overflow-auto">
        {children}
      </main>
    </div>
  );
}
