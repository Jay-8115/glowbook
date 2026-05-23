import { useState } from "react";
import { useGetAdminBookings } from "@workspace/api-client-react";
import { useAuth } from "@/lib/auth";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";

export default function BookingsPage() {
  const { token } = useAuth();
  const [page] = useState(1);
  
  const { data, isLoading } = useGetAdminBookings(
    { page, limit: 50 },
    { query: { enabled: !!token } as any }
  );

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'completed': return <Badge variant="outline" className="text-green-600 bg-green-50 border-green-200">Completed</Badge>;
      case 'pending': return <Badge variant="outline" className="text-yellow-600 bg-yellow-50 border-yellow-200">Pending</Badge>;
      case 'cancelled': return <Badge variant="destructive">Cancelled</Badge>;
      case 'accepted': return <Badge variant="outline" className="text-blue-600 bg-blue-50 border-blue-200">Accepted</Badge>;
      default: return <Badge variant="secondary">{status}</Badge>;
    }
  };

  return (
    <div className="p-8 space-y-6">
      <div className="flex justify-between items-end">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Bookings Activity</h1>
          <p className="text-muted-foreground mt-1">Monitor platform-wide reservation flow.</p>
        </div>
      </div>

      <div className="border rounded-md bg-card">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Booking ID</TableHead>
              <TableHead>Date & Time</TableHead>
              <TableHead>Customer</TableHead>
              <TableHead>Salon & Service</TableHead>
              <TableHead>Amount</TableHead>
              <TableHead>Status</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              Array.from({ length: 5 }).map((_, i) => (
                <TableRow key={i}>
                  <TableCell><Skeleton className="h-5 w-16" /></TableCell>
                  <TableCell><Skeleton className="h-5 w-32" /></TableCell>
                  <TableCell><Skeleton className="h-5 w-32" /></TableCell>
                  <TableCell><Skeleton className="h-5 w-48" /></TableCell>
                  <TableCell><Skeleton className="h-5 w-16" /></TableCell>
                  <TableCell><Skeleton className="h-5 w-20" /></TableCell>
                </TableRow>
              ))
            ) : data?.bookings?.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} className="text-center py-8 text-muted-foreground">No bookings found</TableCell>
              </TableRow>
            ) : (
              data?.bookings?.map((booking) => (
                <TableRow key={booking.id}>
                  <TableCell className="font-mono text-xs">#{booking.id}</TableCell>
                  <TableCell>
                    <div className="font-medium">{new Date(booking.bookingDate).toLocaleDateString()}</div>
                    <div className="text-xs text-muted-foreground">{booking.startTime}</div>
                  </TableCell>
                  <TableCell>
                    <div className="font-medium">{booking.user?.name || 'Unknown'}</div>
                    <div className="text-xs text-muted-foreground">{booking.user?.email}</div>
                  </TableCell>
                  <TableCell>
                    <div className="font-medium">{booking.salon?.name}</div>
                    <div className="text-xs text-muted-foreground">{booking.service?.name}</div>
                  </TableCell>
                  <TableCell className="font-medium">${booking.totalPrice}</TableCell>
                  <TableCell>
                    {getStatusBadge(booking.status)}
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>
    </div>
  );
}
