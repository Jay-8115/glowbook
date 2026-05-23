import { useGetAdminStats } from "@workspace/api-client-react";
import { useAuth } from "@/lib/auth";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Users, Store, CalendarDays, DollarSign, Activity, AlertCircle } from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";

export default function DashboardPage() {
  const { token } = useAuth();
  const { data: stats, isLoading } = useGetAdminStats({ query: { enabled: !!token } as any });

  if (isLoading) {
    return (
      <div className="p-8 space-y-6">
        <div>
          <Skeleton className="h-10 w-64 mb-2" />
          <Skeleton className="h-5 w-96" />
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {[1, 2, 3, 4, 5, 6].map((i) => (
            <Skeleton key={i} className="h-32 rounded-xl" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="p-8 space-y-8">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Platform Overview</h1>
        <p className="text-muted-foreground mt-1">Real-time metrics and platform status.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard 
          title="Total Revenue" 
          value={`$${stats?.totalRevenue?.toLocaleString() || "0"}`} 
          icon={<DollarSign className="text-accent" />} 
        />
        <StatCard 
          title="Total Users" 
          value={stats?.totalUsers?.toLocaleString() || "0"} 
          icon={<Users className="text-muted-foreground" />} 
        />
        <StatCard 
          title="Active Salons" 
          value={`${stats?.activeSalons || 0} / ${stats?.totalSalons || 0}`} 
          icon={<Store className="text-muted-foreground" />} 
        />
        <StatCard 
          title="Active Bookings" 
          value={stats?.activeBookings?.toLocaleString() || "0"} 
          icon={<Activity className="text-accent" />} 
        />
        <StatCard 
          title="Pending Bookings" 
          value={stats?.pendingBookings?.toLocaleString() || "0"} 
          icon={<AlertCircle className="text-destructive" />} 
        />
        <StatCard 
          title="Total Bookings" 
          value={stats?.totalBookings?.toLocaleString() || "0"} 
          icon={<CalendarDays className="text-muted-foreground" />} 
        />
      </div>
    </div>
  );
}

function StatCard({ title, value, icon }: { title: string; value: string; icon: React.ReactNode }) {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">{title}</CardTitle>
        {icon}
      </CardHeader>
      <CardContent>
        <div className="text-3xl font-bold">{value}</div>
      </CardContent>
    </Card>
  );
}
