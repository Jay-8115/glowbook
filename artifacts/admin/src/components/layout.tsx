import React, { useState, useEffect } from "react";
import { Link, useLocation } from "wouter";
import { LayoutDashboard, Users, Store, CalendarDays, LogOut, Terminal } from "lucide-react";
import { useAuth } from "@/lib/auth";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";

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
  const { token, logout } = useAuth();
  const [isOpen, setIsOpen] = useState(false);
  const [logs, setLogs] = useState<any[]>([]);
  const [isLoadingLogs, setIsLoadingLogs] = useState(false);

  // Fetch administrator action logs when drawer opens
  useEffect(() => {
    if (isOpen && token) {
      setIsLoadingLogs(true);
      fetch("/api/admin/logs", {
        headers: {
          Authorization: `Bearer ${token}`
        }
      })
        .then((res) => {
          if (!res.ok) throw new Error("Failed to fetch logs");
          return res.json();
        })
        .then((data) => {
          setLogs(data.logs || []);
          setIsLoadingLogs(false);
        })
        .catch((err) => {
          console.error("Failed to load logs:", err);
          setIsLoadingLogs(false);
        });
    }
  }, [isOpen, token]);

  return (
    <div className="flex h-screen w-full bg-muted/30">
      <aside className="w-64 bg-card border-r flex flex-col shrink-0">
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

      <main className="flex-1 flex flex-col h-screen overflow-hidden">
        {/* PREMIUM TOP HEADER BAR */}
        <header className="h-16 border-b bg-card px-8 flex items-center justify-between shrink-0">
          <div className="flex items-center gap-2">
            <h2 className="font-semibold text-lg text-foreground">GlowBook System Management</h2>
            <Badge variant="outline" className="text-xs text-primary border-primary/20 bg-primary/5 uppercase font-semibold">Super Admin</Badge>
          </div>
          
          <div className="flex items-center gap-4">
            {/* Radix Sheet Modal Drawer for Audit Logs */}
            <Sheet open={isOpen} onOpenChange={setIsOpen}>
              <SheetTrigger asChild>
                <Button variant="outline" size="sm" className="gap-2 text-muted-foreground hover:text-foreground">
                  <Terminal size={16} />
                  <span>Admin Logs</span>
                </Button>
              </SheetTrigger>
              <SheetContent className="w-[500px] sm:max-w-[500px] flex flex-col h-full bg-card border-l">
                <SheetHeader className="border-b pb-4">
                  <SheetTitle className="flex items-center gap-2 text-foreground font-bold">
                    <Terminal className="text-primary" size={20} />
                    <span>Administrative Audit Logs</span>
                  </SheetTitle>
                  <SheetDescription className="text-muted-foreground">
                    Real-time logging of user mutations, salon approvals, and record deletions.
                  </SheetDescription>
                </SheetHeader>
                
                {/* Scrollable Audit Feed */}
                <div className="flex-1 overflow-y-auto py-4 pr-1 space-y-3">
                  {isLoadingLogs ? (
                    <div className="space-y-4">
                      {Array.from({ length: 6 }).map((_, i) => (
                        <div key={i} className="p-3 border rounded-md space-y-2">
                          <div className="h-4 bg-muted animate-pulse rounded w-1/4" />
                          <div className="h-4 bg-muted animate-pulse rounded w-3/4" />
                        </div>
                      ))}
                    </div>
                  ) : logs.length === 0 ? (
                    <div className="text-center py-12 text-muted-foreground text-sm">
                      No system logs recorded yet.
                    </div>
                  ) : (
                    <div className="space-y-3">
                      {logs.map((log) => (
                        <div key={log.id} className="p-3 border rounded-md bg-muted/10 hover:bg-muted/30 transition-colors text-xs space-y-1.5 border-border">
                          <div className="flex justify-between items-center">
                            <span className="font-semibold text-primary">{log.action}</span>
                            <span className="text-[10px] text-muted-foreground">{new Date(log.createdAt).toLocaleString()}</span>
                          </div>
                          <div className="font-medium text-foreground">
                            Target: <span className="font-mono text-muted-foreground bg-muted px-1 py-0.5 rounded border border-border">{log.target || "N/A"}</span>
                          </div>
                          <div className="text-muted-foreground leading-relaxed">{log.details}</div>
                          <div className="text-[10px] text-muted-foreground/60 mt-1 border-t pt-1.5 flex justify-between items-center">
                            <span>Admin: <strong className="text-foreground/75">{log.adminName}</strong></span>
                            <span>{log.adminEmail}</span>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </SheetContent>
            </Sheet>
          </div>
        </header>

        {/* MAIN ROUTE CONTENT COMPONENT */}
        <div className="flex-1 overflow-auto">
          {children}
        </div>
      </main>
    </div>
  );
}
